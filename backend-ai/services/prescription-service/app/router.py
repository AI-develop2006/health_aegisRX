"""Prescription Service — Routes"""
from fastapi import APIRouter, Query
from typing import Optional
from app.models import PrescriptionCreate
from app import service
from app.blockchain import log_activity

router = APIRouter(prefix="/api", tags=["Prescription"])


@router.get("/prescriptions", summary="Get prescriptions by patient name")
async def get_prescriptions(patient: str = "Elenavan"):
    return service.get_prescriptions_by_patient(patient)


@router.post("/prescriptions", summary="Create a signed prescription")
async def create_prescription(rx: PrescriptionCreate):
    rx_dict = rx.dict()
    return await service.create_prescription(rx_dict)


@router.get("/prescriptions/{rx_id}", summary="Get a single prescription by ID")
async def get_prescription(rx_id: str):
    return service.get_prescription_by_id(rx_id)


@router.get("/doctor/consultations", summary="Get prescriptions written by doctor")
async def get_doctor_consultations(doctor_id: str):
    return service.get_prescriptions_by_doctor(doctor_id)


@router.get("/doctor/patient-history/{patient_id}", summary="Doctor views patient history")
async def get_patient_history(patient_id: str, doctor_id: Optional[str] = Query(None)):
    return service.get_patient_history(patient_id, doctor_id)


@router.post("/doctor/patient-allergies", summary="Save patient allergies")
async def save_patient_allergies(req: dict):
    patient_id = req.get("patient_id")
    allergies = req.get("allergies", [])
    return await service.save_patient_allergies(patient_id, allergies)

