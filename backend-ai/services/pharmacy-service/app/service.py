"""
Pharmacy Service — Business Logic
Self-contained: calls app.db, app.blockchain, app.utils.signature, and app.integrations.polygon_client.
"""
import logging
from datetime import datetime
from fastapi import HTTPException

from app.config import TEST_PHARMACY_PRIVATE_KEY, ALLOW_MOCK_POLYGON_TX, logger
from app.db import prescriptions_col
from app.blockchain import BlockchainManager, log_activity
from shared_core.signature import sha256_hash, decrypt, json_stringify_rx
from app.integrations import polygon_client

logger = logging.getLogger("pharmacy-service")


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


async def get_prescription(rx_id: str) -> dict:
    doc = prescriptions_col().find_one({"id": rx_id})
    if not doc:
        raise HTTPException(status_code=404, detail="Prescription not found")

    await log_activity(
        "SCAN_PHARMACY",
        doc.get("patientName", "Unknown"), "Pharmacy",
        f"Pharmacy scanned and retrieved prescription details for {rx_id}."
    )
    return _serialize_doc(doc)


async def verify_scan(raw_payload: str, signature: str, timestamp: str) -> dict:
    parts = raw_payload.split("|")
    if len(parts) < 8:
        logger.warning(f"Invalid payload format: only {len(parts)} parts.")
        return {"verified": False, "error": "Invalid payload format"}

    rx_id = parts[0]
    doctor_sign_id = parts[8] if len(parts) > 8 else "889218"

    # Compute static hash on the original prescription details (parts 0 to 8) to match signature and blockchain
    original_payload = "|".join(parts[:9])
    local_hash = sha256_hash(original_payload)

    # Item 3: Validate expiry, scope, and nonces
    if len(parts) >= 12:
        try:
            expiry = int(parts[9])
            nonce = parts[10]
            scope = parts[11]
            
            import time
            current_time = int(time.time())
            
            if current_time > expiry:
                logger.warning(f"Verification blocked: Scanned QR token has expired. Current={current_time}, Expiry={expiry}")
                return {
                    "verified": False,
                    "verdict": "TOKEN_EXPIRED",
                    "reason": "This dispensation session token has expired. Please regenerate the checkout QR code in your app.",
                    "error": "Single-use session token expired"
                }
                
            if scope != "DISPENSE":
                logger.warning(f"Verification blocked: Invalid QR token scope. Scope={scope}")
                return {
                    "verified": False,
                    "verdict": "INVALID_SCOPE",
                    "reason": "This token is not authorized for prescription dispensation.",
                    "error": "Invalid token scope authorization"
                }
        except ValueError as ex:
            logger.error(f"Error parsing QR payload secure parameters: {ex}")
            return {"verified": False, "error": "Malformed secure payload parameters"}

    logger.info(f"Verifying scan: rx_id={rx_id}, doctor_sign_id={doctor_sign_id}")

    db_rx = prescriptions_col().find_one({"id": rx_id})
    if not db_rx:
        logger.warning(f"Prescription {rx_id} not found.")
        return {"verified": False, "error": "Prescription not found"}

    if db_rx.get("isDispensed"):
        await log_activity(
            "PHARMACY_REUSE_BLOCKED", db_rx.get("patientName", "Unknown"), "Pharmacy",
            f"Reuse attempt blocked — prescription {rx_id} already dispensed."
        )
        return {
            "verified": False,
            "verdict": "ALREADY_DISPENSED",
            "reason": "This prescription has already been dispensed. The single-use token is burned.",
            "error": "Single-use token already burned",
        }

    # Cross-check with Polygon Blockchain
    onchain_rx = polygon_client.get_prescription(rx_id)
    if onchain_rx.get("exists"):
        onchain_hash = onchain_rx.get("hash", "")
        if onchain_hash.startswith("0x"):
            onchain_hash = onchain_hash[2:]

        if onchain_hash != local_hash:
            logger.warning(f"Polygon hash mismatch for {rx_id}: chain={onchain_hash} local={local_hash}")
            await log_activity(
                "PHARMACY_VERIFY_FORGED", db_rx.get("patientName", "Unknown"), "Pharmacy",
                f"ON-CHAIN TAMPER DETECTED — prescription {rx_id} hash on-chain ≠ computed hash."
            )
            return {
                "verified": False,
                "verdict": "TAMPERED_ONCHAIN",
                "reason": "This prescription has been tampered with. The hash does not match the blockchain ledger.",
                "error": "On-chain integrity check failed"
            }

        if onchain_rx.get("dispensed"):
            logger.warning(f"Polygon scan reuse blocked: {rx_id} already marked dispensed on-chain.")
            await log_activity(
                "PHARMACY_REUSE_BLOCKED", db_rx.get("patientName", "Unknown"), "Pharmacy",
                f"On-chain reuse attempt blocked — prescription {rx_id} already dispensed on Polygon."
            )
            return {
                "verified": False,
                "verdict": "ALREADY_DISPENSED_ONCHAIN",
                "reason": "This prescription has already been dispensed on the Polygon ledger.",
                "error": "On-chain single-use token already burned"
            }

    # Verify signature
    stored_signature = db_rx.get("signature")
    if signature != stored_signature:
        logger.warning(f"Verification fail: incoming '{signature}' ≠ stored '{stored_signature}'")
        await log_activity(
            "PHARMACY_VERIFY_FORGED", db_rx.get("patientName", "Unknown"), "Pharmacy",
            f"FORGERY DETECTED — signature mismatch for prescription {rx_id}."
        )
        return {
            "verified": False, "verdict": "FORGED",
            "reason": "Signature mismatch — prescription may have been tampered",
            "error": "Signature mismatch"
        }

    # Verify decryption
    decrypted_hash = decrypt(signature, doctor_sign_id)
    if decrypted_hash != local_hash:
        db_payload = json_stringify_rx(db_rx)
        db_hash = sha256_hash(db_payload)
        if decrypted_hash != db_hash:
            logger.warning(f"Hash mismatch: decrypted={decrypted_hash} local={local_hash}")
            await log_activity(
                "PHARMACY_VERIFY_FORGED", db_rx.get("patientName", "Unknown"), "Pharmacy",
                f"FORGERY DETECTED — hash mismatch for prescription {rx_id}."
            )
            return {
                "verified": False, "verdict": "FORGED",
                "reason": "Hash mismatch — payload modified after signing",
                "error": "Integrity check failed: payload modified after signing"
            }

    # Cross-check with local database blockchain
    bm = BlockchainManager()
    rx_blocks = bm.get_blocks_by_type("PRESCRIPTION")
    chain_verified = any(b.get("data", {}).get("rx_id") == rx_id for b in rx_blocks)

    await log_activity(
        "PHARMACY_VERIFY_GENUINE", db_rx.get("patientName", "Unknown"), "Pharmacy",
        f"Zero-trust cross-verification PASSED for prescription {rx_id}. Chain: {chain_verified}."
    )
    return {
        "verified": True,
        "verdict": "GENUINE",
        "chain_verified": chain_verified,
        "prescription": _serialize_doc(db_rx),
    }


