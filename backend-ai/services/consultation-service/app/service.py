"""
Consultation Service — Business Logic
Self-contained: uses app.db and app.blockchain.
"""
import hashlib
import time
import re
import logging
from datetime import datetime
from fastapi import HTTPException

from app.db import consultations_col, get_db
from app import blockchain

logger = logging.getLogger("consultation-service")


def _make_request_id() -> str:
    return f"req_{hashlib.md5(str(time.time()).encode()).hexdigest()[:8]}"


def _serialize_doc(doc: dict | None) -> dict | None:
    if doc is None:
        return None
    doc_copy = dict(doc)
    doc_copy.pop("_id", None)
    for key, value in doc_copy.items():
        if isinstance(value, datetime):
            doc_copy[key] = value.isoformat() + ("Z" if value.tzinfo is None else "")
        elif isinstance(value, list):
            doc_copy[key] = [_serialize_doc(i) if isinstance(i, dict) else i for i in value]
    return doc_copy


async def create_consultation_request(patient_name: str, patient_id: str | None, doctor_id: str | None) -> dict:
    patient_id = patient_id or patient_name

    # Resolve actual patientName and patientId from 'patients' collection
    db = get_db()
    safe_id = re.escape(patient_id)
    safe_name = re.escape(patient_name)
    pattern = f"^({safe_id}|{safe_name})$"

    patient_doc = db["patients"].find_one({
        "$or": [
            {"id_number": {"$regex": pattern, "$options": "i"}},
            {"mobile": {"$regex": pattern, "$options": "i"}},
            {"name": {"$regex": pattern, "$options": "i"}},
            {"patient_id": {"$regex": pattern, "$options": "i"}},
            {"email": {"$regex": pattern, "$options": "i"}},
        ]
    })

    if patient_doc:
        patient_name = patient_doc.get("name", patient_name)
        patient_id = patient_doc.get("id_number") or patient_doc.get("mobile") or patient_doc.get("patient_id") or str(patient_doc["_id"])

    safe_name_escaped = re.escape(patient_name)
    existing_pending = consultations_col().find_one({
        "patientName": {"$regex": f"^{safe_name_escaped}$", "$options": "i"},
        "status": "pending"
    })
    if existing_pending:
        logger.info(f"Duplicate pending request for patient {patient_name} — returning existing.")
        return _serialize_doc(existing_pending)

    request_id = _make_request_id()
    request_data = {
        "id": request_id,
        "patientName": patient_name,
        "patientId": patient_id,
        "doctorId": doctor_id,
        "status": "pending",
        "createdAt": datetime.utcnow()
    }

    consultations_col().insert_one(request_data.copy())
    logger.info(f"New consultation request created: {request_id} for patient: {patient_name}")

    await blockchain.log_activity(
        "SCAN_CONSULTATION", patient_name, doctor_id or "Doctor",
        f"Doctor initiated connection request {request_id}."
    )
    return _serialize_doc(request_data)


async def get_consultation_status(req_id: str) -> dict:
    req_doc = consultations_col().find_one({"id": req_id})
    if not req_doc:
        raise HTTPException(status_code=404, detail="Request not found")
    return {"status": req_doc.get("status", "pending")}


async def get_pending_consultation(patient: str, patient_id: str | None) -> dict | None:
    or_filters = [{"patientName": {"$regex": f"^{re.escape(patient)}$", "$options": "i"}}]
    if patient_id:
        or_filters.append({"patientName": {"$regex": f"^{re.escape(patient_id)}$", "$options": "i"}})
        or_filters.append({"patientId": {"$regex": f"^{re.escape(patient_id)}$", "$options": "i"}})

    query = {"$or": or_filters, "status": "pending"}
    pending = consultations_col().find_one(query, sort=[("createdAt", -1)])
    return _serialize_doc(pending)


async def has_active_session(patient: str) -> bool:
    safe = re.escape(patient)
    doc = consultations_col().find_one(
        {"patientName": {"$regex": f"^{safe}$", "$options": "i"}, "status": "accepted"},
        sort=[("createdAt", -1)]
    )
    return doc is not None


async def accept_consultation(req_id: str) -> dict:
    updated = consultations_col().find_one_and_update(
        {"id": req_id},
        {"$set": {"status": "accepted"}},
        return_document=True
    )
    if not updated:
        raise HTTPException(status_code=404, detail="Request not found")

    await blockchain.log_activity(
        "ACCEPT_ACCESS", updated.get("patientName", "Unknown"), "Patient",
        f"Patient accepted doctor connection request {req_id}."
    )

    bm = blockchain.BlockchainManager()
    bm.add_block("ACCESS_GRANT", {
        "request_id": req_id,
        "patient_name": updated.get("patientName", ""),
        "patient_id": updated.get("patientId", ""),
        "doctor_id": updated.get("doctorId", updated.get("patientId", "")),
        "granted_at": datetime.utcnow().isoformat(),
    })

    # Write consent event on-chain to Fabric private channel
    try:
        import os
        import httpx
        
        ledger_url = os.getenv("LEDGER_SERVICE_URL", "http://localhost:4007")
        patient_id = updated.get("patientId", "") or updated.get("patientName", "")
        patient_id_anon = f"anon-patient-{hashlib.sha256(patient_id.encode('utf-8')).hexdigest()[:8]}"
        
        payload = {
            "consent_id": req_id,
            "patient_id": patient_id_anon,
            "scope": "ACCESS_GRANT",
            "action_type": "accept",
            "timestamp": datetime.utcnow().isoformat() + "Z"
        }
        
        async with httpx.AsyncClient(timeout=2.0) as client:
            res = await client.post(f"{ledger_url}/api/ledger/consent-event", json=payload)
            if res.status_code == 200:
                logger.info(f"Consent ACCESS_GRANT event successfully logged on Fabric: {res.json()}")
            else:
                logger.warning(f"Ledger service returned status {res.status_code}: {res.text}")
    except Exception as lex:
        logger.error(f"Failed to log ACCESS_GRANT consent event to Fabric: {lex}")

    return _serialize_doc(updated)


