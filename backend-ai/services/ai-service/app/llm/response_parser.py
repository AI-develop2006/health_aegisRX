import json
import logging
from typing import Dict, Any

logger = logging.getLogger("ai-service.response-parser")

class ResponseParser:
    @staticmethod
    def parse_json_response(text: str) -> Dict[str, Any]:
        """
        Strips markdown decorators and converts raw text response into a Python dictionary.
        """
        text = text.strip()
        
        # Clean markdown formatting wraps if returned by the LLM
        if text.startswith("```"):
            lines = text.splitlines()
            if lines[0].startswith("```"):
                lines = lines[1:]
            if lines and lines[-1].startswith("```"):
                lines = lines[:-1]
            text = "\n".join(lines).strip()

        try:
            return json.loads(text)
        except Exception as e:
            logger.error(f"Failed to parse LLM response text as JSON. Text: '{text[:200]}...'. Error: {e}")
            raise ValueError(f"Invalid JSON format returned: {e}")