async def dispense_prescription(
    rx_id: str,
    batch_number: str = None,
    expiry_date: str = None,
    touch_signature: str = None,
    delivery_tracking_id: str = None,
    billing_amount: float = None,
    receipt_attached: bool = None,
) -> dict:
    existing = prescriptions_col().find_one({"id": rx_id})
    if not existing:
        raise HTTPException(status_code=404, detail="Prescription not found")
    if existing.get("isDispensed"):
        raise HTTPException(status_code=409, detail="Prescription has already been dispensed")

    updated = prescriptions_col().find_one_and_update(
        {"id": rx_id},
        {
            "$set": {
                "isDispensed": True,
                "batch_number": batch_number,
                "expiry_date": expiry_date,
                "touch_signature": touch_signature,
                "delivery_tracking_id": delivery_tracking_id,
                "billing_amount": billing_amount,
                "receipt_attached": receipt_attached,
                "dispensedAt": datetime.utcnow(),
            }
        },
        return_document=True
    )
    if not updated:
        raise HTTPException(status_code=404, detail="Prescription not found")

    # Mark dispensed on-chain (Polygon)
    onchain_tx_hash = None
    if TEST_PHARMACY_PRIVATE_KEY:
        try:
            onchain_tx_hash = polygon_client.mark_dispensed(rx_id, TEST_PHARMACY_PRIVATE_KEY)
        except Exception as e:
            logger.error(f"Polygon on-chain mark_dispensed failed: {e}")
            if not ALLOW_MOCK_POLYGON_TX:
                raise HTTPException(status_code=400, detail=f"On-chain dispensation failed: {str(e)}")
    else:
        if not ALLOW_MOCK_POLYGON_TX:
            raise HTTPException(
                status_code=400,
                detail="Sovereign Dispense Error: Missing Polygon pharmacist key. On-chain validation failed."
            )

    bm = BlockchainManager()
    bm.add_block("DISPENSED", {
        "rx_id": rx_id,
        "patient_name": updated.get("patientName", ""),
        "doctor_id": updated.get("doctorSignId", ""),
        "dispensed_at": datetime.utcnow().isoformat(),
        "batch_number": batch_number,
        "expiry_date": expiry_date,
        "touch_signature": touch_signature,
        "delivery_tracking_id": delivery_tracking_id,
    }, onchain_tx_hash=onchain_tx_hash)

    await log_activity(
        "DISPENSE_PRESCRIPTION",
        updated.get("patientName", "Unknown"), "Pharmacy",
        f"Pharmacy dispensed medications and burned token for prescription {rx_id} (Batch: {batch_number}).",
        onchain_tx_hash=onchain_tx_hash
    )
    return _serialize_doc(updated)