async def reject_consultation(req_id: str) -> dict:
    updated = consultations_col().find_one_and_update(
        {"id": req_id},
        {"$set": {"status": "rejected"}},
        return_document=True
    )
    if not updated:
        raise HTTPException(status_code=404, detail="Request not found")

    await blockchain.log_activity(
        "REJECT_ACCESS", updated.get("patientName", "Unknown"), "Patient",
        f"Patient rejected doctor connection request {req_id}."
    )

    bm = blockchain.BlockchainManager()
    bm.add_block("ACCESS_REVOKE", {
        "request_id": req_id,
        "patient_name": updated.get("patientName", ""),
        "patient_id": updated.get("patientId", ""),
        "doctor_id": updated.get("doctorId", updated.get("patientId", "")),
        "revoked_at": datetime.utcnow().isoformat(),
    })

    # Write consent event on-chain to Fabric private channel
    try:
        import os
        import httpx
        
        ledger_url = os.getenv("LEDGER_SERVICE_URL", "http://localhost:4007")
        patient_id = updated.get("patientId", "") or updated.get("patientName", "")
        patient_id_anon = f"anon-patient-{hashlib.sha256(patient_id.encode('utf-8')).hexdigest()[:8]}"
        
        payload = {
            "consent_id": req_id,
            "patient_id": patient_id_anon,
            "scope": "ACCESS_REVOKE",
            "action_type": "reject",
            "timestamp": datetime.utcnow().isoformat() + "Z"
        }
        
        async with httpx.AsyncClient(timeout=2.0) as client:
            res = await client.post(f"{ledger_url}/api/ledger/consent-event", json=payload)
            if res.status_code == 200:
                logger.info(f"Consent ACCESS_REVOKE event successfully logged on Fabric: {res.json()}")
            else:
                logger.warning(f"Ledger service returned status {res.status_code}: {res.text}")
    except Exception as lex:
        logger.error(f"Failed to log ACCESS_REVOKE consent event to Fabric: {lex}")

    return _serialize_doc(updated)


async def cancel_consultation(
    req_id: str | None,
    patient_id: str | None,
    patient_name: str | None,
    doctor_id: str | None,
) -> dict:
    query = {}
    if req_id:
        query["id"] = req_id
    else:
        # Match any active (accepted) or pending consultation request for this doctor-patient pair
        or_conditions = []
        if patient_id:
            or_conditions.append({"patientId": patient_id})
        if patient_name:
            or_conditions.append({"patientName": patient_name})
            
        if not or_conditions:
            raise HTTPException(status_code=400, detail="Must provide at least one identifier (req_id, patient_id, or patient_name)")
            
        query["$or"] = or_conditions
        query["status"] = {"$in": ["accepted", "pending"]}
        if doctor_id:
            query["doctorId"] = doctor_id

    # Find the latest matching consultation
    matched_doc = consultations_col().find_one(query, sort=[("createdAt", -1)])
    if not matched_doc:
        logger.warning(f"Cancel session requested but no matching active/pending consultation found. Query: {query}")
        return {"status": "already_inactive"}

    actual_req_id = matched_doc["id"]
    updated = consultations_col().find_one_and_update(
        {"id": actual_req_id},
        {"$set": {"status": "cancelled"}},
        return_document=True
    )

    await blockchain.log_activity(
        "CANCEL_CONSULTATION", updated.get("patientName", "Unknown"), updated.get("doctorId", "Doctor"),
        f"Consultation request {actual_req_id} was cancelled/disconnected."
    )

    bm = blockchain.BlockchainManager()
    bm.add_block("ACCESS_REVOKE", {
        "request_id": actual_req_id,
        "patient_name": updated.get("patientName", ""),
        "patient_id": updated.get("patientId", ""),
        "doctor_id": updated.get("doctorId", ""),
        "revoked_at": datetime.utcnow().isoformat(),
        "reason": "cancelled_by_user",
    })

    # Write consent event on-chain to Fabric private channel
    try:
        import os
        import httpx
        
        ledger_url = os.getenv("LEDGER_SERVICE_URL", "http://localhost:4007")
        p_id = updated.get("patientId", "") or updated.get("patientName", "")
        patient_id_anon = f"anon-patient-{hashlib.sha256(p_id.encode('utf-8')).hexdigest()[:8]}"
        
        payload = {
            "consent_id": actual_req_id,
            "patient_id": patient_id_anon,
            "scope": "ACCESS_REVOKE",
            "action_type": "cancel",
            "timestamp": datetime.utcnow().isoformat() + "Z"
        }
        
        async with httpx.AsyncClient(timeout=2.0) as client:
            res = await client.post(f"{ledger_url}/api/ledger/consent-event", json=payload)
            if res.status_code == 200:
                logger.info(f"Consent ACCESS_REVOKE event successfully logged on Fabric: {res.json()}")
            else:
                logger.warning(f"Ledger service returned status {res.status_code}: {res.text}")
    except Exception as lex:
        logger.error(f"Failed to log ACCESS_REVOKE consent event to Fabric: {lex}")

    return _serialize_doc(updated)
