import logging
from pathlib import Path
from app.llm.adapter import LLMAdapter

logger = logging.getLogger("ai-service.education-service")

class EducationService:
    def __init__(self):
        self.adapter = LLMAdapter()
        self.prompt_path = Path(__file__).resolve().parent.parent / "prompts" / "patient_education.txt"

    async def generate_education(self, medication_name: str, instructions: str) -> dict:
        try:
            with open(self.prompt_path, "r", encoding="utf-8") as f:
                template = f.read()
        except Exception:
            template = "Generate guide for: {medication_name} with instructions: {instructions}"

        user_prompt = template.format(medication_name=medication_name, instructions=instructions)
        system_prompt = "You are a helpful patient education medical assistant."
        
        resp = await self.adapter.get_response(system_prompt, user_prompt)
        return {
            "status": "SUCCESS",
            "guide": resp["content"],
            "mode": resp["mode"]
        }
