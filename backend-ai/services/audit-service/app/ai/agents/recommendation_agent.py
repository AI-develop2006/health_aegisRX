import logging
from typing import Dict, Any, List
from app.schemas.patient import PatientContext
from app.ai.agents.base_agent import BaseAgent

logger = logging.getLogger("AegisRx.RecommendationAgent")


class RecommendationAgent(BaseAgent):
    async def analyze(self, patient: PatientContext) -> Dict[str, Any]:
        # This agent does not perform direct checks on patient itself; 
        # instead it operates as an aggregator. We override the abstract method
        # but the primary orchestration is done in ai_service.py or below.
        return {}

    def compile_clinical_overrides(
        self,
        interaction_results: Dict[str, Any],
        allergy_results: Dict[str, Any],
        disease_results: Dict[str, Any],
        dosage_results: Dict[str, Any],
        doctor_results: Dict[str, Any] = None
    ) -> Dict[str, Any]:
        """
        Synthesizes intermediate agent results to derive a deterministic clinical safety decision.
        Acts as a fail-safe override to guarantee clinical standards are upheld.
        """
        if doctor_results is None:
            doctor_results = {"complications": [], "severity": "LOW", "has_issues": False}

        has_high_risk = (
            dosage_results.get("has_high_risk", False) or
            any(item["severity"] == "MAJOR" for item in interaction_results.get("drug_interactions", [])) or
            len(allergy_results.get("allergy_conflicts", [])) > 0 or
            len(disease_results.get("disease_contraindications", [])) > 0 or
            doctor_results.get("severity") in ("HIGH", "CRITICAL")
        )

        has_warnings = (
            dosage_results.get("has_issues", False) or
            interaction_results.get("has_issues", False) or
            allergy_results.get("has_issues", False) or
            disease_results.get("has_issues", False) or
            doctor_results.get("has_issues", False)
        )

        # Determine clinical risk level
        if has_high_risk:
            risk_level = "HIGH_RISK"
        elif has_warnings:
            risk_level = "WARNING"
        else:
            risk_level = "SAFE"

        # Map risk level to recommended action
        recommended_action = "SAFE_TO_DISPENSE"
        
        # Life-threatening checks for CONTACT_DOCTOR_IMMEDIATELY
        has_critical_pregnancy_risk = any(
            w["type"] == "PREGNANCY_RISK" and w["severity"] == "HIGH_RISK"
            for w in dosage_results.get("dosage_and_demographic_warnings", [])
        )
        
        if has_high_risk:
            if has_critical_pregnancy_risk:
                recommended_action = "CONTACT_DOCTOR_IMMEDIATELY"
            else:
                recommended_action = "DO_NOT_DISPENSE"
        elif has_warnings:
            recommended_action = "DOCTOR_REVIEW"

        # Generate alternatives list based on drug conflicts
        alternatives = self.suggest_alternatives(
            interaction_results, allergy_results, disease_results, dosage_results
        )

        # Collect high-level reasons
        reasons = []
        for dupe in interaction_results.get("duplicate_detections", []):
            reasons.append(dupe["reason"])
        for inter in interaction_results.get("drug_interactions", []):
            reasons.append(f"Drug Interaction ({inter['severity']}): between {', '.join(inter['drugs'])}.")
        for allergy in allergy_results.get("allergy_conflicts", []):
            reasons.append(f"Allergy conflict: {allergy['description']}")
        for contra in disease_results.get("disease_contraindications", []):
            reasons.append(f"Contraindication: {contra['description']}")
        for warning in dosage_results.get("dosage_and_demographic_warnings", []):
            reasons.append(f"Dosing Alert ({warning['type']}): {warning['description']}")
        for comp in doctor_results.get("complications", []):
            reasons.append(f"Clinical Chart Warning: {comp}")

        if not reasons:
            reasons.append("No clinical contraindications, drug-drug interactions, or safety warnings detected.")

        return {
            "risk_level": risk_level,
            "recommended_action": recommended_action,
            "suggested_alternative_medicines": alternatives,
            "reasons": reasons,
            "confidence_score": 0.98 if has_high_risk or has_warnings else 0.95
        }

    def suggest_alternatives(
        self,
        interaction_results: Dict[str, Any],
        allergy_results: Dict[str, Any],
        disease_results: Dict[str, Any],
        dosage_results: Dict[str, Any]
    ) -> List[str]:
        """Suggests clinical alternatives based on detected conflicts."""
        conflicting_drugs = set()
        alternatives = []

        # Find which drugs caused issues
        for dupe in interaction_results.get("duplicate_detections", []):
            conflicting_drugs.add(dupe["drug"].lower())
        for inter in interaction_results.get("drug_interactions", []):
            for d in inter["drugs"]:
                conflicting_drugs.add(d.lower())
        for allergy in allergy_results.get("allergy_conflicts", []):
            conflicting_drugs.add(allergy["drug"].lower())
        for contra in disease_results.get("disease_contraindications", []):
            conflicting_drugs.add(contra["drug"].lower())
        for warning in dosage_results.get("dosage_and_demographic_warnings", []):
            conflicting_drugs.add(warning["drug"].lower())

        # Alternative drug mapping
        for drug in conflicting_drugs:
            if "ibuprofen" in drug or "aspirin" in drug:
                # If NSAID has issues, suggest acetaminophen for general pain
                alternatives.append("Acetaminophen")
            elif "amoxicillin" in drug or "penicillin" in drug:
                # If penicillin allergy, suggest macrolides
                alternatives.append("Azithromycin")
                alternatives.append("Clarithromycin")
            elif "warfarin" in drug:
                # If warfarin is contraindicated (e.g. pregnancy), suggest LMWH
                alternatives.append("Low Molecular Weight Heparin (LMWH)")
            elif "metformin" in drug:
                # If metformin has issues (e.g. CKD), suggest insulin or SGLT2 inhibitors
                alternatives.append("Insulin")
                alternatives.append("Empagliflozin")

        # De-duplicate
        # De-duplicate
        return list(set(alternatives))

