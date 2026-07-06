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
        if self.api_key and not self.api_key.startswith("mock"):
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
        if self.is_mock:
            return self._generate_mock_fallback(user_prompt)

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

        try:
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

        except httpx.RequestError as e:
            logger.error(f"HTTP request error calling Gemini API: {str(e)}")
            raise RuntimeError(f"LLM service connection failure: {str(e)}")
        except httpx.HTTPStatusError as e:
            logger.error(f"Gemini API returned status error {e.response.status_code}: {e.response.text}")
            raise RuntimeError(f"LLM service API error ({e.response.status_code}): {e.response.text}")
        except Exception as e:
            logger.error(f"Unexpected error in GeminiClient: {str(e)}")
            raise RuntimeError(f"LLM execution failed: {str(e)}")

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
