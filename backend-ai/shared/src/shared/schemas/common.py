from pydantic import BaseModel, Field
from typing import Optional, List


class PrescriptionMedicine(BaseModel):
    name: str = Field(..., example="Metformin 500mg")
    interval: str = Field(..., example="Once daily after breakfast")


class TokenResponse(BaseModel):
    id: Optional[str] = None
    name: str
    email: Optional[str] = None
    token: str


class AuthResponse(BaseModel):
    ok: bool
    message: Optional[str] = None
    token: Optional[str] = None
