import json
import logging
import httpx
import asyncio
from typing import Optional, Type
from pydantic import BaseModel
from app.config import settings
from app.llm.base import BaseLLM

logger = logging.getLogger("ai-service.QwenProvider")

class QwenProvider(BaseLLM):
    def __init__(self):
        self.host = settings.MEDGEMMA_API_URL  # We map LLM_HOST from configured URL
        self.model = settings.LLM_PROVIDER    # Configured model
        logger.info(f"Initialized QwenProvider: Host={self.host}, Model={self.model}")

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
            logger.warning("USE_MOCK_LLM enabled. Using Qwen mock fallback.")
            fallback = self._generate_mock_fallback(user_prompt)
            return {"content": fallback, "mode": "mock", "reason": "USE_MOCK_LLM enabled"}

        # Attempt up to 3 retries with progressive delays for transient connectivity failures
        max_retries = 3
        last_error = None
        for attempt in range(max_retries):
            try:
                content = await asyncio.wait_for(
                    self.real_generate_response(system_prompt, user_prompt, response_format),
                    timeout=15.0
                )
                return {"content": content, "mode": "real", "reason": None}
            except (httpx.RequestError, asyncio.TimeoutError) as e:
                last_error = e
                delay = 2 ** attempt
                logger.warning(f"Qwen Connection attempt {attempt+1}/{max_retries} failed. Retrying in {delay}s. Error: {e}")
                await asyncio.sleep(delay)
            except Exception as e:
                # Unhandled non-connection failures should bubble up immediately
                logger.error(f"Qwen execution failed with unhandled error: {e}")
                raise e

        # Permanently failed to connect: Return high-fidelity failsafe mock response instead of cloud fallback
        logger.error(f"All Qwen provider connection attempts failed. Activating local failsafe fallback. Error: {last_error}")
        fallback = self._generate_mock_fallback(user_prompt)
        return {"content": fallback, "mode": "failsafe", "reason": f"Connection failed: {str(last_error)}"}

    async def real_generate_response(
        self, 
        system_prompt: str, 
        user_prompt: str, 
        response_format: Optional[Type[BaseModel]] = None
    ) -> str:
        url = self.host.rstrip("/")
        
        # Determine endpoint path
        is_openai_compat = "/v1" in url or "/chat" in url
        
        async with httpx.AsyncClient(timeout=10.0) as client:
            if is_openai_compat:
                target_url = url if "/chat/completions" in url else f"{url}/chat/completions"
                payload = {
                    "model": self.model if self.model else "qwen3:8b",
                    "messages": [
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": user_prompt}
                    ],
                    "temperature": 0.1,
                    "response_format": {"type": "json_object"} if response_format else None
                }
                logger.info(f"Submitting chat completion request to Qwen API endpoint: {target_url}...")
                response = await client.post(target_url, json=payload)
                response.raise_for_status()
                data = response.json()
                return data["choices"][0]["message"]["content"]
            else:
                # Default to OpenAI route first
                target_url = f"{url}/v1/chat/completions"
                payload = {
                    "model": self.model if self.model else "qwen3:8b",
                    "messages": [
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": user_prompt}
                    ],
                    "temperature": 0.1
                }
                try:
                    logger.info(f"Submitting OpenAI-compatible request to Qwen: {target_url}...")
                    response = await client.post(target_url, json=payload)
                    response.raise_for_status()
                    data = response.json()
                    return data["choices"][0]["message"]["content"]
                except Exception as e:
                    logger.warning(f"OpenAI compat route failed ({e}). Falling back to Ollama native /api/generate...")
                    
                    native_url = f"{url}/api/generate"
                    native_payload = {
                        "model": self.model if self.model else "qwen3:8b",
                        "prompt": user_prompt,
                        "system": system_prompt,
                        "stream": False,
                        "options": {
                            "temperature": 0.1
                        }
                    }
                    response = await client.post(native_url, json=native_payload)
                    response.raise_for_status()
                    data = response.json()
                    return data.get("response", "")
