"""Auth Service — Pydantic request/response models"""
from pydantic import BaseModel, Field
from typing import Optional


# ── Patient ──────────────────────────────────────────────────────────────────

class PatientSignup(BaseModel):
    name: str = Field(..., example="Elena Vance")
    email: str = Field(..., example="elena@example.com")
    password: str = Field(..., min_length=6, example="secret123")


class PatientLoginInput(BaseModel):
    email: str = Field(..., example="elena@example.com")
    password: str = Field(..., example="secret123")


class PatientUpdateNameInput(BaseModel):
    name: str = Field(..., example="Elena Vance")


# ── Doctor ───────────────────────────────────────────────────────────────────

class DoctorRegisterInput(BaseModel):
    name: str = Field(..., example="Dr. Arun Kumar")
    hospitalName: str = Field(..., example="Apollo Hospital")
    doctorMobile: str = Field(..., example="9876543210")


class DoctorLoginInput(BaseModel):
    doctorMobile: str = Field(..., example="9876543210")
