from pydantic import BaseModel, Field
from typing import Optional


class PatientSignup(BaseModel):
    name: str = Field(..., example="Elena Vance")
    email: str = Field(..., example="elena@example.com")
    password: str = Field(..., min_length=6, example="secret123")


class PatientLoginInput(BaseModel):
    email: str = Field(..., example="elena@example.com")
    password: str = Field(..., example="secret123")


class PatientUpdateNameInput(BaseModel):
    name: str = Field(..., example="Elena Vance")


class PatientResponse(BaseModel):
    id: Optional[str] = None
    name: str
    email: str
    token: Optional[str] = None


class PatientDashboard(BaseModel):
    patient_id: str
    patient_name: str
    total_prescriptions: int
    active_prescriptions: int
    dispensed_prescriptions: int
    alert_level: str
    flagged_medicines: list[str]
