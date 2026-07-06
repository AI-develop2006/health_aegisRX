import hashlib
import time
import re
from datetime import datetime
from fastapi import HTTPException
from app.config import logger
from app.db.mongodb import MongoDBConnector
from app.services import ledger_service


def _make_request_id() -> str:
    return f"req_{hashlib.md5(str(time.time()).encode()).hexdigest()[:8]}"


# ============================================
# CONSULTATION SERVICE
# ============================================
async def create_consultation_request(db: MongoDBConnector, patient_name: str, patient_id: str | None, doctor_id: str | None) -> dict:
    """
    Create a new consultation request with status=pending.
    Raises 409 if there is already a pending request for this patient.
    """
    patient_id = patient_id or patient_name
    safe_name = re.escape(patient_name)

    consultations_col = db.get_consultations_collection()

    # Guard: reject duplicate active pending request
    existing_pending = consultations_col.find_one({
        "patientName": {"$regex": f"^{safe_name}$", "$options": "i"},
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

    consultations_col.insert_one(request_data.copy())
    logger.info(f"New consultation request created: {request_id} for patient: {patient_name} (ID: {patient_id})")

    await ledger_service.log_activity(
        db, "SCAN_CONSULTATION", patient_name, doctor_id or "Doctor",
        f"Doctor initiated connection request {request_id}."
    )
    return _serialize_doc(request_data)


async def get_consultation_status(db: MongoDBConnector, req_id: str) -> dict:
    """Return the current status of a consultation request."""
    consultations_col = db.get_consultations_collection()
    req_doc = consultations_col.find_one({"id": req_id})
    if not req_doc:
        raise HTTPException(status_code=404, detail="Request not found")
    return {"status": req_doc.get("status", "pending")}


async def get_pending_consultation(db: MongoDBConnector, patient: str, patient_id: str | None) -> dict | None:
    """Fetch the latest pending consultation for a patient (by name or ID)."""
    consultations_col = db.get_consultations_collection()
    or_filters = [{"patientName": {"$regex": f"^{re.escape(patient)}$", "$options": "i"}}]
    if patient_id:
        or_filters.append({"patientName": {"$regex": f"^{re.escape(patient_id)}$", "$options": "i"}})
        or_filters.append({"patientId": {"$regex": f"^{re.escape(patient_id)}$", "$options": "i"}})

    query = {"$or": or_filters, "status": "pending"}
    pending = consultations_col.find_one(query, sort=[("createdAt", -1)])
    return _serialize_doc(pending)


async def has_active_session(db: MongoDBConnector, patient: str) -> bool:
    """Return True if the patient has an accepted (not completed) consultation."""
    consultations_col = db.get_consultations_collection()
    safe = re.escape(patient)
    doc = consultations_col.find_one(
        {"patientName": {"$regex": f"^{safe}$", "$options": "i"}, "status": "accepted"},
        sort=[("createdAt", -1)]
    )
    return doc is not None


async def accept_consultation(db: MongoDBConnector, req_id: str) -> dict:
    """Accept a pending consultation request and add an ACCESS_GRANT blockchain block."""
    consultations_col = db.get_consultations_collection()
    updated = consultations_col.find_one_and_update(
        {"id": req_id},
        {"$set": {"status": "accepted"}},
        return_document=True
    )
    if not updated:
        raise HTTPException(status_code=404, detail="Request not found")

    await ledger_service.log_activity(
        db, "ACCEPT_ACCESS", updated.get("patientName", "Unknown"), "Patient",
        f"Patient accepted doctor connection request {req_id}."
    )

    bm = ledger_service.get_blockchain_manager()
    if bm:
        bm.add_block("ACCESS_GRANT", {
            "request_id": req_id,
            "patient_name": updated.get("patientName", ""),
            "patient_id": updated.get("patientId", ""),
            "doctor_id": updated.get("doctorId", updated.get("patientId", "")),
            "granted_at": datetime.utcnow().isoformat(),
        })
    return _serialize_doc(updated)


async def reject_consultation(db: MongoDBConnector, req_id: str) -> dict:
    """Reject a pending consultation request and add an ACCESS_REVOKE blockchain block."""
    consultations_col = db.get_consultations_collection()
    updated = consultations_col.find_one_and_update(
        {"id": req_id},
        {"$set": {"status": "rejected"}},
        return_document=True
    )
    if not updated:
        raise HTTPException(status_code=404, detail="Request not found")

    await ledger_service.log_activity(
        db, "REJECT_ACCESS", updated.get("patientName", "Unknown"), "Patient",
        f"Patient rejected doctor connection request {req_id}."
    )

    bm = ledger_service.get_blockchain_manager()
    if bm:
        bm.add_block("ACCESS_REVOKE", {
            "request_id": req_id,
            "patient_name": updated.get("patientName", ""),
            "patient_id": updated.get("patientId", ""),
            "doctor_id": updated.get("doctorId", updated.get("patientId", "")),
            "revoked_at": datetime.utcnow().isoformat(),
        })
    return _serialize_doc(updated)


# ============================================
# HELPERS
# ============================================
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
