from fastapi import APIRouter
from app.models.pharmacy import VerifyScanInput, DispenseInput
from app.db.mongodb import get_connector
from app.services import pharmacy_service

router = APIRouter(prefix="/api", tags=["Pharmacy"])


@router.get("/prescriptions/{rx_id}", summary="Fetch prescription by RX ID (pharmacy view)", include_in_schema=False)
async def get_prescription_pharmacy(rx_id: str):
    """
    Pharmacy-facing prescription fetch.
    NOTE: This is also served by the doctor router at the same path.
    The doctor router is registered first, so this acts as a labelled alias.
    """
    db = get_connector()
    return await pharmacy_service.get_prescription(db, rx_id)


@router.post("/prescriptions/verify-scan", summary="Verify a scanned prescription payload")
async def verify_scan(data: VerifyScanInput):
    db = get_connector()
    try:
        return await pharmacy_service.verify_scan(db, data.raw_payload, data.signature, data.timestamp)
    except Exception as e:
        from fastapi import HTTPException
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/prescriptions/dispense", summary="Dispense a prescription (marks as used)")
async def dispense_prescription(input_data: DispenseInput):
    db = get_connector()
    return await pharmacy_service.dispense_prescription(db, input_data.id)
