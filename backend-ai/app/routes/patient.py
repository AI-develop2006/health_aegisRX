from fastapi import APIRouter, Header, Depends
from typing import Optional
from app.db.mongodb import get_connector
from app.services import patient_service, auth_service

router = APIRouter(prefix="/api/patient", tags=["Patient"])


@router.get("/dashboard/{patient_id}", summary="Patient dashboard summary")
async def get_dashboard(patient_id: str):
    db = get_connector()
    return patient_service.get_patient_dashboard(db, patient_id)


@router.get("/prescriptions/{patient_id}", summary="Get all prescriptions for a patient")
async def get_prescriptions(patient_id: str):
    db = get_connector()
    return patient_service.get_patient_prescriptions(db, patient_id)
