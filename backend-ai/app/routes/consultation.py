from fastapi import APIRouter
from typing import Optional
from app.models.consultation import ConsultationRequestInput, AcceptRejectInput
from app.db.mongodb import get_connector
from app.services import consultation_service

router = APIRouter(prefix="/api/consultation", tags=["Consultation Management"])


@router.post("/request", summary="Doctor initiates a consultation request")
async def create_consultation_request(input_data: ConsultationRequestInput):
    db = get_connector()
    return await consultation_service.create_consultation_request(
        db,
        patient_name=input_data.patientName,
        patient_id=input_data.patientId,
        doctor_id=input_data.doctorId,
    )


@router.get("/status/{req_id}", summary="Get status of a consultation request")
async def get_consultation_status(req_id: str):
    db = get_connector()
    return await consultation_service.get_consultation_status(db, req_id)


@router.get("/pending", summary="Get latest pending consultation for a patient")
async def get_pending_consultation(patient: str, patientId: Optional[str] = None):
    db = get_connector()
    return await consultation_service.get_pending_consultation(db, patient, patientId)


@router.get("/has-active-session", summary="Check if patient has an active accepted consultation")
async def has_active_session(patient: str):
    db = get_connector()
    active = await consultation_service.has_active_session(db, patient)
    return {"active": active}


@router.post("/accept", summary="Patient accepts a consultation request")
async def accept_consultation(input_data: AcceptRejectInput):
    db = get_connector()
    return await consultation_service.accept_consultation(db, input_data.id)


@router.post("/reject", summary="Patient rejects a consultation request")
async def reject_consultation(input_data: AcceptRejectInput):
    db = get_connector()
    return await consultation_service.reject_consultation(db, input_data.id)
