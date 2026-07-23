"""
Audit Service — Business Logic
Self-contained: wraps the Multi-Agent AI system from app.ai.
"""
import logging
from datetime import datetime
from app.config import logger
from app.db import patients_col, prescriptions_col, allergies_col
from app.schemas.patient import PatientContext
from app.ai.services.ai_service import AIService

# Instantiate multi-agent AI service
_new_ai_service = AIService()


async def run_audit(patient_id: str, doctor_id: str, new_medicine: str, new_dosage: str, disease: str | None) -> dict:
    logger.info(f"Audit Service: patient={patient_id} med={new_medicine} dosage={new_dosage}")

    allergies = []
    current_meds = []

    try:
        import re
        clean_id = patient_id.replace("_", " ").strip()
        escaped_id = re.escape(clean_id).replace(r"\ ", r"[\ _]")
        regex_pattern = f"^{escaped_id}$"
        
        patient_doc = patients_col().find_one({"patient_id": {"$regex": regex_pattern, "$options": "i"}})
        if not patient_doc:
            patient_doc = patients_col().find_one({"name": {"$regex": regex_pattern, "$options": "i"}})
        if not patient_doc:
            patient_doc = patients_col().find_one({"email": {"$regex": f"^{re.escape(patient_id)}$", "$options": "i"}})

        if patient_doc:
            p_id = patient_doc.get("patient_id")
            p_name = patient_doc.get("name")
            
            # Fetch from allergies collection
            search_terms = []
            if p_id:
                search_terms.append(p_id)
                search_terms.append(p_id.replace("_", " "))
                search_terms.append(p_id.replace(" ", "_"))
            if p_name:
                search_terms.append(p_name)
                search_terms.append(p_name.replace("_", " "))
                search_terms.append(p_name.replace(" ", "_"))
            
            import re
            allergy_filters = []
            for term in list(set(search_terms)):
                safe_term = re.escape(term)
                allergy_filters.append({"patient_id": {"$regex": f"^({safe_term})$", "$options": "i"}})
                allergy_filters.append({"patient_name": {"$regex": f"^({safe_term})$", "$options": "i"}})
                
            if allergy_filters:
                cursor = allergies_col().find({"$or": allergy_filters})
                allergies = [doc.get("allergy_name") for doc in cursor if doc.get("allergy_name")]
                
            # Also fallback to doc fields
            patient_allergies_field = patient_doc.get("allergies", [])
            if patient_allergies_field:
                allergies.extend(patient_allergies_field)
                
            allergies = list(set(allergies))


        # Fetch active prescriptions to extract current meds
        active_rxs = prescriptions_col().find({"patientName": patient_id, "isDispensed": False})
        from datetime import datetime
        from app.ai.services.patient_context import parse_duration_days
        now = datetime.now()
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
                name = med.get("name")
                if name:
                    is_active = True
                    if rx_date and isinstance(rx_date, datetime):
                        diff_days = abs((now - rx_date).days)
                        dur_str = med.get("duration", "30 days")
                        dur_days = parse_duration_days(dur_str)
                        if diff_days > dur_days:
                            is_active = False
                    
                    if is_active:
                        current_meds.append(name)
        # Fetch ALL prescriptions written by doctors for this patient (database history)
        all_rxs_cursor = prescriptions_col().find({"patientName": patient_id})
        all_prescriptions = []
        for rx in all_rxs_cursor:
            rx_clean = rx.copy()
            if "_id" in rx_clean:
                rx_clean["_id"] = str(rx_clean["_id"])
            if "date" in rx_clean:
                if isinstance(rx_clean["date"], datetime):
                    rx_clean["date"] = rx_clean["date"].isoformat()
                else:
                    rx_clean["date"] = str(rx_clean["date"])
            all_prescriptions.append(rx_clean)
    except Exception as e:
        logger.error(f"Error querying patient info for AI context: {e}")
        all_prescriptions = []

    # Build patient context
    context = PatientContext(
        patient_id=patient_id,
        age=35,  # Fallback age
        gender="Male",  # Fallback gender
        allergies=allergies,
        diseases=[disease] if disease else [],
        current_medications=list(set(current_meds)),
        new_prescription=[new_medicine],
        all_prescriptions=all_prescriptions,
        doctor_id=doctor_id
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
