from fastapi import APIRouter, Header, Depends
from app.models.patient import PatientSignup, PatientLoginInput, PatientUpdateNameInput
from app.models.doctor import DoctorRegisterInput, DoctorLoginInput
from app.db.mongodb import get_connector
from app.services import auth_service, ledger_service

router = APIRouter(prefix="/api", tags=["Auth"])


# ============================================
# PATIENT AUTH ENDPOINTS
# ============================================
@router.post("/patient/register", summary="Patient registration")
async def patient_register(input_data: PatientSignup):
    db = get_connector()
    result = await auth_service.patient_register(
        db, input_data.name, input_data.email, input_data.password
    )
    await ledger_service.log_activity(
        db, "PATIENT_REGISTER", input_data.name, input_data.email,
        f"New patient account created: {input_data.name}"
    )
    return result


@router.post("/patient/login", summary="Patient login")
async def patient_login(input_data: PatientLoginInput):
    db = get_connector()
    result = await auth_service.patient_login(db, input_data.email, input_data.password)
    await ledger_service.log_activity(
        db, "PATIENT_LOGIN", result.get("name", input_data.email), input_data.email,
        f"Patient signed in: {input_data.email}"
    )
    return result


@router.post("/patient/update-name", summary="Update patient display name")
async def patient_update_name(
    input_data: PatientUpdateNameInput,
    x_session_token: str = Header(..., alias="X-Session-Token"),
):
    db = get_connector()
    return await auth_service.patient_update_name(db, x_session_token, input_data.name)


# ============================================
# DOCTOR AUTH ENDPOINTS
# ============================================
@router.post("/doctor/register", summary="Doctor registration / update")
async def doctor_register(input_data: DoctorRegisterInput):
    db = get_connector()
    result = await auth_service.doctor_register(
        db, input_data.name, input_data.hospitalName, input_data.doctorMobile
    )
    await ledger_service.log_activity(
        db, "DOCTOR_REGISTER", "N/A", str(input_data.doctorMobile),
        f"Doctor {input_data.name} registered from {input_data.hospitalName}."
    )
    return result


@router.post("/doctor/login", summary="Doctor login by mobile number")
async def doctor_login(input_data: DoctorLoginInput):
    db = get_connector()
    result = await auth_service.doctor_login(db, input_data.doctorMobile)
    await ledger_service.log_activity(
        db, "DOCTOR_LOGIN", "N/A", str(input_data.doctorMobile),
        f"Doctor {result.get('name', 'Unknown')} signed in successfully."
    )
    return result
