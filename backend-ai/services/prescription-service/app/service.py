"""
Prescription Service — Business Logic
Self-contained: calls app.db, app.blockchain, app.utils.signature, and app.integrations.polygon_client.
"""
import re
import logging
from datetime import datetime
from fastapi import HTTPException

from app.config import TEST_DOCTOR_PRIVATE_KEY, logger
from app.db import prescriptions_col, get_db
from app.blockchain import BlockchainManager, log_activity
from app.utils.signature import json_stringify_rx, sha256_hash, sign
from app.integrations import polygon_client

logger = logging.getLogger("prescription-service")


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


def get_prescriptions_by_patient(patient: str) -> list:
    cursor = prescriptions_col().find(
        {"patientName": {"$regex": f"^{re.escape(patient)}$", "$options": "i"}}
    )
    return [_serialize_doc(doc) for doc in cursor]


def get_prescription_by_id(rx_id: str) -> dict:
    doc = prescriptions_col().find_one({"id": rx_id})
    if not doc:
        raise HTTPException(status_code=404, detail="Prescription not found")
    return _serialize_doc(doc)


async def create_prescription(rx_dict: dict) -> dict:
    # 1. Compute signature
    payload_str = json_stringify_rx(rx_dict)
    rx_hash = sha256_hash(payload_str)
    doctor_sign_id = rx_dict.get("doctorSignId") or "889218"
    rx_dict["signature"] = sign(rx_hash, doctor_sign_id)
    rx_dict["isDispensed"] = False

    logger.info(f"Issuing prescription {rx_dict['id']}. Hash: {rx_hash}. Signed: {rx_dict['signature']}")

    # 2. Polygon Integration
    onchain_tx_hash = None
    if TEST_DOCTOR_PRIVATE_KEY:
        try:
            onchain_tx_hash = polygon_client.create_prescription(
                rx_dict["id"], rx_hash, TEST_DOCTOR_PRIVATE_KEY
            )
            rx_dict["onchain_tx_hash"] = onchain_tx_hash
        except Exception as e:
            logger.error(f"Polygon on-chain create_prescription failed: {e}")

    # 3. Blockchain access check
    access_warning = None
    bm = BlockchainManager()
    has_access = bm.has_doctor_access(doctor_sign_id, rx_dict["patientName"])
    if not has_access:
        patient_name_str = rx_dict["patientName"]
        access_warning = (
            f"No active access grant found for doctor {doctor_sign_id} "
            f"and patient {patient_name_str}. Prescription recorded with warning."
        )
        logger.warning(access_warning)

    # 4. Save to MongoDB
    rx_mongo = rx_dict.copy()
    if "date" in rx_mongo and isinstance(rx_mongo["date"], str):
        try:
            rx_mongo["date"] = datetime.fromisoformat(rx_mongo["date"])
        except Exception:
            pass
    prescriptions_col().insert_one(rx_mongo)

    # 5. Add blocks to blockchain collection
    bm.add_block("PRESCRIPTION", {
        "rx_id": rx_dict["id"],
        "patient_name": rx_dict["patientName"],
        "doctor_id": doctor_sign_id,
        "doctor_name": rx_dict["doctorName"],
        "disease": rx_dict["disease"],
        "hash": rx_hash,
        "signature": rx_dict["signature"],
    }, onchain_tx_hash=onchain_tx_hash)

    bm.add_block("VISIT_HISTORY", {
        "patient_name": rx_dict["patientName"],
        "doctor_id": doctor_sign_id,
        "doctor_name": rx_dict["doctorName"],
        "hospital": rx_dict.get("hospitalName", ""),
        "disease": rx_dict["disease"],
        "rx_id": rx_dict["id"],
        "date": rx_dict.get("date", ""),
    })

    bm.add_block("ACCESS_REVOKE", {
        "patient_name": rx_dict["patientName"],
        "doctor_id": doctor_sign_id,
        "doctor_name": rx_dict["doctorName"],
        "revoked_at": datetime.utcnow().isoformat(),
        "reason": "auto_revoke_post_prescription",
    })

    # 6. Mark active consultation as completed
    consultations_col = get_db()["consultation_requests"]
    safe_name = re.escape(rx_dict["patientName"])
    consultations_col.find_one_and_update(
        {"patientName": {"$regex": f"^{safe_name}$", "$options": "i"}, "status": "accepted"},
        {"$set": {"status": "completed"}},
        sort=[("createdAt", -1)],
    )

    # 7. Log activity
    await log_activity(
        "CREATE_PRESCRIPTION",
        rx_dict["patientName"], doctor_sign_id,
        f"Doctor {rx_dict['doctorName']} created prescription {rx_dict['id']} for {rx_dict['disease']}.",
        onchain_tx_hash=onchain_tx_hash
    )

    result = _serialize_doc(rx_mongo)
    if access_warning:
        result["access_warning"] = access_warning
    return result


def get_patient_history(patient_id: str, doctor_id: str | None = None) -> dict:
    logger.info(f"Doctor {doctor_id} requesting history for patient {patient_id}")

    bm = BlockchainManager()
    if doctor_id:
        has_access = bm.has_doctor_access(doctor_id, patient_id)
        if not has_access:
            raise HTTPException(
                status_code=403,
                detail="Access denied: no active consultation grant found for this doctor-patient pair."
            )

    # Find prescriptions
    safe = re.escape(patient_id)
    cur = prescriptions_col().find({
        "$or": [
            {"patientName": {"$regex": f"^{safe}$", "$options": "i"}},
            {"patient_id": {"$regex": f"^{safe}$", "$options": "i"}},
        ]
    })
    prescriptions = [_serialize_doc(doc) for doc in cur]

    # Get visit history
    visit_history = bm.get_visit_history(patient_id)

    return {
        "patient_id": patient_id,
        "doctor_id": doctor_id,
        "prescriptions": prescriptions,
        "visit_history": visit_history,
        "total_prescriptions": len(prescriptions),
    }
