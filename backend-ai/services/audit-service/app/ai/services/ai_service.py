import asyncio
import logging
import time
import json
import httpx
import hashlib
from uuid import uuid4, UUID
from typing import Dict, Any, List, Optional
from datetime import datetime

from app.core.config import settings
from app.schemas.patient import PatientContext
from app.schemas.response import (
    PrescriptionSafetyAnalysis, 
    AuditLogEntry, 
    DrugInteractionDetail, 
    AllergyRiskDetail, 
    DiseaseContraindicationDetail,
    AuditResponse
)
from app.ai.knowledge import (
    RxNormMock, 
    DrugBankMock, 
    DailyMedMock, 
    OpenFDAMock, 
    SNOMEDMock
)
from app.ai.agents import (
    InteractionAgent, 
    AllergyAgent, 
    DiseaseAgent, 
    DosageAgent, 
    RecommendationAgent
)
from app.ai.agents.base_agent import AgentResult
from app.ai.agents.allergy_agent import run_allergy_agent
from app.ai.agents.disease_agent import run_disease_agent
from app.ai.agents.dosage_agent import run_dosage_agent
from app.ai.agents.interaction_agent import run_interaction_agent
from app.ai.agents.doctor_agent import run_doctor_agent, DoctorAgent
from app.ai.services.patient_context import PatientContextService, build_patient_context

logger = logging.getLogger("AegisRx.AIService")

# In-memory audit database
audit_store: Dict[str, AuditLogEntry] = {}

