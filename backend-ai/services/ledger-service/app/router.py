"""Ledger Service — Routes"""
import asyncio
import logging
import time
from datetime import datetime
from bson import ObjectId
from fastapi import APIRouter, Query, HTTPException, BackgroundTasks
from pydantic import BaseModel, Field
from app.blockchain import (
    get_blockchain_manager, get_activity_logs, get_db
)
from app.integrations.fabric_client import get_fabric_client

router = APIRouter(tags=["Ledger"])
logger = logging.getLogger("ledger-service.router")


def _bm():
    bm = get_blockchain_manager()
    if not bm:
        raise HTTPException(503, "Blockchain not ready")
    return bm


# ── Blockchain ────────────────────────────────────────────────────────────────

@router.get("/api/blockchain/chain")
async def chain():
    c = _bm().get_chain()
    return {"chain": c, "length": len(c)}


@router.get("/api/blockchain/verify")
async def verify():
    return _bm().verify_chain()


@router.post("/api/blockchain/heal")
async def heal():
    return _bm().heal_chain_integrity()


@router.get("/api/blockchain/blocks")
async def blocks_by_type(
    block_type: str = Query(..., description="e.g. PRESCRIPTION, ACCESS_GRANT, DISPENSED")
):
    return {"blocks": _bm().get_blocks_by_type(block_type)}


# ── Ledger ────────────────────────────────────────────────────────────────────

@router.get("/api/ledger/prescriptions/{rx_id}")
async def ledger_prescription(rx_id: str):
    all_blocks = _bm().get_blocks_by_type("PRESCRIPTION")
    rx_blocks = [b for b in all_blocks if b.get("data", {}).get("rx_id") == rx_id]
    return {"rx_id": rx_id, "blocks": rx_blocks, "count": len(rx_blocks)}


@router.get("/api/ledger/events/{resource_id}")
async def ledger_events(resource_id: str):
    all_blocks = _bm().get_chain()
    matching = [b for b in all_blocks if resource_id.lower() in str(b.get("data", {})).lower()]
    return {"resource_id": resource_id, "events": matching, "count": len(matching)}


# ── Access ────────────────────────────────────────────────────────────────────

@router.get("/api/access/status")
async def access_status(
    doctor_id: str = Query(...),
    patient_name: str = Query(...),
):
    return {
        "doctor_id": doctor_id,
        "patient_name": patient_name,
        "access_granted": _bm().has_doctor_access(doctor_id, patient_name),
    }


@router.get("/api/visit-history/{patient_name}")
async def visit_history(patient_name: str):
    return {"visits": _bm().get_visit_history(patient_name), "source": "blockchain"}


# ── Activity Logs ─────────────────────────────────────────────────────────────

@router.get("/api/activity-logs")
async def activity_logs():
    return get_activity_logs()


# ── Hyperledger Fabric Simulated API Endpoints ─────────────────────────────────

class AuditEventPayload(BaseModel):
    audit_id: str = Field(..., example="uuid-1234")
    patient_id: str = Field(..., example="anon-patient-404")
    doctor_id: str = Field(..., example="doc-01")
    risk_band: str = Field(..., example="HIGH")
    decision_type: str = Field(..., example="approved")
    audit_hash: str = Field(..., example="SHA256-of-AuditResponse-JSON")
    timestamp: str = Field(..., example="2026-07-15T11:03:00Z")


class ConsentEventPayload(BaseModel):
    consent_id: str = Field(..., example="consent-uuid-123")
    patient_id: str = Field(..., example="anon-patient-404")
    scope: str = Field(..., example="ACCESS_GRANT")
    action_type: str = Field(..., example="accept")
    timestamp: str = Field(..., example="2026-07-15T11:03:00Z")


# ── Worker Task Processors ───────────────────────────────────────────────────

async def run_audit_commit_worker(payload: AuditEventPayload):
    client = get_fabric_client()
    max_retries = 3
    last_error = None
    for attempt in range(max_retries):
        try:
            # Check if we should force a failure for testing the DLQ
            if payload.audit_id == "force_fail_ledger":
                raise RuntimeError("Forced simulation peer connection failure")
            
            await client.record_audit(
                audit_id=payload.audit_id,
                patient_id_anon=payload.patient_id,
                doctor_id_anon=payload.doctor_id,
                risk_band=payload.risk_band,
                decision_type=payload.decision_type,
                audit_hash=payload.audit_hash,
                timestamp=payload.timestamp
            )
            logger.info(f"Asynchronous Fabric Audit Commit successful for {payload.audit_id}")
            return
        except Exception as e:
            last_error = e
            delay = 2 ** attempt
            logger.warning(f"Fabric Audit Commit failed on attempt {attempt+1}/{max_retries}. Retrying in {delay}s. Error: {e}")
            await asyncio.sleep(delay)
            
    # Permanently failed: Push to DLQ
    try:
        db = get_db()
        dlq_record = {
            "event_type": "AUDIT",
            "payload": payload.dict(),
            "error": str(last_error),
            "retries": max_retries,
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "status": "FAILED"
        }
        db["ledger_dlq"].insert_one(dlq_record)
        logger.error(f"Fabric Audit Commit failed permanently. Record saved to MongoDB DLQ collection.")
    except Exception as db_err:
        logger.critical(f"Failed to write to ledger_dlq: {db_err}")


