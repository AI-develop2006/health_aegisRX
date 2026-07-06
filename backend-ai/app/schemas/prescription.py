from typing import Optional
from pydantic import BaseModel, Field, field_validator

class MedicationDetail(BaseModel):
    name: str = Field(..., description="Name of the medication")
    dosage: Optional[str] = Field(None, description="Dosage of the medication (e.g. 500mg)")
    frequency: Optional[str] = Field(None, description="Frequency (e.g. once daily)")
    route: Optional[str] = Field(None, description="Administration route (e.g. oral, intravenous)")

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("Medication name cannot be empty")
        return v.strip()
