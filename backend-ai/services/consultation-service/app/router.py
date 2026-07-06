"""Consultation Service — Routes"""
from fastapi import APIRouter
from typing import Optional
from app.models import ConsultationRequestInput, AcceptRejectInput
from app import service

router = APIRouter(prefix="/api/consultation", tags=["Consultation Management"])


@router.post("/request", summary="Doctor initiates a consultation request")
async def create_consultation_request(input_data: ConsultationRequestInput):
    return await service.create_consultation_request(
        patient_name=input_data.patientName,
        patient_id=input_data.patientId,
        doctor_id=input_data.doctorId,
    )


@router.get("/status/{req_id}", summary="Get status of a consultation request")
async def get_consultation_status(req_id: str):
    return await service.get_consultation_status(req_id)


@router.get("/pending", summary="Get latest pending consultation for a patient")
async def get_pending_consultation(patient: str, patientId: Optional[str] = None):
    return await service.get_pending_consultation(patient, patientId)


@router.get("/has-active-session", summary="Check if patient has an active accepted consultation")
async def has_active_session(patient: str):
    active = await service.has_active_session(patient)
    return {"active": active}


@router.post("/accept", summary="Patient accepts a consultation request")
async def accept_consultation(input_data: AcceptRejectInput):
    return await service.accept_consultation(input_data.id)


@router.post("/reject", summary="Patient rejects a consultation request")
async def reject_consultation(input_data: AcceptRejectInput):
    return await service.reject_consultation(input_data.id)
