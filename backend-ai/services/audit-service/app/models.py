"""Audit Service — Pydantic Models"""
from pydantic import BaseModel, Field
from typing import Optional, List
from enum import Enum


class RiskBand(str, Enum):
    LOW = "LOW"
    MEDIUM = "MEDIUM"
    HIGH = "HIGH"
    CRITICAL = "CRITICAL"


class AuditRequest(BaseModel):
    patient_id: str = Field(..., example="elena_vance")
    doctor_id: str = Field(..., example="NPI-88912")
    new_medicine: str = Field(..., example="Penicillin V")
    new_dosage: str = Field(..., example="500mg")
    disease: Optional[str] = Field(None, example="Acute Strep Throat")


class DuplicateRequest(BaseModel):
    patient_id: str = Field(..., example="Priya_123")
    new_medicine: str = Field(..., example="Metformin")
    new_dosage: str = Field(..., example="500mg")


class InteractionRequest(BaseModel):
    patient_id: str = Field(..., example="Priya_123")
    new_medicine: str = Field(..., example="Metformin")
    new_dosage: str = Field(..., example="500mg")


class AllergyRequest(BaseModel):
    patient_id: str = Field(..., example="Priya_123")
    new_medicine: str = Field(..., example="Penicillin")


class RecommendationRequest(BaseModel):
    patient_id: str = Field(..., example="Priya_123")
    disease: str = Field(..., example="Type 2 Diabetes")
    current_medicine: str = Field(..., example="Metformin")