async def run_consent_commit_worker(payload: ConsentEventPayload):
    client = get_fabric_client()
    max_retries = 3
    last_error = None
    for attempt in range(max_retries):
        try:
            if payload.consent_id == "force_fail_ledger":
                raise RuntimeError("Forced simulation peer connection failure")
                
            await client.record_consent(
                consent_id=payload.consent_id,
                patient_id_anon=payload.patient_id,
                scope=payload.scope,
                action_type=payload.action_type,
                timestamp=payload.timestamp
            )
            logger.info(f"Asynchronous Fabric Consent Commit successful for {payload.consent_id}")
            return
        except Exception as e:
            last_error = e
            delay = 2 ** attempt
            logger.warning(f"Fabric Consent Commit failed on attempt {attempt+1}/{max_retries}. Retrying in {delay}s. Error: {e}")
            await asyncio.sleep(delay)
            
    # Permanently failed: Push to DLQ
    try:
        db = get_db()
        dlq_record = {
            "event_type": "CONSENT",
            "payload": payload.dict(),
            "error": str(last_error),
            "retries": max_retries,
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "status": "FAILED"
        }
        db["ledger_dlq"].insert_one(dlq_record)
        logger.error(f"Fabric Consent Commit failed permanently. Record saved to MongoDB DLQ collection.")
    except Exception as db_err:
        logger.critical(f"Failed to write to ledger_dlq: {db_err}")


@router.post("/api/ledger/audit-event", status_code=202)
async def record_audit_event(payload: AuditEventPayload, background_tasks: BackgroundTasks):
    background_tasks.add_task(run_audit_commit_worker, payload)
    return {"status": "ACCEPTED", "message": "Transaction queued for asynchronous commit."}


@router.post("/api/ledger/consent-event", status_code=202)
async def record_consent_event(payload: ConsentEventPayload, background_tasks: BackgroundTasks):
    background_tasks.add_task(run_consent_commit_worker, payload)
    return {"status": "ACCEPTED", "message": "Transaction queued for asynchronous commit."}


@router.get("/api/ledger/audit-event/{audit_id}")
async def get_audit_event(audit_id: str):
    client = get_fabric_client()
    res = await client.get_audit(audit_id)
    if not res:
        raise HTTPException(status_code=404, detail=f"Audit log {audit_id} not found in Fabric ledger")
    return res


# ── DLQ Administration Endpoints ──────────────────────────────────────────────

@router.get("/api/ledger/admin/dlq")
async def get_dlq_records():
    try:
        db = get_db()
        records = list(db["ledger_dlq"].find())
        for r in records:
            r["_id"] = str(r["_id"])
        return {"dlq": records}
    except Exception as e:
        raise HTTPException(500, f"Failed to retrieve DLQ: {e}")


@router.post("/api/ledger/admin/dlq/{dlq_id}/retry")
async def retry_dlq_record(dlq_id: str, background_tasks: BackgroundTasks):
    db = get_db()
    record = None
    try:
        record = db["ledger_dlq"].find_one({"_id": ObjectId(dlq_id)})
    except Exception:
        pass
    if not record:
        record = db["ledger_dlq"].find_one({"_id": dlq_id})
    if not record:
        raise HTTPException(status_code=404, detail="DLQ record not found")
        
    event_type = record.get("event_type")
    raw_payload = record.get("payload", {})
    
    if event_type == "AUDIT":
        payload = AuditEventPayload(**raw_payload)
        # If it was forced to fail, clear payload ID for successful retry
        if payload.audit_id == "force_fail_ledger":
            payload.audit_id = "retry_success_" + str(int(time.time()))
        background_tasks.add_task(run_audit_commit_worker, payload)
    elif event_type == "CONSENT":
        payload = ConsentEventPayload(**raw_payload)
        if payload.consent_id == "force_fail_ledger":
            payload.consent_id = "retry_success_" + str(int(time.time()))
        background_tasks.add_task(run_consent_commit_worker, payload)
    else:
        raise HTTPException(status_code=400, detail="Invalid event type in DLQ record")
        
    db["ledger_dlq"].update_one(
        {"_id": record["_id"]},
        {"$set": {"status": "RETRYING", "retried_at": datetime.utcnow().isoformat() + "Z"}}
    )
    return {"status": "SUCCESS", "message": "Manual retry task initiated."}


@router.post("/api/ledger/admin/dlq/{dlq_id}/resolve")
async def resolve_dlq_record(dlq_id: str):
    db = get_db()
    record = None
    try:
        record = db["ledger_dlq"].find_one({"_id": ObjectId(dlq_id)})
    except Exception:
        pass
    if not record:
        record = db["ledger_dlq"].find_one({"_id": dlq_id})
    if not record:
        raise HTTPException(status_code=404, detail="DLQ record not found")
        
    db["ledger_dlq"].update_one(
        {"_id": record["_id"]},
        {"$set": {"status": "RESOLVED", "resolved_at": datetime.utcnow().isoformat() + "Z"}}
    )
    return {"status": "SUCCESS", "message": "DLQ record marked as RESOLVED."}


@router.delete("/api/ledger/admin/dlq/{dlq_id}")
async def delete_dlq_record(dlq_id: str):
    db = get_db()
    record = None
    try:
        record = db["ledger_dlq"].find_one({"_id": ObjectId(dlq_id)})
    except Exception:
        pass
    if not record:
        record = db["ledger_dlq"].find_one({"_id": dlq_id})
    if not record:
        raise HTTPException(status_code=404, detail="DLQ record not found")
        
    db["ledger_dlq"].delete_one({"_id": record["_id"]})
    return {"status": "SUCCESS", "message": "DLQ record deleted successfully."}
