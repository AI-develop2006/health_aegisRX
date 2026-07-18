import logging
from pathlib import Path
from app.llm.adapter import LLMAdapter

logger = logging.getLogger("ai-service.chat-service")

class ChatService:
    def __init__(self):
        self.adapter = LLMAdapter()
        self.prompt_path = Path(__file__).resolve().parent.parent / "prompts" / "medical_chat.txt"

    async def medical_chat(self, question: str, context: str) -> dict:
        try:
            with open(self.prompt_path, "r", encoding="utf-8") as f:
                template = f.read()
        except Exception:
            template = "Question: {question}. Context: {context}"

        user_prompt = template.format(question=question, context=context)
        system_prompt = "You are a clinical AI chat bot. Answer patient questions safely."
        
        resp = await self.adapter.get_response(system_prompt, user_prompt)
        return {
            "status": "SUCCESS",
            "reply": resp["content"],
            "mode": resp["mode"]
        }
