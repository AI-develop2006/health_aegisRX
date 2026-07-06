import re
from datetime import datetime
from fastapi import HTTPException
from app.config import COLLECTION_PRESCRIPTIONS, logger, TEST_DOCTOR_PRIVATE_KEY
from app.db.mongodb import MongoDBConnector
from app.utils.signature import json_stringify_rx, sha256_hash, sign
from app.services import ledger_service
from app.integrations import polygon_client


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
# GET PRESCRIPTIONS (shared helper)
# ============================================
def get_prescriptions_by_patient(db: MongoDBConnector, patient: str) -> list:
    """Return all prescriptions for a patient (by patientName query param)."""
    prescriptions_col = db.get_prescriptions_collection()
    cursor = prescriptions_col.find(
        {"patientName": {"$regex": f"^{re.escape(patient)}$", "$options": "i"}}
    )
    return [_serialize_doc(doc) for doc in cursor]


def get_prescription_by_id(db: MongoDBConnector, rx_id: str) -> dict:
    """Return a single prescription by its rx id."""
    prescriptions_col = db.get_prescriptions_collection()
    doc = prescriptions_col.find_one({"id": rx_id})
    if not doc:
        raise HTTPException(status_code=404, detail="Prescription not found")
    return _serialize_doc(doc)


# ============================================
# CREATE PRESCRIPTION (sign + store + ledger)
# ============================================
async def create_prescription(db: MongoDBConnector, rx_dict: dict) -> dict:
    """
    Canonicalize, sign, and store a new prescription.
    Also appends PRESCRIPTION, VISIT_HISTORY, and ACCESS_REVOKE blockchain blocks.
    """
    # 1. Compute signature
    payload_str = json_stringify_rx(rx_dict)
    rx_hash = sha256_hash(payload_str)
    doctor_sign_id = rx_dict.get("doctorSignId") or "889218"
    rx_dict["signature"] = sign(rx_hash, doctor_sign_id)
    rx_dict["isDispensed"] = False

    logger.info(
        f"Issuing prescription {rx_dict['id']}. Hash: {rx_hash}. "
        f"Signed: {rx_dict['signature']}"
    )

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

    # 3. Blockchain soft-check for doctor access
    access_warning = None
    bm = ledger_service.get_blockchain_manager()
    if bm:
        has_access = bm.has_doctor_access(doctor_sign_id, rx_dict["patientName"])
        if not has_access:
            access_warning = (
                f"No active access grant found for doctor {doctor_sign_id} "
                f"and patient {rx_dict["patientName"]}. Prescription recorded with warning."
            )
            logger.warning(access_warning)

    # 4. Convert date string to datetime for MongoDB
    prescriptions_col = db.get_prescriptions_collection()
    rx_mongo = rx_dict.copy()
    if "date" in rx_mongo and isinstance(rx_mongo["date"], str):
        try:
            rx_mongo["date"] = datetime.fromisoformat(rx_mongo["date"])
        except Exception:
            pass
    prescriptions_col.insert_one(rx_mongo)

    # 5. Blockchain blocks
    if bm:
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
        # Auto-revoke access after prescription is committed
        bm.add_block("ACCESS_REVOKE", {
            "patient_name": rx_dict["patientName"],
            "doctor_id": doctor_sign_id,
            "doctor_name": rx_dict["doctorName"],
            "revoked_at": datetime.utcnow().isoformat(),
            "reason": "auto_revoke_post_prescription",
        })

    # 6. Mark active consultation as completed
    consultations_col = db.get_consultations_collection()
    safe_name = re.escape(rx_dict["patientName"])
    consultations_col.find_one_and_update(
        {"patientName": {"$regex": f"^{safe_name}$", "$options": "i"}, "status": "accepted"},
        {"$set": {"status": "completed"}},
        sort=[("createdAt", -1)],
    )

    # 7. Activity log
    await ledger_service.log_activity(
        db, "CREATE_PRESCRIPTION",
        rx_dict["patientName"], doctor_sign_id,
        f"Doctor {rx_dict['doctorName']} created prescription {rx_dict['id']} for {rx_dict['disease']}.",
        onchain_tx_hash=onchain_tx_hash
    )

    result = _serialize_doc(rx_mongo)
    if access_warning:
        result["access_warning"] = access_warning
    return result
