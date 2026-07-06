from pydantic import BaseModel, Field
from typing import Optional


class DoctorRegisterInput(BaseModel):
    name: str = Field(..., example="Dr. Arun Kumar")
    hospitalName: str = Field(..., example="Apollo Hospital")
    doctorMobile: str = Field(..., example="9876543210")


class DoctorLoginInput(BaseModel):
    doctorMobile: str = Field(..., example="9876543210")


class DoctorResponse(BaseModel):
    doctor_id: str
    name: str
    hospitalName: str
    createdAt: Optional[str] = None
