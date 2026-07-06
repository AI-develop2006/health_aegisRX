import json
import logging
import httpx
from typing import Optional, Type
from pydantic import BaseModel
from app.core.config import settings
from app.ai.llm.base import BaseLLM

logger = logging.getLogger("AegisRx.MedGemmaClient")

class MedGemmaClient(BaseLLM):
    def __init__(self):
        self.api_url = settings.MEDGEMMA_API_URL
        logger.info(f"Initialized MedGemmaClient target endpoint: {self.api_url}")

    async def generate_response(
        self, 
        system_prompt: str, 
        user_prompt: str, 
        response_format: Optional[Type[BaseModel]] = None
    ) -> str:
        # Check if running in mock testing mode or if API is mock
        if "mock" in self.api_url or settings.OPENAI_API_KEY.startswith("mock"):
            return self._generate_mock_fallback(user_prompt)

        try:
            logger.info(f"Sending request to MedGemma API at {self.api_url}...")
            
            # Formulate payloads for typical local LLM APIs (Ollama / vLLM style)
            payload = {
                "model": "medgemma",
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                "temperature": 0.1,
                "options": {
                    "temperature": 0.1
                }
            }
            
            # If Ollama format, response is under response, else choices[0].message.content (vLLM/OpenAI format)
            async with httpx.AsyncClient(timeout=20.0) as client:
                response = await client.post(f"{self.api_url}/chat/completions", json=payload)
                response.raise_for_status()
                data = response.json()
                
                # Check for standard OpenAI-compatible API response format
                if "choices" in data:
                    content = data["choices"][0]["message"]["content"]
                else:
                    # Fallback for alternative endpoint structures
                    content = data.get("response", data.get("content", ""))
                
                logger.info("Successfully received response from MedGemma service.")
                return content

        except httpx.RequestError as e:
            logger.error(f"HTTP request error calling MedGemma API: {str(e)}")
            raise RuntimeError(f"MedGemma LLM connection failed: {str(e)}")
        except httpx.HTTPStatusError as e:
            logger.error(f"MedGemma API returned status error {e.response.status_code}: {e.response.text}")
            raise RuntimeError(f"MedGemma LLM API error ({e.response.status_code})")
        except Exception as e:
            logger.error(f"Unexpected error in MedGemmaClient: {str(e)}")
            raise RuntimeError(f"MedGemma LLM execution failed: {str(e)}")

    def _generate_mock_fallback(self, user_prompt: str) -> str:
        """Reuse the high-fidelity mock generator for MedGemma client tests."""
        logger.info("Executing MedGemma mock LLM fallback generation...")
        # Since the logic is similar for clinical outputs, we mimic a slightly different clinical reasoning style for MedGemma
        from app.ai.llm.gpt import GPTClient
        gpt_mock = GPTClient()
        raw_res = gpt_mock._generate_mock_fallback(user_prompt)
        
        # Parse and slightly modify to show it came from MedGemma mock
        try:
            data = json.loads(raw_res)
            data["clinical_explanation"] = "[MedGemma Clinical Inference] " + data.get("clinical_explanation", "")
            return json.dumps(data)
        except Exception:
            return raw_res
