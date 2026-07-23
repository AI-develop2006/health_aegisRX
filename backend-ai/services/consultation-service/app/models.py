"""Consultation Service — Pydantic models"""
from pydantic import BaseModel, Field
from typing import Optional
from enum import Enum


class ConsultationStatus(str, Enum):
    pending = "pending"
    accepted = "accepted"
    rejected = "rejected"
    completed = "completed"


class ConsultationRequestInput(BaseModel):
    patientName: str = Field(..., example="Elena Vance")
    patientId: Optional[str] = Field(None, description="Internal patient ID; falls back to patientName")
    doctorId: Optional[str] = Field(None, example="9876543210")


class AcceptRejectInput(BaseModel):
    id: str = Field(..., description="Consultation request ID", example="req_a1b2c3d4")


class CancelInput(BaseModel):
    id: Optional[str] = Field(None, description="Consultation request ID", example="req_a1b2c3d4")
    patient_id: Optional[str] = Field(None, description="Patient ID", example="992818")
    patient_name: Optional[str] = Field(None, description="Patient display name", example="Elena Vance")
    doctor_id: Optional[str] = Field(None, description="Doctor license number", example="889218")


class ConsultationResponse(BaseModel):
    id: str
    patientName: str
    patientId: Optional[str] = None
    doctorId: Optional[str] = None
    status: ConsultationStatus
    createdAt: Optional[str] = None
