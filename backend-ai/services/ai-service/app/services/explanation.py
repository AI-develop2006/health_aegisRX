import json
import logging
from pathlib import Path
from typing import Dict, Any, List
from app.llm.adapter import LLMAdapter
from app.llm.response_parser import ResponseParser
from app.guardrails.validator import GuardrailsValidator

logger = logging.getLogger("ai-service.explanation-service")

class ExplanationService:
    def __init__(self):
        self.adapter = LLMAdapter()
        self.prompt_path = Path(__file__).resolve().parent.parent / "prompts" / "clinical_explanation.txt"

    async def generate_explanation(
        self,
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
    ) -> Dict[str, Any]:
        """
        Loads the clinical explanation prompt template, runs guardrails, queries the Qwen LLM
        via the adapter, parses the response, and runs output safety sanitizations.
        """
        # Load prompt template
        try:
            with open(self.prompt_path, "r", encoding="utf-8") as f:
                template = f.read()
        except Exception as file_err:
            logger.error(f"Failed to read prompt template file: {self.prompt_path}. Error: {file_err}")
            template = "Explain these clinical findings: {report_data}"

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

        user_prompt = template.replace("{report_data}", json.dumps(report_data, indent=2))
        system_prompt = "You are a Board-Certified Clinical Pharmacist. Respond ONLY with a valid JSON object matching the requested schema. No conversational wrappers."

        # 1. Run Input Guardrails
        try:
            GuardrailsValidator.run_input_guard(user_prompt)
        except Exception as guard_exc:
            logger.error(f"Input Guardrails rejected the request: {guard_exc}")
            return {
                "status": "GUARDRAILS_BLOCKED",
                "mode": "blocked",
                "fallback_reason": str(guard_exc),
                "clinical_explanation": "Security Block: Input prompt contains violation patterns.",
                "patient_friendly_summary": "Safety check blocked. Please contact clinic support.",
                "suggested_alternatives": [],
                "medication_education": ""
            }

        # 2. Query Qwen Local LLM Adapter
        response_dict = await self.adapter.get_response(system_prompt, user_prompt)
        response_content = response_dict["content"]
        mode_used = response_dict["mode"]
        reason_info = response_dict["reason"]

        if mode_used in ("mock", "failsafe"):
            # Return failsafe directly if mock was used
            logger.info("Using mock/failsafe response directly. Skipping output guardrails.")
            parsed_json = ResponseParser.parse_json_response(response_content)
            return {
                "status": "SUCCESS" if mode_used == "mock" else "FAILSAFE_FALLBACK",
                "mode": mode_used,
                "fallback_reason": reason_info,
                **parsed_json
            }

        # 3. Parse JSON Response
        try:
            parsed_json = ResponseParser.parse_json_response(response_content)
        except Exception as parse_err:
            logger.error(f"JSON parsing failed: {parse_err}. Activating Failsafe fallback.")
            return {
                "status": "FAILSAFE_FALLBACK",
                "mode": "failsafe",
                "fallback_reason": f"JSON parsing failed: {parse_err}",
                "clinical_explanation": "Failsafe Mode active (JSON parsing failure). Reasoning generated via the clinical rule engine. Checked conflicts present in allergies, diseases, or drug interactions.",
                "patient_friendly_summary": "This combination of medicines is flagged as high risk. Please consult your physician.",
                "suggested_alternatives": [],
                "medication_education": "Take medicines exactly as prescribed and report any adverse events to your doctor immediately."
            }

        # 4. Run Output Guardrails
        try:
            sanitized_json = GuardrailsValidator.run_output_guard(parsed_json, report_data["completed_audit_decisions"])
            return {
                "status": "SUCCESS",
                "mode": mode_used,
                "fallback_reason": None,
                **sanitized_json
            }
        except Exception as out_exc:
            logger.error(f"Output Guardrails failed: {out_exc}")
            return {
                "status": "FAILSAFE_FALLBACK",
                "mode": "failsafe",
                "fallback_reason": f"Output guardrails failed: {out_exc}",
                "clinical_explanation": "Failsafe Mode active (Output validation failure). Checked conflicts present in allergies, diseases, or drug interactions.",
                "patient_friendly_summary": "Safety check blocked. Please contact your doctor.",
                "suggested_alternatives": [],
                "medication_education": "Report adverse reactions immediately."
            }
