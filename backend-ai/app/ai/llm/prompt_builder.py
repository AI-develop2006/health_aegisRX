from typing import Dict, Any, List
import json
from app.schemas.patient import PatientContext

class PromptBuilder:
    @staticmethod
    def build_system_prompt() -> str:
        """
        Generates the system prompt establishing the expert persona,
        clinical parameters, and safety guidelines.
        """
        return (
            "You are a Board-Certified Clinical Pharmacist and AI Clinical Decision Support System (CDSS) agent.\n"
            "Your duty is to analyze new prescriptions against a patient's medical history to determine safety.\n\n"
            "You MUST perform the following critical safety checks:\n"
            "1. Duplicate Medicines: Verify if any drug in the new prescription is already being taken.\n"
            "2. Drug-Drug Interactions: Assess risk of interactions with active medications.\n"
            "3. Allergy Conflicts: Identify conflicts between new drugs (or chemical classes) and patient allergies.\n"
            "4. Disease Contraindications: Cross-examine new prescriptions with patient medical conditions (especially kidney, liver, cardiovascular disease).\n"
            "5. Demographic Risks: Consider age-related (pediatric/geriatric Beers Criteria) and weight-based safety guidelines.\n"
            "6. Pregnancy Risks: Evaluate pregnancy status and warning categories if applicable.\n\n"
            "You must suggest safer alternative medicines if warnings or high risks are identified.\n"
            "Provide clinical explanations summarizing the pathophysiological rationale for warnings.\n\n"
            "OUTPUT FORMAT INSTRUCTIONS:\n"
            "You MUST respond ONLY with a single valid JSON object. Do not include markdown wraps (like ```json) or explanation outside the JSON.\n"
            "The JSON structure must match this schema:\n"
            "{\n"
            '  "risk_level": "SAFE" | "WARNING" | "HIGH_RISK",\n'
            '  "confidence_score": float (between 0.0 and 1.0),\n'
            '  "reasons": ["string description of each key finding", ...],\n'
            '  "detected_drug_interactions": [\n'
            "    {\n"
            '      "severity": "MAJOR" | "MODERATE" | "MINOR",\n'
            '      "drugs": ["DrugA", "DrugB"],\n'
            '      "description": "Interaction detail"\n'
            "    }\n"
            "  ],\n"
            '  "detected_allergy_risks": [\n'
            "    {\n"
            '      "allergy": "AllergyName",\n'
            '      "drug": "PrescribedDrug",\n'
            '      "description": "Conflict detail"\n'
            "    }\n"
            "  ],\n"
            '  "disease_contraindications": [\n'
            "    {\n"
            '      "disease": "DiseaseName",\n'
            '      "drug": "ContraindicatedDrug",\n'
            '      "description": "Contraindication detail"\n'
            "    }\n"
            "  ],\n"
            '  "suggested_alternative_medicines": ["AlternativeDrugName", ...],\n'
            '  "clinical_explanation": "Detailed clinical reasoning summary",\n'
            '  "recommended_action": "SAFE_TO_DISPENSE" | "DOCTOR_REVIEW" | "DO_NOT_DISPENSE" | "CONTACT_DOCTOR_IMMEDIATELY"\n'
            "}"
        )

    @staticmethod
    def build_user_prompt(
        patient: PatientContext,
        agent_assertions: Dict[str, Any],
        knowledge_facts: List[str]
    ) -> str:
        """
        Assembles patient context data, facts gathered from external clinical mocks,
        and intermediate results from clinical agents into a formatted prompt.
        """
        # Build patient profile representation
        patient_data = {
            "patient_id": patient.patient_id,
            "age": patient.age,
            "gender": patient.gender,
            "weight_kg": patient.weight,
            "is_pregnant": patient.is_pregnant,
            "allergies": patient.allergies,
            "active_diseases": patient.diseases,
            "current_medications": patient.current_medications,
            "previous_prescriptions_history": patient.previous_prescriptions,
            "new_prescription_to_evaluate": patient.new_prescription
        }

        # Format clinical inputs
        assertions_str = json.dumps(agent_assertions, indent=2)
        facts_str = "\n".join([f"- {fact}" for fact in knowledge_facts])

        return (
            "--- PATIENT CLINICAL PROFILE ---\n"
            f"{json.dumps(patient_data, indent=2)}\n\n"
            "--- CLINICAL AGENT RULE FINDINGS (FOR IN-CONTEXT GUIDANCE) ---\n"
            f"{assertions_str}\n\n"
            "--- CLINICAL KNOWLEDGE FACT RETRIEVALS ---\n"
            f"{facts_str if knowledge_facts else '- No specific knowledge base facts retrieved.'}\n\n"
            "--- YOUR TASK ---\n"
            "Perform clinical reasoning on the patient profile using the rule findings and knowledge facts provided.\n"
            "Evaluate if the new prescription is safe for this patient. Ensure you check duplicate medicines, drug interactions, allergy risks, disease contraindications, age/weight/pregnancy warnings.\n"
            "Synthesize the final risk level, clinical explanation, alternative drug recommendations, and recommended action.\n"
            "Generate and return the response in the specified JSON format."
        )
