"""Patient Service — Routes"""
from fastapi import APIRouter
from app import service

router = APIRouter(prefix="/api/patient", tags=["Patient"])


@router.get("/dashboard/{patient_id}", summary="Patient dashboard")
async def dashboard(patient_id: str):
    return service.get_dashboard(patient_id)


@router.get("/prescriptions/{patient_id}", summary="All prescriptions for patient")
async def prescriptions(patient_id: str):
    return service.get_prescriptions(patient_id)