import asyncio
from pydantic import BaseModel
from app.ai.agents.base_agent import AgentResult

class RecommendationResult(BaseModel):
    summary: str
    alternatives: List[str] = []

async def run_recommendation_agent(context: PatientContext, agents_results: List[AgentResult]) -> RecommendationResult:
    # Deterministic alternative drug selector
    from app.ai.knowledge.rxnorm import RxNormMock
    from app.ai.knowledge.drugbank import DrugBankMock
    from app.ai.knowledge.dailymed import DailyMedMock
    from app.ai.knowledge.openfda import OpenFDAMock
    from app.ai.knowledge.snomed import SNOMEDMock
    
    rxnorm = RxNormMock()
    drugbank = DrugBankMock()
    dailymed = DailyMedMock()
    openfda = OpenFDAMock()
    snomed = SNOMEDMock()
    
    agent_inst = RecommendationAgent(rxnorm, drugbank, dailymed, openfda, snomed)
    
    interaction_res = {"duplicate_detections": [], "drug_interactions": [], "has_issues": False}
    allergy_res = {"allergy_conflicts": [], "has_issues": False}
    disease_res = {"disease_contraindications": [], "has_issues": False}
    dosage_res = {"dosage_and_demographic_warnings": [], "has_high_risk": False, "has_issues": False}
    doctor_res = {"complications": [], "severity": "LOW", "has_issues": False}
    
    for r in agents_results:
        if r.name == "interaction":
            interaction_res = r.meta
        elif r.name == "allergy":
            allergy_res = r.meta
        elif r.name == "disease":
            disease_res = r.meta
        elif r.name == "dosage":
            dosage_res = r.meta
        elif r.name == "doctor":
            doctor_res = r.meta
            
    alternatives = agent_inst.suggest_alternatives(
        interaction_res, allergy_res, disease_res, dosage_res
    )
    fallback_summary = "Evaluated safe by clinical rules."
    if len(alternatives) > 0 or len(interaction_res.get("drug_interactions", [])) > 0 or len(allergy_res.get("allergy_conflicts", [])) > 0:
        fallback_summary = "Deterministic safety checks identified potential risks."

    return RecommendationResult(summary=fallback_summary, alternatives=alternatives)
