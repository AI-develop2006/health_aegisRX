"""Ledger Service — Routes"""
from fastapi import APIRouter, Query, HTTPException
from app.blockchain import (
    get_blockchain_manager, get_activity_logs
)

router = APIRouter(tags=["Ledger"])


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
