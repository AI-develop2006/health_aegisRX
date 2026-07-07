"""Prescription Service — Pydantic models"""
from pydantic import BaseModel, Field
from typing import Optional, List


class PrescriptionMedicine(BaseModel):
    name: str = Field(..., example="Metformin 500mg")
    interval: str = Field(..., example="Once daily")
    morning: bool = Field(False, example=True)
    afternoon: bool = Field(False, example=False)
    evening: bool = Field(False, example=False)
    night: bool = Field(False, example=True)
    beforeFood: bool = Field(False, example=True)
    afterFood: bool = Field(False, example=False)
    customInstruction: Optional[str] = Field("", example="Take with warm water")
    duration: Optional[str] = Field("30 days", example="30 days")
    strength: Optional[str] = Field("500mg", example="500mg")


class PrescriptionCreate(BaseModel):
    id: str = Field(..., example="RX-0001")
    doctorName: str = Field(..., example="Dr. Arun Kumar")
    hospitalName: str = Field(..., example="Apollo Hospital")
    patientName: str = Field(..., example="Elena Vance")
    patient_id: Optional[str] = Field(None, description="Internal patient ID (falls back to patientName)")
    disease: str = Field(..., example="Type 2 Diabetes")
    date: str = Field(..., example="2026-07-05")
    time: str = Field(..., example="10:00")
    medicines: List[PrescriptionMedicine]
    doctorSignId: Optional[str] = Field("889218", example="992818")
    riskBand: Optional[str] = Field(None, example="CRITICAL")
    overrideReason: Optional[str] = Field(None, example="Allergy verified, low dose justified")


class PrescriptionResponse(BaseModel):
    id: str
    doctorName: str
    hospitalName: str
    patientName: str
    patient_id: Optional[str] = None
    disease: str
    date: str
    time: str
    medicines: List[PrescriptionMedicine]
    signature: Optional[str] = None
    doctorSignId: Optional[str] = None
    isDispensed: bool = False
    riskBand: Optional[str] = None
    overrideReason: Optional[str] = None
