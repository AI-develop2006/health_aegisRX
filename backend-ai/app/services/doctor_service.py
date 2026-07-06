import re
from datetime import datetime
from fastapi import HTTPException
from app.config import logger
from app.db.mongodb import MongoDBConnector
from app.services import ai_service, ledger_service


def _serialize_doc(doc: dict | None) -> dict | None:
    if doc is None:
        return None
    doc_copy = dict(doc)
    doc_copy.pop("_id", None)
    for key, value in doc_copy.items():
        if isinstance(value, datetime):
            if value.hour == 0 and value.minute == 0 and value.second == 0:
                doc_copy[key] = value.strftime("%Y-%m-%d")
            elif value.tzinfo is None:
                doc_copy[key] = value.isoformat() + "Z"
            else:
                doc_copy[key] = value.isoformat()
        elif isinstance(value, list):
            doc_copy[key] = [_serialize_doc(i) if isinstance(i, dict) else i for i in value]
    return doc_copy


# ============================================
# PATIENT HISTORY (requires consultation access)
# ============================================
def get_patient_history(db: MongoDBConnector, patient_id: str, doctor_id: str | None = None) -> dict:
    """
    Return a patient's prescription history.
    If doctor_id is provided, verify that the doctor has an active consultation access grant
    via the blockchain ledger before exposing any records.
    """
    logger.info(f"Doctor {doctor_id} requesting history for patient {patient_id}")

    bm = ledger_service.get_blockchain_manager()
    if doctor_id and bm:
        has_access = bm.has_doctor_access(doctor_id, patient_id)
        if not has_access:
            raise HTTPException(
                status_code=403,
                detail="Access denied: no active consultation grant found for this doctor-patient pair."
            )

    safe = re.escape(patient_id)
    prescriptions_col = db.get_prescriptions_collection()
    cursor = prescriptions_col.find({
        "$or": [
            {"patientName": {"$regex": f"^{safe}$", "$options": "i"}},
            {"patient_id": {"$regex": f"^{safe}$", "$options": "i"}},
        ]
    })
    prescriptions = [_serialize_doc(doc) for doc in cursor]

    # Also fetch visit history from blockchain if available
    visit_history = []
    if bm:
        visit_history = bm.get_visit_history(patient_id)

    return {
        "patient_id": patient_id,
        "doctor_id": doctor_id,
        "prescriptions": prescriptions,
        "visit_history": visit_history,
        "total_prescriptions": len(prescriptions),
    }


# ============================================
# PRESCRIPTION PATTERN ANALYSIS
# ============================================
def get_pattern_analysis(doctor_id: str) -> dict:
    """
    Run prescription pattern anomaly analysis for a doctor.
    Delegates to AIAgent via ai_service.
    """
    logger.info(f"Pattern analysis requested for doctor: {doctor_id}")
    return ai_service.pattern_analysis(doctor_id)
