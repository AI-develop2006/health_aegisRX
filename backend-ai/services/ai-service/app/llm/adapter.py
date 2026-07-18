import logging
from app.llm.base import BaseLLM
from app.llm.qwen_provider import QwenProvider

logger = logging.getLogger("ai-service.LLMAdapter")

class LLMAdapter:
    def __init__(self):
        # The Qwen provider is set as the sole active provider
        self.provider: BaseLLM = QwenProvider()
        logger.info("LLMAdapter initialized with active QwenProvider.")

    async def get_response(self, system_prompt: str, user_prompt: str) -> dict:
        """
        Delegates LLM generation requests to the active local provider.
        """
        return await self.provider.safe_generate_response(system_prompt, user_prompt)
