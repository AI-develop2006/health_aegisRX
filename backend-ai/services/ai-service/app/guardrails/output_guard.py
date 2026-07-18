import json
import logging
from typing import Dict, Any

logger = logging.getLogger("ai-service.output-guard")

class OutputGuardrailException(Exception):
    pass

class OutputGuard:
    @staticmethod
    def validate_output(parsed_json: Dict[str, Any], deterministic_report: Dict[str, Any]) -> Dict[str, Any]:
        """
        Validates LLM output JSON and guarantees that the narratives do not overwrite or
        compromise the calculated clinical decision outcomes.
        """
        # Ensure we have the required keys
        required_keys = ["clinical_explanation", "patient_friendly_summary", "suggested_alternatives", "medication_education"]
        for key in required_keys:
            if key not in parsed_json:
                logger.warning(f"Output Guard: Missing expected key '{key}' in LLM response. Appending empty default.")
                parsed_json[key] = "" if key != "suggested_alternatives" else []

        # Enforce clinical authority:
        # Check if the LLM generated explanation attempts to modify the risk or bypass restrictions
        explanation_lower = parsed_json.get("clinical_explanation", "").lower()
        patient_summary_lower = parsed_json.get("patient_friendly_summary", "").lower()
        
        rule_risk = deterministic_report.get("risk_level", "SAFE").upper()
        
        # If rules engine determined the prescription is HIGH_RISK, the LLM must not call it safe or tell the patient it is safe
        if rule_risk in ("HIGH_RISK", "CRITICAL", "WARNING"):
            override_indicators = ["is safe to dispense", "no risks detected", "safe for patient", "override this block"]
            for indicator in override_indicators:
                if indicator in explanation_lower or indicator in patient_summary_lower:
                    logger.error("Output Guard: LLM generated explanation attempts to override deterministic safety block.")
                    # Automatically correct the narrative rather than throwing exception to maintain failsafe uptime
                    parsed_json["clinical_explanation"] = (
                        f"Deterministic rules identified safety conflicts: {', '.join(deterministic_report.get('triggered_rules', []))}. "
                        "The prescription cannot be dispensed without clinical override review."
                    )
                    parsed_json["patient_friendly_summary"] = "This combination of medicines is flagged as high risk. Please consult your physician."
                    break

        return parsed_json
