"""
Auth Service — Business Logic
Self-contained: uses only app.config, app.db — no shared monolith imports.
"""
import uuid
import logging
from datetime import datetime

from argon2 import PasswordHasher
from argon2.exceptions import VerifyMismatchError
from fastapi import HTTPException

from app.db import patients_col, doctors_col, activity_logs_col

logger = logging.getLogger("auth-service")
_ph = PasswordHasher()


# ─────────────────────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────────────────────
def _log(event: str, actor: str, details: str):
    try:
        activity_logs_col().insert_one({
            "timestamp": datetime.utcnow(),
            "eventType": event,
            "actorId": actor,
            "details": details,
        })
    except Exception as e:
        logger.warning(f"Activity log failed: {e}")


# ─────────────────────────────────────────────────────────────────────────────
# PATIENT AUTH
# ─────────────────────────────────────────────────────────────────────────────
async def patient_register(name: str, email: str, password: str) -> dict:
    email = email.strip().lower()
    name = name.strip()
    logger.info(f"Patient register: {email}")

    if patients_col().find_one({"email": email}):
        raise HTTPException(status_code=409, detail="Email already registered")

    session_token = str(uuid.uuid4())
    doc = {
        "name": name,
        "email": email,
        "password_hash": _ph.hash(password),
        "session_token": session_token,
        "createdAt": datetime.utcnow(),
        "is_active": True,
    }
    result = patients_col().insert_one(doc)
    _log("PATIENT_REGISTER", email, f"New patient: {name}")
    return {"_id": str(result.inserted_id), "name": name, "email": email, "token": session_token}


async def patient_login(email: str, password: str) -> dict:
    email = email.strip().lower()
    logger.info(f"Patient login: {email}")

    doc = patients_col().find_one({"email": email})
    try:
        if not doc:
            raise VerifyMismatchError()
        _ph.verify(doc.get("password_hash", ""), password)
    except VerifyMismatchError:
        raise HTTPException(status_code=401, detail="Invalid email or password")

    session_token = str(uuid.uuid4())
    patients_col().update_one({"_id": doc["_id"]}, {"$set": {"session_token": session_token}})
    _log("PATIENT_LOGIN", email, f"Patient signed in: {email}")
    return {"_id": str(doc["_id"]), "name": doc.get("name", ""), "email": email, "token": session_token}


async def patient_update_name(session_token: str, new_name: str) -> dict:
    doc = patients_col().find_one({"session_token": session_token})
    if not doc:
        raise HTTPException(status_code=401, detail="Invalid or expired session")
    patients_col().update_one({"_id": doc["_id"]}, {"$set": {"name": new_name.strip()}})
    return {"ok": True, "name": new_name.strip()}


# ─────────────────────────────────────────────────────────────────────────────
# DOCTOR AUTH
# ─────────────────────────────────────────────────────────────────────────────
async def doctor_register(name: str, hospital_name: str, doctor_mobile: str) -> dict:
    doc_id = str(doctor_mobile).strip()
    logger.info(f"Doctor register: {doc_id}")

    col = doctors_col()
    existing = col.find_one({"doctor_id": doc_id})
    if not existing:
        doc = {
            "doctor_id": doc_id,
            "name": name.strip(),
            "hospitalName": hospital_name.strip(),
            "createdAt": datetime.utcnow(),
            "is_active": True,
        }
        col.insert_one(doc.copy())
    else:
        col.update_one(
            {"doctor_id": doc_id},
            {"$set": {"name": name.strip(), "hospitalName": hospital_name.strip()}}
        )
        doc = existing
        doc["name"] = name.strip()
        doc["hospitalName"] = hospital_name.strip()

    doc.pop("_id", None)
    if "createdAt" in doc and isinstance(doc["createdAt"], datetime):
        doc["createdAt"] = doc["createdAt"].isoformat()
    _log("DOCTOR_REGISTER", doc_id, f"Doctor {name} registered from {hospital_name}")
    return doc


async def doctor_login(doctor_mobile: str) -> dict:
    doc_id = str(doctor_mobile).strip()
    logger.info(f"Doctor login: {doc_id}")

    doc = doctors_col().find_one({"doctor_id": doc_id})
    if not doc:
        raise HTTPException(status_code=404, detail="Doctor ID not found. Please register first.")

    doc.pop("_id", None)
    if "createdAt" in doc and isinstance(doc["createdAt"], datetime):
        doc["createdAt"] = doc["createdAt"].isoformat()
    _log("DOCTOR_LOGIN", doc_id, f"Doctor signed in: {doc_id}")
    return doc
