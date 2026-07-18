import re
import logging
from typing import Dict, Any

logger = logging.getLogger("ai-service.input-guard")

class InputGuardrailException(Exception):
    pass

class InputGuard:
    MAX_CHAR_LENGTH = 8000
    
    INJECTION_PATTERNS = [
        r"ignore (?:all|your)?\s*instructions",
        r"bypass (?:safety|clinical)?\s*rules",
        r"you are now (?:allowed|permitted)",
        r"system command",
        r"ignore previous",
        r"override safety"
    ]

    @staticmethod
    def validate_input(user_prompt: str) -> None:
        """
        Runs input validations to detect malicious prompt injections, context length limits,
        and verify medical scope.
        """
        # 1. Context length check
        if len(user_prompt) > InputGuard.MAX_CHAR_LENGTH:
            logger.warning(f"Input Guard: Prompt exceeded maximum context length ({len(user_prompt)} chars).")
            raise InputGuardrailException(f"Context length limit exceeded. Maximum size is {InputGuard.MAX_CHAR_LENGTH} characters.")

        # 2. Prompt injection validation
        prompt_lower = user_prompt.lower()
        for pattern in InputGuard.INJECTION_PATTERNS:
            if re.search(pattern, prompt_lower):
                logger.error(f"Input Guard: Potential prompt injection attempt intercepted matching pattern: '{pattern}'.")
                raise InputGuardrailException("Security Violation: Prompt contains instructions to bypass safety guidelines.")

        # 3. PHI leak check (e.g. check for direct patient password keys or NPI passwords in payload)
        if "password" in prompt_lower or "secret_pin" in prompt_lower:
            logger.error("Input Guard: PHI leak detected. Prompt contains authentication secrets.")
            raise InputGuardrailException("Security Violation: PHI leak detected. Unencrypted credentials cannot be passed to the LLM.")

        # 4. Medical scope validation (Ensure prompt contains clinical context indicators)
        clinical_keywords = ["patient", "drug", "medicine", "prescription", "allergy", "disease", "treatment", "clinic", "audit", "warfarin", "ibuprofen", "amoxicillin", "safety"]
        if not any(k in prompt_lower for k in clinical_keywords):
            logger.warning("Input Guard: Prompt lacks clinical indicators. Potential out-of-scope query.")
            # We log a warning instead of raising exception to remain flexible for general system chats.
