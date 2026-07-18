"""Audit Service — Routes"""
from fastapi import APIRouter, HTTPException
from app.models import AuditRequest, DuplicateRequest, InteractionRequest, AllergyRequest, RecommendationRequest
from app import service
from app.ai.services.ai_service import run_full_audit
from app.schemas.response import AuditResponse

router = APIRouter(prefix="/api", tags=["Audit"])


@router.post("/audit", response_model=AuditResponse, summary="Full AI prescription audit")
async def audit_prescription(req: AuditRequest):
    try:
        return await run_full_audit(req)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))



@router.post("/duplicate-check", summary="Duplicate medicine detection")
async def duplicate_check(req: DuplicateRequest):
    # Perform simple duplicate check logic
    patient_id = req.patient_id
    new_medicine = req.new_medicine
    new_dosage = req.new_dosage

    # Check for direct duplicates
    from app.db import prescriptions_col
    from datetime import datetime
    from app.ai.services.patient_context import parse_duration_days
    now = datetime.now()
    active_rxs = prescriptions_col().find({"patientName": patient_id, "isDispensed": False})
    is_duplicate = False
    dup_details = ""
    for rx in active_rxs:
        rx_date = rx.get("date")
        if rx_date:
            if isinstance(rx_date, str):
                try:
                    date_clean = rx_date.split("+")[0]
                    rx_date = datetime.fromisoformat(date_clean)
                except Exception:
                    pass

        for med in rx.get("medicines", []):
            name = med.get("name", "")
            if name.lower().split()[0] == new_medicine.lower().split()[0]:
                is_active = True
                diff_days = None
                if rx_date and isinstance(rx_date, datetime):
                    diff_days = abs((now - rx_date).days)
                    dur_str = med.get("duration", "30 days")
                    dur_days = parse_duration_days(dur_str)
                    if diff_days > dur_days:
                        is_active = False
                
                if is_active:
                    is_duplicate = True
                    dup_details = f"Patient is already taking {name} (prescribed {diff_days} days ago)." if diff_days is not None else f"Patient is already taking {name}."
                    break
        if is_duplicate:
            break

    result = {
        "is_duplicate": is_duplicate,
        "duplicate_details": dup_details,
        "alert_doctor_2": is_duplicate,
        "previous_visits": []
    }
    return result


@router.post("/interaction-check", summary="Drug interaction check (Multi-Agent AI)")
async def interaction_check(req: InteractionRequest):
    return await service.check_interactions(req.patient_id, req.new_medicine, req.new_dosage)


@router.post("/allergy-check", summary="Allergy conflict check")
async def allergy_check(req: AllergyRequest):
    return await service.check_allergy(req.patient_id, req.new_medicine)


@router.post("/recommendations", summary="AI medicine recommendations")
async def recommend_alternatives(req: RecommendationRequest):
    return await service.recommend_alternatives(req.patient_id, req.disease, req.current_medicine)
