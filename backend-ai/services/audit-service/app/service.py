"""
Audit Service — Business Logic
Self-contained: wraps the Multi-Agent AI system from app.ai.
"""
import logging
from datetime import datetime
from app.config import logger
from app.db import patients_col, prescriptions_col
from app.schemas.patient import PatientContext
from app.ai.services.ai_service import AIService

# Instantiate multi-agent AI service
_new_ai_service = AIService()


async def run_audit(patient_id: str, doctor_id: str, new_medicine: str, new_dosage: str, disease: str | None) -> dict:
    logger.info(f"Audit Service: patient={patient_id} med={new_medicine} dosage={new_dosage}")

    allergies = []
    current_meds = []

    try:
        # Find patient record to build context
        patient_doc = patients_col().find_one({"name": patient_id})
        if not patient_doc:
            patient_doc = patients_col().find_one({"email": patient_id})

        if patient_doc:
            allergies = patient_doc.get("allergies", [])

        # Fetch active prescriptions to extract current meds
        active_rxs = prescriptions_col().find({"patientName": patient_id, "isDispensed": False})
        for rx in active_rxs:
            for med in rx.get("medicines", []):
                name = med.get("name")
                if name:
                    current_meds.append(name)
    except Exception as e:
        logger.error(f"Error querying patient info for AI context: {e}")

    # Build patient context
    context = PatientContext(
        patient_id=patient_id,
        age=35,  # Fallback age
        gender="Male",  # Fallback gender
        allergies=allergies,
        diseases=[disease] if disease else [],
        current_medications=list(set(current_meds)),
        new_prescription=[new_medicine]
    )

    # Execute safety checks
    analysis = await _new_ai_service.analyze_prescription(context)

    # Format output dictionary compatible with doctor console
    allergy_triggered = len(analysis.detected_allergy_risks) > 0
    allergy_severity = "HIGH" if allergy_triggered else "LOW"

    interaction_triggered = len(analysis.detected_drug_interactions) > 0
    interaction_risk = "HIGH" if interaction_triggered else "LOW"
    interaction_details = "; ".join([i.description for i in analysis.detected_drug_interactions]) if interaction_triggered else ""

    # Simulated duplicate logic (as legacy is removed)
    is_duplicate = False
    dup_details = ""
    for med in current_meds:
        if med.lower().split()[0] == new_medicine.lower().split()[0]:
            is_duplicate = True
            dup_details = f"Patient is already taking {med}. Potential therapeutic duplication."
            break

    result = {
        "analysis_id": str(analysis.analysis_id),
        "risk_level": analysis.risk_level,
        "confidence_score": analysis.confidence_score,
        "clinical_explanation": analysis.clinical_explanation,
        "recommended_action": analysis.recommended_action,
        "duplicate_check": {
            "is_duplicate": is_duplicate,
            "duplicate_details": dup_details
        },
        "allergy_check": {
            "allergy_conflict": allergy_triggered,
            "severity": allergy_severity,
            "suggested_alternatives": analysis.suggested_alternative_medicines
        },
        "interaction_check": {
            "interaction_risk": interaction_risk,
            "interaction_details": interaction_details,
            "alternatives": analysis.suggested_alternative_medicines
        },
        "pattern_analysis": {
            "pattern_type": "NORMAL",
            "recommendation": ""
        }
    }
    return result


async def check_interactions(patient_id: str, new_medicine: str, new_dosage: str) -> dict:
    context = PatientContext(
        patient_id=patient_id,
        age=35,
        gender="Male",
        new_prescription=[new_medicine]
    )
    res = await _new_ai_service.interaction_agent.analyze(context)
    return res


async def check_allergy(patient_id: str, new_medicine: str) -> dict:
    context = PatientContext(
        patient_id=patient_id,
        age=35,
        gender="Male",
        new_prescription=[new_medicine]
    )
    res = await _new_ai_service.allergy_agent.analyze(context)
    return res


async def recommend_alternatives(patient_id: str, disease: str, current_medicine: str) -> dict:
    context = PatientContext(
        patient_id=patient_id,
        age=35,
        gender="Male",
        diseases=[disease],
        current_medications=[current_medicine],
        new_prescription=[]
    )
    res = await _new_ai_service.recommendation_agent.analyze(context)
    return res
