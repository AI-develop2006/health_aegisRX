import re
from datetime import datetime
from app.config import COLLECTION_PRESCRIPTIONS, logger
from app.db.mongodb import MongoDBConnector


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


def _serialize_list(docs: list) -> list:
    return [_serialize_doc(d) for d in docs]


# ============================================
# PATIENT PRESCRIPTION RETRIEVAL
# ============================================
def get_patient_prescriptions(db: MongoDBConnector, patient_id: str) -> list:
    """
    Return all prescriptions for a patient (matched by patientName or patient_id).
    """
    logger.info(f"Fetching prescriptions for patient: {patient_id}")
    prescriptions_col = db.get_prescriptions_collection()
    safe = re.escape(patient_id)
    cursor = prescriptions_col.find({
        "$or": [
            {"patientName": {"$regex": f"^{safe}$", "$options": "i"}},
            {"patient_id": {"$regex": f"^{safe}$", "$options": "i"}},
        ]
    })
    return _serialize_list(list(cursor))


# ============================================
# PATIENT DASHBOARD
# ============================================
def get_patient_dashboard(db: MongoDBConnector, patient_id: str) -> dict:
    """
    Build a dashboard summary for a patient:
      - total, active, and dispensed prescription counts
      - overall alert level derived from flagged medicines
      - list of flagged medicine names
    """
    logger.info(f"Building dashboard for patient: {patient_id}")
    prescriptions = get_patient_prescriptions(db, patient_id)

    total = len(prescriptions)
    dispensed = sum(1 for rx in prescriptions if rx.get("isDispensed", False))
    active = total - dispensed

    # Collect all medicine names from active prescriptions
    active_medicines: list[str] = []
    for rx in prescriptions:
        if not rx.get("isDispensed", False):
            for med in rx.get("medicines", []):
                name = med.get("name", "")
                if name:
                    active_medicines.append(name)

    # Simple heuristic: flag medicines that appear in more than one active prescription (potential duplicate)
    from collections import Counter
    med_counts = Counter(m.split()[0].lower() for m in active_medicines)
    flagged = [med for med, count in med_counts.items() if count > 1]

    alert_level = "HIGH" if flagged else "LOW"

    # Derive display name from first prescription found or fall back to patient_id
    display_name = patient_id
    if prescriptions:
        display_name = prescriptions[0].get("patientName", patient_id)

    return {
        "patient_id": patient_id,
        "patient_name": display_name,
        "total_prescriptions": total,
        "active_prescriptions": active,
        "dispensed_prescriptions": dispensed,
        "alert_level": alert_level,
        "flagged_medicines": flagged,
    }
