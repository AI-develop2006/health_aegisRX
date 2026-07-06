import uuid
from datetime import datetime
from fastapi import HTTPException
from argon2 import PasswordHasher
from argon2.exceptions import VerifyMismatchError

from app.config import logger
from app.db.mongodb import MongoDBConnector

_ph = PasswordHasher()


# ============================================
# PATIENT AUTH
# ============================================
async def patient_register(db: MongoDBConnector, name: str, email: str, password: str) -> dict:
    """Register a new patient account."""
    email = email.strip().lower()
    name = name.strip()
    logger.info(f"Patient Registration Request. Email: {email}, Name: {name}")

    patients_col = db.get_patients_collection()
    existing = patients_col.find_one({"email": email})
    if existing:
        raise HTTPException(status_code=409, detail="Email already registered")

    session_token = str(uuid.uuid4())
    doc = {
        "name": name,
        "email": email,
        "password_hash": _ph.hash(password),
        "session_token": session_token,
        "createdAt": datetime.utcnow(),
    }
    result = patients_col.insert_one(doc)
    return {"_id": str(result.inserted_id), "name": name, "email": email, "token": session_token}


async def patient_login(db: MongoDBConnector, email: str, password: str) -> dict:
    """Authenticate a patient and rotate their session token."""
    email = email.strip().lower()
    logger.info(f"Patient Login Request. Email: {email}")

    patients_col = db.get_patients_collection()
    doc = patients_col.find_one({"email": email})
    try:
        if not doc:
            raise VerifyMismatchError()
        _ph.verify(doc.get("password_hash", ""), password)
    except VerifyMismatchError:
        raise HTTPException(status_code=401, detail="Invalid email or password")

    session_token = str(uuid.uuid4())
    patients_col.update_one({"_id": doc["_id"]}, {"$set": {"session_token": session_token}})
    return {"_id": str(doc["_id"]), "name": doc.get("name", ""), "email": email, "token": session_token}


async def patient_update_name(db: MongoDBConnector, session_token: str, new_name: str) -> dict:
    """Update a patient's display name (requires valid session token)."""
    patients_col = db.get_patients_collection()
    doc = patients_col.find_one({"session_token": session_token})
    if not doc:
        raise HTTPException(status_code=401, detail="Invalid or expired session")
    patients_col.update_one({"_id": doc["_id"]}, {"$set": {"name": new_name.strip()}})
    return {"ok": True, "name": new_name.strip()}


async def require_patient_session(db: MongoDBConnector, session_token: str) -> dict:
    """Validate a patient session token. Returns patient info dict."""
    patients_col = db.get_patients_collection()
    patient = patients_col.find_one({"session_token": session_token})
    if not patient:
        raise HTTPException(status_code=401, detail="Invalid or expired session")
    return {"name": patient.get("name", ""), "email": patient.get("email", "")}


# ============================================
# DOCTOR AUTH
# ============================================
async def doctor_register(db: MongoDBConnector, name: str, hospital_name: str, doctor_mobile: str) -> dict:
    """Register or update a doctor record (upsert by mobile number)."""
    doc_id_str = str(doctor_mobile)
    logger.info(f"Doctor Registration Request. ID: {doc_id_str}, Name: {name}")

    doctors_col = db.get_doctors_collection()
    doc = doctors_col.find_one({"doctor_id": doc_id_str})
    if not doc:
        doc = {
            "doctor_id": doc_id_str,
            "name": name,
            "hospitalName": hospital_name,
            "createdAt": datetime.utcnow()
        }
        doctors_col.insert_one(doc.copy())
    else:
        doctors_col.update_one(
            {"doctor_id": doc_id_str},
            {"$set": {"name": name, "hospitalName": hospital_name}}
        )
        doc["name"] = name
        doc["hospitalName"] = hospital_name

    doc.pop("_id", None)
    return doc


async def doctor_login(db: MongoDBConnector, doctor_mobile: str) -> dict:
    """Authenticate a doctor by their mobile number (used as doctor_id)."""
    doc_id_str = str(doctor_mobile)
    logger.info(f"Doctor Sign-In Request. ID: {doc_id_str}")

    doctors_col = db.get_doctors_collection()
    doc = doctors_col.find_one({"doctor_id": doc_id_str})
    if not doc:
        raise HTTPException(status_code=404, detail="Doctor ID not found. Please register first.")

    doc.pop("_id", None)
    if "createdAt" in doc and isinstance(doc["createdAt"], datetime):
        doc["createdAt"] = doc["createdAt"].isoformat()
    return doc
