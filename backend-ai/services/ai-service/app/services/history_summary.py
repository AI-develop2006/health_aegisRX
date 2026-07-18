import logging
from pathlib import Path
from app.llm.adapter import LLMAdapter

logger = logging.getLogger("ai-service.history-summary-service")

class HistorySummaryService:
    def __init__(self):
        self.adapter = LLMAdapter()
        self.prompt_path = Path(__file__).resolve().parent.parent / "prompts" / "patient_summary.txt"

    async def summarize_history(self, patient_history: str) -> dict:
        try:
            with open(self.prompt_path, "r", encoding="utf-8") as f:
                template = f.read()
        except Exception:
            template = "Summarize patient report: {patient_history}"

        user_prompt = template.format(patient_history=patient_history)
        system_prompt = "You are a clinical history summarizer."
        
        resp = await self.adapter.get_response(system_prompt, user_prompt)
        return {
            "status": "SUCCESS",
            "summary": resp["content"],
            "mode": resp["mode"]
        }
