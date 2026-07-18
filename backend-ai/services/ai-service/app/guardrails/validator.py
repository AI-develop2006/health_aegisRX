from app.guardrails.input_guard import InputGuard, InputGuardrailException
from app.guardrails.output_guard import OutputGuard, OutputGuardrailException
from typing import Dict, Any

class GuardrailsValidator:
    @staticmethod
    def run_input_guard(prompt: str) -> None:
        """Runs the validation logic on the prompt before sending it to the model."""
        InputGuard.validate_input(prompt)

    @staticmethod
    def run_output_guard(parsed_json: Dict[str, Any], deterministic_report: Dict[str, Any]) -> Dict[str, Any]:
        """Runs output sanitization checks on the parsed response dictionary."""
        return OutputGuard.validate_output(parsed_json, deterministic_report)
