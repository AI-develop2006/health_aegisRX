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
async def get_prescription_by_id(rx_id: str):
    result = service.get_prescription_by_id(rx_id)
    await log_activity(
        "SCAN_PHARMACY", result.get("patientName", "Unknown"), "Pharmacy",
        f"Pharmacy retrieved prescription details for {rx_id}."
    )
    return result


@router.get("/doctor/patient-history/{patient_id}", summary="Doctor views patient history")
async def get_patient_history(patient_id: str, doctor_id: Optional[str] = Query(None)):
    return service.get_patient_history(patient_id, doctor_id)