class AIService:
    def __init__(self):
        # Initialize Medical Knowledge Layer
        self.rxnorm = RxNormMock()
        self.drugbank = DrugBankMock()
        self.dailymed = DailyMedMock()
        self.openfda = OpenFDAMock()
        self.snomed = SNOMEDMock()

        # Initialize Safety Agents
        self.interaction_agent = InteractionAgent(self.rxnorm, self.drugbank, self.dailymed, self.openfda, self.snomed)
        self.allergy_agent = AllergyAgent(self.rxnorm, self.drugbank, self.dailymed, self.openfda, self.snomed)
        self.disease_agent = DiseaseAgent(self.rxnorm, self.drugbank, self.dailymed, self.openfda, self.snomed)
        self.dosage_agent = DosageAgent(self.rxnorm, self.drugbank, self.dailymed, self.openfda, self.snomed)
        self.doctor_agent = DoctorAgent(self.rxnorm, self.drugbank, self.dailymed, self.openfda, self.snomed)
        self.recommendation_agent = RecommendationAgent(self.rxnorm, self.drugbank, self.dailymed, self.openfda, self.snomed)

    async def analyze_prescription(self, patient: PatientContext) -> PrescriptionSafetyAnalysis:
        start_time = time.time()
        analysis_id = uuid4()
        logger.info(f"Starting safety analysis run {analysis_id} for Patient {patient.patient_id}")

        # Step 1: Preprocess patient context
        cleaned_patient = PatientContextService.preprocess_context(patient)

        # Step 2: Run safety rule sub-agents in parallel (deterministic CDSS)
        logger.info("Executing clinical safety agents in parallel...")
        interaction_task = self.interaction_agent.analyze(cleaned_patient)
        allergy_task = self.allergy_agent.analyze(cleaned_patient)
        disease_task = self.disease_agent.analyze(cleaned_patient)
        dosage_task = self.dosage_agent.analyze(cleaned_patient)
        doctor_task = self.doctor_agent.analyze(cleaned_patient)

        agent_results = await asyncio.gather(
            interaction_task,
            allergy_task,
            disease_task,
            dosage_task,
            doctor_task
        )

        interaction_res, allergy_res, disease_res, dosage_res, doctor_res = agent_results
        logger.info("Clinical agents successfully finished execution.")

        # Step 3: Compile rule-based safety overrides (Ground-truth safety outcomes)
        clinical_overrides = self.recommendation_agent.compile_clinical_overrides(
            interaction_res, allergy_res, disease_res, dosage_res, doctor_res
        )

        # Determine immutable risk score, level, and recommended action based on deterministic check
        risk_level = clinical_overrides["risk_level"]
        recommended_action = clinical_overrides["recommended_action"]
        reasons = clinical_overrides["reasons"]
        
        risk_band = "LOW" if risk_level == "SAFE" else "MEDIUM" if risk_level == "WARNING" else "CRITICAL"
        risk_score = 10 if risk_band == "LOW" else 60 if risk_band == "MEDIUM" else 95

        # Format lists compatibility schemas
        interactions_list = [
            DrugInteractionDetail(**i) for i in interaction_res.get("drug_interactions", [])
        ]
        allergies_list = [
            AllergyRiskDetail(**a) for a in allergy_res.get("allergy_conflicts", [])
        ]
        diseases_list = [
            DiseaseContraindicationDetail(**d) for d in disease_res.get("disease_contraindications", [])
        ]

        # Step 4: Call external standalone AI explanation service (zero-trust pattern)
        ai_service_url = getattr(settings, "AI_SERVICE_URL", "http://localhost:4008")
        logger.info(f"Submitting audit outcomes to decoupled AI explanation service: {ai_service_url}")

        ai_payload = {
            "risk_score": risk_score,
            "risk_level": risk_level,
            "triggered_rules": reasons,
            "recommended_action": recommended_action,
            "patient_age": cleaned_patient.age or 35,
            "patient_gender": cleaned_patient.gender or "Male",
            "patient_allergies": cleaned_patient.allergies,
            "patient_diseases": cleaned_patient.diseases,
            "current_medicines": cleaned_patient.current_medications,
            "new_prescription_medicines": cleaned_patient.new_prescription
        }

        clinical_explanation = ""
        patient_friendly_summary = ""
        suggested_alternatives = clinical_overrides["suggested_alternative_medicines"]
        medication_education = ""
        backend_mode = "real"
        backend_reason = None

        try:
            async with httpx.AsyncClient(timeout=15.0) as client:
                res = await client.post(f"{ai_service_url}/api/ai/explain", json=ai_payload)
                if res.status_code == 200:
                    ai_data = res.json()
                    clinical_explanation = ai_data.get("clinical_explanation", "")
                    patient_friendly_summary = ai_data.get("patient_friendly_summary", "")
                    medication_education = ai_data.get("medication_education", "")
                    backend_mode = ai_data.get("mode", "real")
                    backend_reason = ai_data.get("fallback_reason")
                    
                    # Merge alternatives from LLM if any
                    llm_alts = ai_data.get("suggested_alternatives", [])
                    for alt in llm_alts:
                        if alt not in suggested_alternatives:
                            suggested_alternatives.append(alt)
                else:
                    logger.warning(f"AI Service returned error status {res.status_code}. Using failsafe fallback.")
                    raise RuntimeError(f"AI Service HTTP status {res.status_code}")
        except Exception as e:
            logger.error(f"Failed to fetch explanation from AI service: {e}. Utilizing rules engine fallback.")
            backend_mode = "failsafe"
            backend_reason = str(e)
            clinical_explanation = (
                "Failsafe Mode active (AI service unavailable). Reasoning generated via the clinical rule engine. "
                f"Detected conflicts present: {', '.join(reasons)}."
            ) if risk_level != "SAFE" else "Failsafe Mode active (AI service unavailable). No safety rules violated."
            patient_friendly_summary = "This prescription combination has been flagged as high risk. Please review with your doctor."
            medication_education = "Report any adverse events to your doctor immediately."

        # Scan list items to dynamically compile flagged_medicines
        flagged = set()
        for item in interactions_list:
            flagged.update(item.drugs)
            if not item.reason:
                item.reason = f"{item.drugs[0]} + {item.drugs[1]} – interaction risk ({item.severity})"
        for item in allergies_list:
            flagged.add(item.drug)
            if not item.reason:
                item.reason = f"{item.drug} – allergy risk ({item.allergy})"
        for item in diseases_list:
            flagged.add(item.drug)
            if not item.reason:
                item.reason = f"{item.drug} – contraindicated in {item.disease}"

        # Construct safe output structure
        parsed_llm_analysis = PrescriptionSafetyAnalysis(
            analysis_id=analysis_id,
            risk_level=risk_level,
            confidence_score=0.98 if risk_level in ("HIGH_RISK", "WARNING") else 0.95,
            reasons=reasons,
            detected_drug_interactions=interactions_list,
            detected_allergy_risks=allergies_list,
            disease_contraindications=diseases_list,
            suggested_alternative_medicines=suggested_alternatives,
            clinical_explanation=clinical_explanation,
            recommended_action=recommended_action,
            metadata={"provider": "rules_engine", "fallback_mode": (backend_mode == "failsafe")},
            backend_mode=backend_mode,
            backend_reason=backend_reason
        )

        parsed_llm_analysis.risk_band = risk_band
        parsed_llm_analysis.risk_score = risk_score
        parsed_llm_analysis.recommendation = clinical_explanation[:120] if clinical_explanation else "Evaluated safe by clinical rules."
        parsed_llm_analysis.flagged_medicines = list(flagged)

        # Compute latency
        latency_ms = (time.time() - start_time) * 1000
        parsed_llm_analysis.metadata["latency_ms"] = latency_ms

        # Save to local Audit Log database
        audit_entry = AuditLogEntry(
            analysis_id=analysis_id,
            timestamp=datetime.utcnow().isoformat() + "Z",
            patient_context=patient.model_dump(),
            analysis_result=parsed_llm_analysis,
            raw_prompt_system="decoupled",
            raw_prompt_user="decoupled",
            raw_llm_response=json.dumps(ai_payload),
            latency_ms=latency_ms,
            token_usage={"prompt_tokens": 0, "completion_tokens": 0, "total_tokens": 0}
        )
        audit_store[str(analysis_id)] = audit_entry

        return parsed_llm_analysis

    async def _gather_knowledge_facts(self, patient: PatientContext) -> List[str]:
        return []

