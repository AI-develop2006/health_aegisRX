from typing import List, Optional
from pydantic import BaseModel, Field, field_validator

class PatientContext(BaseModel):
    patient_id: str = Field(..., description="Unique identifier for the patient")
    age: int = Field(..., description="Age of the patient in years")
    gender: str = Field(..., description="Gender of the patient (e.g., Male, Female, Other)")
    weight: Optional[float] = Field(None, description="Weight of the patient in kilograms")
    allergies: List[str] = Field(default_factory=list, description="List of patient allergies")
    diseases: List[str] = Field(default_factory=list, description="List of active patient medical conditions/diseases")
    current_medications: List[str] = Field(default_factory=list, description="Medications the patient is currently taking")
    previous_prescriptions: List[str] = Field(default_factory=list, description="List of previously prescribed drugs")
    new_prescription: List[str] = Field(..., description="List of newly prescribed medications to evaluate")
    is_pregnant: Optional[bool] = Field(None, description="Pregnancy status of the patient (if applicable)")

    @field_validator("patient_id")
    @classmethod
    def validate_patient_id(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("patient_id cannot be empty or whitespace")
        return v.strip()

    @field_validator("age")
    @classmethod
    def validate_age(cls, v: int) -> int:
        if v <= 0 or v > 125:
            raise ValueError("Age must be a positive integer between 1 and 125")
        return v

    @field_validator("gender")
    @classmethod
    def validate_gender(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("Gender cannot be empty or whitespace")
        return v.strip()

    @field_validator("weight")
    @classmethod
    def validate_weight(cls, v: Optional[float]) -> Optional[float]:
        if v is not None and v <= 0:
            raise ValueError("Weight must be greater than 0")
        return v

    @field_validator("new_prescription")
    @classmethod
    def validate_new_prescription(cls, v: List[str]) -> List[str]:
        if not v:
            raise ValueError("new_prescription cannot be empty")
        cleaned = [med.strip() for med in v if med.strip()]
        if not cleaned:
            raise ValueError("new_prescription must contain at least one valid non-empty medicine name")
        return cleaned
