"""Pharmacy Service — Routes"""
from fastapi import APIRouter, HTTPException
from app.models import VerifyScanInput, DispenseInput
from app import service

router = APIRouter(prefix="/api", tags=["Pharmacy"])


@router.get("/prescriptions/{rx_id}", summary="Fetch prescription by RX ID")
async def get_prescription(rx_id: str):
    return await service.get_prescription(rx_id)


@router.post("/prescriptions/verify-scan", summary="Verify scanned payload")
async def verify_scan(data: VerifyScanInput):
    try:
        return await service.verify_scan(data.raw_payload, data.signature, data.timestamp)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/prescriptions/dispense", summary="Dispense prescription")
async def dispense_prescription(input_data: DispenseInput):
    return await service.dispense_prescription(
        rx_id=input_data.id,
        batch_number=input_data.batch_number,
        expiry_date=input_data.expiry_date,
        touch_signature=input_data.touch_signature,
        delivery_tracking_id=input_data.delivery_tracking_id,
        billing_amount=input_data.billing_amount,
        receipt_attached=input_data.receipt_attached,
    )
