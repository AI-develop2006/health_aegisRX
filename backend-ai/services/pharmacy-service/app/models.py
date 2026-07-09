"""Pharmacy Service — Pydantic Models"""
from pydantic import BaseModel, Field
from typing import Optional


class PharmacyLoginInput(BaseModel):
    pharmacy_id: str = Field(..., example="PHARMA-001")
    password: str = Field(..., example="pharmacy123")


class VerifyScanInput(BaseModel):
    raw_payload: str = Field(..., description="Pipe-separated raw prescription payload")
    signature: str = Field(..., description="Hex-shifted SHA-256 signature")
    timestamp: str = Field(..., description="Scan timestamp")


class DispenseInput(BaseModel):
    id: str = Field(..., example="RX-9921")
    batch_number: Optional[str] = None
    expiry_date: Optional[str] = None
    touch_signature: Optional[str] = None
    delivery_tracking_id: Optional[str] = None
    billing_amount: Optional[float] = None
    receipt_attached: Optional[bool] = None


class DispenseRequest(BaseModel):
    rx_id: str = Field(..., example="RX-9921")
    pharmacy_id: Optional[str] = Field(None, example="PHARMA-001")
