"""Auth Service — FastAPI routes"""
from fastapi import APIRouter, Header
from app.models import (
    PatientSignup, PatientLoginInput, PatientUpdateNameInput,
    DoctorRegisterInput, DoctorLoginInput, PharmacyLoginInput,
)
from app import service

router = APIRouter(prefix="/api", tags=["Auth"])


# ── Patient ───────────────────────────────────────────────────────────────────

@router.post("/patient/register", summary="Patient registration")
async def patient_register(data: PatientSignup):
    return await service.patient_register(
        name=data.name,
        email=data.email,
        password=data.password,
        mobile=data.mobile,
        dob=data.dob,
        gender=data.gender,
        country=data.country,
        id_type=data.id_type,
        id_number=data.id_number,
        uploaded_file_name=data.uploaded_file_name,
    )


@router.post("/patient/login", summary="Patient login")
async def patient_login(data: PatientLoginInput):
    return await service.patient_login(data.email, data.password)


@router.post("/patient/update-name", summary="Update patient display name")
async def patient_update_name(
    data: PatientUpdateNameInput,
    x_session_token: str = Header(..., alias="X-Session-Token"),
):
    return await service.patient_update_name(x_session_token, data.name)


# ── Doctor ────────────────────────────────────────────────────────────────────

@router.post("/doctor/register", summary="Doctor registration / update")
async def doctor_register(data: DoctorRegisterInput):
    return await service.doctor_register(
        name=data.name,
        hospital_name=data.hospitalName,
        doctor_mobile=data.doctorMobile,
        specialty=data.specialty,
        email=data.email,
        phone=data.phone,
    )


@router.post("/doctor/login", summary="Doctor login")
async def doctor_login(data: DoctorLoginInput):
    return await service.doctor_login(data.doctorMobile)


@router.post("/pharmacy/login", summary="Pharmacy login")
async def pharmacy_login(data: PharmacyLoginInput):
    return await service.pharmacy_login(data.pharmacy_id)
