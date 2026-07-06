"""Auth Service — FastAPI routes"""
from fastapi import APIRouter, Header
from app.models import (
    PatientSignup, PatientLoginInput, PatientUpdateNameInput,
    DoctorRegisterInput, DoctorLoginInput,
)
from app import service

router = APIRouter(prefix="/api", tags=["Auth"])


# ── Patient ───────────────────────────────────────────────────────────────────

@router.post("/patient/register", summary="Patient registration")
async def patient_register(data: PatientSignup):
    return await service.patient_register(data.name, data.email, data.password)


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
    return await service.doctor_register(data.name, data.hospitalName, data.doctorMobile)


@router.post("/doctor/login", summary="Doctor login")
async def doctor_login(data: DoctorLoginInput):
    return await service.doctor_login(data.doctorMobile)
