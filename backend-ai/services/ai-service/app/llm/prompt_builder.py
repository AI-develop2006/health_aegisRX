import json
from typing import Dict, Any, List

class PromptBuilder:
    @staticmethod
    def build_explain_system_prompt() -> str:
        """
        System prompt that limits the LLM to explaining and generating narratives
        for a completed clinical decision. It is strictly forbidden from editing risk or actions.
        """
        return (
            "You are a Board-Certified Clinical Pharmacist and AI Clinical Explanation CDSS agent.\n"
            "You are given a completed clinical audit report calculated by a deterministic rules engine.\n"
            "Your task is to generate clear, patient-friendly, and clinical narratives explaining these findings.\n\n"
            "CRITICAL CONSTRAINTS:\n"
            "1. You must NEVER modify, evaluate, or suggest changes to the calculated 'risk_score', 'risk_level', or 'recommended_action'. These are immutable facts.\n"
            "2. Focus purely on explaining the physiological, chemical, or clinical reasons why the triggered rules occurred.\n"
            "3. Recommend safe alternative medicines based on the triggered rule limitations.\n"
            "4. Provide counseling points/education for the patient.\n\n"
            "OUTPUT FORMAT INSTRUCTIONS:\n"
            "You MUST respond ONLY with a single valid JSON object. Do not include markdown wraps (like ```json) or explanation outside the JSON.\n"
            "The JSON structure must match this schema:\n"
            "{\n"
            '  "clinical_explanation": "CONCISE, action-first clinical summary (max 2-3 sentences). Focus immediately on the main safety actions (e.g., \\"STOP Metformin when initiating Insulin\\") rather than verbose descriptions.",\n'
            '  "patient_friendly_summary": "Simple, non-technical explanation for the patient of why this prescription might pose risks.",\n'
            '  "suggested_alternatives": ["AlternativeDrug1", "AlternativeDrug2"],\n'
            '  "medication_education": "Key counseling points and warnings for the patient taking these medicines."\n'
            "}"
        )

    @staticmethod
    def build_explain_user_prompt(
        risk_score: int,
        risk_level: str,
        triggered_rules: List[str],
        recommended_action: str,
        patient_age: int,
        patient_gender: str,
        patient_allergies: List[str],
        patient_diseases: List[str],
        current_medicines: List[str],
        new_prescription_medicines: List[str]
    ) -> str:
        """
        Assembles user prompt using the completed clinical report inputs.
        """
        report_data = {
            "completed_audit_decisions": {
                "risk_score": risk_score,
                "risk_level": risk_level,
                "triggered_rules": triggered_rules,
                "recommended_action": recommended_action
            },
            "patient_context": {
                "age": patient_age,
                "gender": patient_gender,
                "allergies": patient_allergies,
                "active_diseases": patient_diseases,
                "current_medications": current_medicines
            },
            "new_prescription_to_explain": new_prescription_medicines
        }

        return (
            "--- IMMUTABLE CLINICAL AUDIT REPORT ---\n"
            f"{json.dumps(report_data, indent=2)}\n\n"
            "--- YOUR TASK ---\n"
            "Explain the audit decisions listed above. Provide the clinical_explanation, patient_friendly_summary, "
            "suggested_alternatives (excluding any drugs matching patient allergies or active interactions), "
            "and patient medication_education.\n"
            "Return the output in the specified JSON format."
        )
