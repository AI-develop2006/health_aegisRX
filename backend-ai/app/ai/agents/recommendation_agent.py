from typing import Dict, Any, List
from app.schemas.patient import PatientContext
from app.ai.agents.base_agent import BaseAgent

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
        dosage_results: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Synthesizes intermediate agent results to derive a deterministic clinical safety decision.
        Acts as a fail-safe override to guarantee clinical standards are upheld.
        """
        has_high_risk = (
            dosage_results.get("has_high_risk", False) or
            any(item["severity"] == "MAJOR" for item in interaction_results.get("drug_interactions", [])) or
            len(allergy_results.get("allergy_conflicts", [])) > 0 or
            len(disease_results.get("disease_contraindications", [])) > 0
        )

        has_warnings = (
            dosage_results.get("has_issues", False) or
            interaction_results.get("has_issues", False) or
            allergy_results.get("has_issues", False) or
            disease_results.get("has_issues", False)
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
        return list(set(alternatives))