def combine_results(*agents: AgentResult):
    severities = [a.severity.upper() for a in agents if a.severity]
    if "CRITICAL" in severities:
        risk_band = "CRITICAL"
        risk_score = 99
        override_required = True
    elif "HIGH" in severities:
        risk_band = "HIGH"
        risk_score = 95
        override_required = True
    elif "MEDIUM" in severities:
        risk_band = "MEDIUM"
        risk_score = 60
        override_required = False
    else:
        risk_band = "LOW"
        risk_score = 10
        override_required = False
    return risk_band, risk_score, override_required

def collect_flags(*agents: AgentResult) -> List[Dict[str, Any]]:
    flags = []
    for a in agents:
        for issue in a.issues:
            flags.append({
                "agent": a.name,
                "issue": issue,
                "affected_medicines": a.affected_medicines,
                "meta": a.meta
            })
    return flags

async def run_full_audit(request) -> AuditResponse:
    context = await build_patient_context(request)
    logger.info(f"AegisRx: Initiating full audit. patient_id={context.patient_id} drugs={context.new_prescription}")

    # Run intermediate checks in parallel
    allergy, disease, dosage, interaction, doctor = await asyncio.gather(
        run_allergy_agent(context),
        run_disease_agent(context),
        run_dosage_agent(context),
        run_interaction_agent(context),
        run_doctor_agent(context)
    )

    risk_band, risk_score, _ = combine_results(
        allergy, disease, dosage, interaction, doctor
    )

    # Deterministic mapping according to Clinical Decision Matrix
    action = "ALLOW"
    block_submission = False
    override_required = False

    if risk_score >= 90:
        action = "BLOCK_UNLESS_OVERRIDE"
        block_submission = True
        override_required = True
    elif risk_score >= 70:
        action = "REQUIRE_OVERRIDE"
        block_submission = False
        override_required = True
    elif risk_score >= 30:
        action = "REVIEW"
        block_submission = False
        override_required = False
    else:
        action = "ALLOW"
        block_submission = False
        override_required = False

    # 1. Gather all rule reasons
    reasons = []
    has_allergy_issues = len(allergy.issues) > 0
    for issue in allergy.issues:
        reasons.append(f"Allergy conflict: {issue}")

    has_interaction_issues = len(interaction.issues) > 0
    for issue in interaction.issues:
        reasons.append(f"Drug Interaction: {issue}")

    has_disease_issues = len(disease.issues) > 0
    for issue in disease.issues:
        reasons.append(f"Contraindication: {issue}")

    has_dosage_issues = len(dosage.issues) > 0
    for issue in dosage.issues:
        reasons.append(f"Dosing Alert: {issue}")

    has_doc_issues = len(doctor.issues) > 0
    for issue in doctor.issues:
        reasons.append(f"Clinical Chart Warning: {issue}")

    if not reasons:
        reasons.append("No clinical contraindications, drug-drug interactions, or safety warnings detected.")

    legacy_risk_level = "SAFE" if risk_band == "LOW" else ("WARNING" if risk_band == "MEDIUM" else "CRITICAL")
    recommended_action = action

    # Deterministic alternatives suggestion
    from app.ai.knowledge import RxNormMock, DrugBankMock, DailyMedMock, OpenFDAMock, SNOMEDMock
    rx = RxNormMock()
    db = DrugBankMock()
    dm = DailyMedMock()
    fda = OpenFDAMock()
    sn = SNOMEDMock()
    rec_agent = RecommendationAgent(rx, db, dm, fda, sn)
    suggested_alternatives = rec_agent.suggest_alternatives(
        interaction.meta, allergy.meta, disease.meta, dosage.meta
    )

    # Call Decoupled AI Explanation Service
    ai_service_url = getattr(settings, "AI_SERVICE_URL", "http://localhost:4008")
    logger.info(f"Submitting AuditResponse outcomes to AI explain service: {ai_service_url}")

    ai_payload = {
        "risk_score": risk_score,
        "risk_level": legacy_risk_level if legacy_risk_level != "CRITICAL" else "HIGH_RISK",
        "triggered_rules": reasons,
        "recommended_action": recommended_action,
        "patient_age": context.age or 35,
        "patient_gender": context.gender or "Male",
        "patient_allergies": context.allergies,
        "patient_diseases": context.diseases,
        "current_medicines": context.current_medications,
        "new_prescription_medicines": context.new_prescription
    }

    explanation = ""
    patient_friendly = ""
    med_edu = ""

    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            res = await client.post(f"{ai_service_url}/api/ai/explain", json=ai_payload)
            if res.status_code == 200:
                ai_data = res.json()
                explanation = ai_data.get("clinical_explanation", "")
                patient_friendly = ai_data.get("patient_friendly_summary", "")
                med_edu = ai_data.get("medication_education", "")
                llm_alts = ai_data.get("suggested_alternatives", [])
                for alt in llm_alts:
                    if alt not in suggested_alternatives:
                        suggested_alternatives.append(alt)
            else:
                raise RuntimeError(f"AI Service status {res.status_code}")
    except Exception as e:
        logger.error(f"AuditResponse AI service connection failed: {e}. Activating failsafe explanation.")
        explanation = (
            "Failsafe Mode active (AI service unavailable). Reasoning generated via the clinical rule engine. "
            f"Detected conflicts: {', '.join(reasons)}."
        ) if legacy_risk_level != "SAFE" else "Failsafe Mode active (AI service unavailable). No safety rules violated."
        patient_friendly = "Safety warning: prescription has potential risks. Consult your physician."

    has_dup_issues = len(doctor.issues) > 0 or any("duplicate" in iss.lower() for iss in interaction.issues)
    dup_details = []
    if len(doctor.issues) > 0:
        dup_details.extend(doctor.issues)
    for iss in interaction.issues:
        if "duplicate" in iss.lower():
            dup_details.append(iss)

    response = AuditResponse(
        risk_band=risk_band,
        risk_score=risk_score,
        override_required=override_required,
        flagged_medicines=collect_flags(allergy, disease, dosage, interaction, doctor),
        explanation=explanation,
        alternatives=suggested_alternatives,
        risk_level=legacy_risk_level,
        confidence_score=float(risk_score) / 100.0,
        clinical_explanation=explanation,
        action=action,
        block_submission=block_submission,
        warnings=reasons,
        alternative_medicines=suggested_alternatives,
        recommended_action=recommended_action,
        allergy_check={
            "allergy_conflict": has_allergy_issues,
            "allergy_details": "; ".join(allergy.issues) if has_allergy_issues else "",
            "suggested_alternatives": suggested_alternatives
        },
        interaction_check={
            "interaction_risk": interaction.severity.upper() if has_interaction_issues else "LOW",
            "interaction_details": "; ".join(interaction.issues) if has_interaction_issues else "",
            "alternatives": suggested_alternatives
        },
        duplicate_check={
            "is_duplicate": has_dup_issues,
            "duplicate_details": "; ".join(dup_details) if has_dup_issues else ""
        }
    )

    # Submit audit metadata to Ledger Service (Fabric queueing simulation)
    try:
        response_json = response.model_dump_json()
        audit_hash = hashlib.sha256(response_json.encode("utf-8")).hexdigest()
        
        patient_id_anon = f"anon-patient-{hashlib.sha256(context.patient_id.encode('utf-8')).hexdigest()[:8]}"
        doctor_id_anon = context.doctor_id or "unknown-doc"
        audit_id = str(uuid4())
        
        payload = {
            "audit_id": audit_id,
            "patient_id": patient_id_anon,
            "doctor_id": doctor_id_anon,
            "risk_band": risk_band,
            "decision_type": "rejected" if override_required else "approved",
            "audit_hash": f"SHA256-{audit_hash}",
            "timestamp": datetime.utcnow().isoformat() + "Z"
        }
        
        ledger_url = getattr(settings, "LEDGER_SERVICE_URL", "http://localhost:4007")
        logger.info(f"Posting audit event metadata to Ledger Service: {ledger_url}")
        
        async with httpx.AsyncClient(timeout=2.0) as client:
            res = await client.post(f"{ledger_url}/api/ledger/audit-event", json=payload)
            if res.status_code in (200, 202):
                logger.info(f"Audit event successfully logged on Fabric: {res.json()}")
            else:
                logger.warning(f"Ledger service returned status {res.status_code}: {res.text}")
    except Exception as lex:
        logger.error(f"Failed to log audit event to Hyperledger Fabric: {lex}")

    return response
