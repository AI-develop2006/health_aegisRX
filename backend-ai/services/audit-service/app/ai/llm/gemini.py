import json
import logging
import time
import httpx
from typing import Optional, Type
from pydantic import BaseModel
from app.core.config import settings
from app.ai.llm.base import BaseLLM

logger = logging.getLogger("AegisRx.GeminiClient")

class GeminiClient(BaseLLM):
    def __init__(self):
        self.api_key = settings.GEMINI_API_KEY
        if settings.USE_MOCK_LLM:
            self.is_mock = True
            logger.warning("USE_MOCK_LLM is enabled. GeminiClient will operate in Mock Fallback Mode.")
        elif self.api_key and not self.api_key.startswith("mock"):
            self.is_mock = False
            logger.info("GeminiClient initialized in Active Production Mode.")
        else:
            self.is_mock = True
            logger.warning("GEMINI_API_KEY is not configured or is a mock key. GeminiClient will operate in Mock Fallback Mode.")

    async def generate_response(
        self, 
        system_prompt: str, 
        user_prompt: str, 
        response_format: Optional[Type[BaseModel]] = None
    ) -> str:
        res = await self.safe_generate_response(system_prompt, user_prompt, response_format)
        return res["content"]

    async def safe_generate_response(
        self,
        system_prompt: str,
        user_prompt: str,
        response_format: Optional[Type[BaseModel]] = None
    ) -> dict:
        if settings.USE_MOCK_LLM:
            logger.warning("USE_MOCK_LLM enabled. Using Gemini mock fallback.")
            fallback = self._generate_mock_fallback(user_prompt)
            return {"content": fallback, "mode": "mock", "reason": "USE_MOCK_LLM enabled"}

        if not self.api_key or self.api_key.startswith("mock"):
            if settings.ENV.lower() in ("production", "prod"):
                raise ValueError("Gemini API Key is missing or invalid in production mode.")
            logger.warning("Invalid or mock Gemini API key. Using mock fallback.")
            fallback = self._generate_mock_fallback(user_prompt)
            return {"content": fallback, "mode": "mock", "reason": "Invalid or mock API key"}

        try:
            import asyncio
            content = await asyncio.wait_for(
                self.real_generate_response(system_prompt, user_prompt, response_format),
                timeout=5.0
            )
            return {"content": content, "mode": "real", "reason": None}
        except asyncio.TimeoutError:
            logger.error("Gemini API call timed out. Falling back to mock.")
            fallback = self._generate_mock_fallback(user_prompt)
            return {"content": fallback, "mode": "mock", "reason": "Gemini timeout"}
        except Exception as e:
            logger.error(f"Gemini API call failed: {e}. Falling back to mock.")
            fallback = self._generate_mock_fallback(user_prompt)
            return {"content": fallback, "mode": "mock", "reason": f"Gemini error: {str(e)}"}

    async def real_generate_response(
        self, 
        system_prompt: str, 
        user_prompt: str, 
        response_format: Optional[Type[BaseModel]] = None
    ) -> str:
        url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={self.api_key}"
        
        # Build the payload structure required by the Gemini API
        payload = {
            "contents": [
                {
                    "role": "user",
                    "parts": [
                        {"text": user_prompt}
                    ]
                }
            ],
            "systemInstruction": {
                "parts": [
                    {"text": system_prompt}
                ]
            },
            "generationConfig": {
                "responseMimeType": "application/json",
                "temperature": 0.1
            }
        }

        logger.info("Sending request to Google Gemini API (gemini-2.5-flash)...")
        start_time = time.time()
        
        async with httpx.AsyncClient(timeout=20.0) as client:
            response = await client.post(url, json=payload)
            response.raise_for_status()
            data = response.json()
            
            latency = (time.time() - start_time) * 1000
            logger.info(f"Gemini API response received in {latency:.2f}ms.")
            
            # Extract text content from Gemini's response schema
            content = data["candidates"][0]["content"]["parts"][0]["text"]
            return content

    def _generate_mock_fallback(self, user_prompt: str) -> str:
        """Deterministic Mock Gemini LLM generator."""
        logger.info("Executing Gemini mock LLM fallback generation...")
        from app.ai.llm.gpt import GPTClient
        gpt_mock = GPTClient()
        raw_res = gpt_mock._generate_mock_fallback(user_prompt)
        
        try:
            data = json.loads(raw_res)
            data["clinical_explanation"] = "[Gemini Clinical Inference] " + data.get("clinical_explanation", "")
            return json.dumps(data)
        except Exception:
            return raw_res
