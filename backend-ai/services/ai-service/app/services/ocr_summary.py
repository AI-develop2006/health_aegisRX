import logging
from app.llm.adapter import LLMAdapter

logger = logging.getLogger("ai-service.ocr-summary-service")

class OcrSummaryService:
    def __init__(self):
        self.adapter = LLMAdapter()

    async def summarize_ocr(self, raw_ocr_text: str) -> dict:
        user_prompt = f"Extract and summarize clinical details from this raw OCR text:\n\n{raw_ocr_text}"
        system_prompt = "You are a clinical OCR document summarizer. Respond with key observations only."
        
        resp = await self.adapter.get_response(system_prompt, user_prompt)
        return {
            "status": "SUCCESS",
            "ocr_summary": resp["content"],
            "mode": resp["mode"]
        }
