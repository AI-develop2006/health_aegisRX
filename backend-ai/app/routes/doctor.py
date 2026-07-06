from fastapi import APIRouter, Query
from typing import Optional
from app.models.prescription import PrescriptionCreate
from app.models.audit import AuditRequest, DuplicateRequest, InteractionRequest, AllergyRequest, RecommendationRequest
from app.db.mongodb import get_connector
from app.services import prescription_service, doctor_service, ai_service, ledger_service

router = APIRouter(prefix="/api", tags=["Doctor"])


# ============================================
# PRESCRIPTION CRUD
# ============================================
@router.get("/prescriptions", summary="Get prescriptions by patient name")
async def get_prescriptions(patient: str = "Elenavan"):
    db = get_connector()
    return prescription_service.get_prescriptions_by_patient(db, patient)


@router.post("/prescriptions", summary="Create a signed prescription")
async def create_prescription(rx: PrescriptionCreate):
    db = get_connector()
    rx_dict = rx.dict()
    return await prescription_service.create_prescription(db, rx_dict)


@router.get("/prescriptions/{rx_id}", summary="Get a single prescription by ID")
async def get_prescription_by_id(rx_id: str):
    db = get_connector()
    result = prescription_service.get_prescription_by_id(db, rx_id)
    await ledger_service.log_activity(
        db, "SCAN_PHARMACY", result.get("patientName", "Unknown"), "Pharmacy",
        f"Pharmacy retrieved prescription details for {rx_id}."
    )
    return result


# ============================================
# DOCTOR READ ENDPOINTS (Phase 8)
# ============================================
@router.get("/doctor/patient-history/{patient_id}", summary="Doctor views patient history (requires access)")
async def get_patient_history(patient_id: str, doctor_id: Optional[str] = Query(None)):
    db = get_connector()
    return doctor_service.get_patient_history(db, patient_id, doctor_id)


@router.get("/pattern-analysis/{doctor_id}", summary="Prescribing pattern anomaly analysis for a doctor")
async def pattern_analysis(doctor_id: str):
    return doctor_service.get_pattern_analysis(doctor_id)


# ============================================
# CLINICAL AI AUDIT (Phase 6)
# ============================================
@router.post("/audit", summary="Full AI prescription audit")
async def audit_prescription(req: AuditRequest):
    try:
        return await ai_service.run_audit(
            patient_id=req.patient_id,
            doctor_id=req.doctor_id,
            new_medicine=req.new_medicine,
            new_dosage=req.new_dosage,
            disease=req.disease
        )
    except Exception as e:
        from fastapi import HTTPException
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/duplicate-check", summary="Duplicate medicine detection")
async def duplicate_check(req: DuplicateRequest):
    result = ai_service.detect_duplicate(req.patient_id, req.new_medicine, req.new_dosage)
    # Enrich with blockchain visit history when duplicate detected
    is_duplicate = result.get("is_duplicate", False)
    visits = []
    if is_duplicate:
        bm = ledger_service.get_blockchain_manager()
        if bm:
            patient_name = req.patient_id.replace("_", " ").rsplit(" ", 1)[0]
            visits = bm.get_visit_history(patient_name)
    result["alert_doctor_2"] = is_duplicate
    result["previous_visits"] = visits[:5]
    return result


@router.post("/interaction-check", summary="Drug interaction check (Multi-Agent AI)")
async def interaction_check(req: InteractionRequest):
    return await ai_service.check_interactions(req.patient_id, req.new_medicine, req.new_dosage)


@router.post("/allergy-check", summary="Allergy conflict check")
async def allergy_check(req: AllergyRequest):
    return await ai_service.check_allergy(req.patient_id, req.new_medicine)


@router.post("/recommendations", summary="AI medicine recommendations")
async def recommend_alternatives(req: RecommendationRequest):
    return await ai_service.recommend_alternatives(req.patient_id, req.disease, req.current_medicine)
