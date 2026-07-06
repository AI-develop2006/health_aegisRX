"""
AI Service — wraps the Multi-Agent AI system from app/ai and legacy AIAgent.
"""
from datetime import datetime
from app.config import logger, TEST_DOCTOR_PRIVATE_KEY
from app.db.mongodb import get_connector
from app.schemas.patient import PatientContext
from app.ai.services.ai_service import AIService as NewAIService

# Instantiate the new multi-agent AI service
_new_ai_service = NewAIService()

# ============================================
# LEGACY AI AGENT SINGLETON (For Z-score & Local Rules)
# ============================================
_ai_agent = None  # Set during app lifespan startup

def get_ai_agent():
    return _ai_agent

def set_ai_agent(agent):
    global _ai_agent
    _ai_agent = agent

# ============================================
# AUDIT BRIDGE
# ============================================
async def run_audit(patient_id: str, doctor_id: str, new_medicine: str, new_dosage: str, disease: str | None) -> dict:
    """
    Run safety analysis using the new multi-agent Gemini/GPT client,
    and returns a structured dict compatible with the doctor console.
    """
    logger.info(f"Multi-Agent AI Audit: patient={patient_id} med={new_medicine} dosage={new_dosage}")
    
    # 1. Fetch patient data from MongoDB to construct full context
    db = get_connector()
    allergies = []
    current_meds = []
    
    if db is not None:
        try:
            # Query patient allergies
            patient_doc = db.db["patients"].find_one({"name": patient_id})
            if not patient_doc:
                patient_doc = db.db["patients"].find_one({"email": patient_id})
            
            if patient_doc:
                allergies = patient_doc.get("allergies", [])
            
            # Query patient active prescriptions to extract current meds
            prescriptions_col = db.get_prescriptions_collection()
            active_rxs = prescriptions_col.find({"patientName": patient_id, "isDispensed": False})
            for rx in active_rxs:
                for med in rx.get("medicines", []):
                    med_name = med.get("name")
                    if med_name:
                        current_meds.append(med_name)
        except Exception as e:
            logger.error(f"Error querying patient info for AI context: {e}")

    # 2. Build PatientContext object
    context = PatientContext(
        patient_id=patient_id,
        age=35,  # Fallback age
        gender="Male",  # Fallback gender
        allergies=allergies,
        diseases=[disease] if disease else [],
        current_medications=list(set(current_meds)),
        new_prescription=[new_medicine]
    )

    # 3. Execute new Multi-Agent safety checks
    analysis = await _new_ai_service.analyze_prescription(context)
    
    # 4. Local Z-Score anomaly pattern fallback
    pattern_type = "NORMAL"
    pattern_rec = ""
    agent = get_ai_agent()
    if agent:
        try:
            local_pattern = agent.analyze_prescription_pattern(doctor_id)
            pattern_type = local_pattern.get("prescription_pattern", {}).get("pattern_type", "NORMAL")
            pattern_rec = local_pattern.get("prescription_pattern", {}).get("recommendation", "")
        except Exception:
            pass

    # 5. Format return dictionary to match doctor console schemas
    duplicate_flag = False
    duplicate_details = ""
    if agent:
        try:
            local_dup = agent.detect_duplicate_medicine(patient_id, new_medicine, new_dosage)
            duplicate_flag = local_dup.get("duplicate_detection", {}).get("is_duplicate", False)
            duplicate_details = local_dup.get("duplicate_detection", {}).get("duplicate_details", "")
        except Exception:
            pass

    # Format allergy response
    allergy_triggered = len(analysis.detected_allergy_risks) > 0
    allergy_severity = "HIGH" if allergy_triggered else "LOW"
    
    # Format drug interactions
    interaction_triggered = len(analysis.detected_drug_interactions) > 0
    interaction_risk = "HIGH" if interaction_triggered else "LOW"
    interaction_details = "; ".join([i.description for i in analysis.detected_drug_interactions]) if interaction_triggered else ""

    result = {
        "analysis_id": str(analysis.analysis_id),
        "risk_level": analysis.risk_level,
        "confidence_score": analysis.confidence_score,
        "clinical_explanation": analysis.clinical_explanation,
        "recommended_action": analysis.recommended_action,
        "duplicate_check": {
            "is_duplicate": duplicate_flag,
            "duplicate_details": duplicate_details
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
            "pattern_type": pattern_type,
            "recommendation": pattern_rec
        }
    }
    return result

# ============================================
# INDIVIDUAL AI CHECKS
# ============================================
def detect_duplicate(patient_id: str, new_medicine: str, new_dosage: str) -> dict:
    agent = get_ai_agent()
    if not agent:
        return {"duplicate_detection": {"is_duplicate": False, "duplicate_details": ""}}
    return agent.detect_duplicate_medicine(patient_id, new_medicine, new_dosage)

async def check_interactions(patient_id: str, new_medicine: str, new_dosage: str) -> dict:
    # Compile a standard PatientContext
    context = PatientContext(
        patient_id=patient_id,
        age=35,
        gender="Male",
        new_prescription=[new_medicine]
    )
    res = await _new_ai_service.interaction_agent.analyze(context)
    return res

async def check_allergy(patient_id: str, new_medicine: str) -> dict:
    # Compile a standard PatientContext
    context = PatientContext(
        patient_id=patient_id,
        age=35,
        gender="Male",
        new_prescription=[new_medicine]
    )
    res = await _new_ai_service.allergy_agent.analyze(context)
    return res

async def recommend_alternatives(patient_id: str, disease: str, current_medicine: str) -> dict:
    # Compile a standard PatientContext
    context = PatientContext(
        patient_id=patient_id,
        age=35,
        gender="Male",
        diseases=[disease] if disease else [],
        current_medications=[current_medicine],
        new_prescription=["Alternative"]
    )
    res = await _new_ai_service.recommendation_agent.analyze(context)
    return res

def pattern_analysis(doctor_id: str) -> dict:
    agent = get_ai_agent()
    if not agent:
        return {"prescription_pattern": {"pattern_type": "NORMAL", "recommendation": ""}}
    return agent.analyze_prescription_pattern(doctor_id)
