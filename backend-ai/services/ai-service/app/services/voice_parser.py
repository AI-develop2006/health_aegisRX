import logging
from app.llm.adapter import LLMAdapter

logger = logging.getLogger("ai-service.voice-parser-service")

class VoiceParserService:
    def __init__(self):
        self.adapter = LLMAdapter()

    async def parse_voice_prescription(self, speech_transcript: str) -> dict:
        user_prompt = f"Parse the doctor's spoken prescription draft and structure it into clean JSON:\n\n{speech_transcript}"
        system_prompt = "You are a clinical transcription parser. Return medication name, strength, and frequency only."
        
        resp = await self.adapter.get_response(system_prompt, user_prompt)
        return {
            "status": "SUCCESS",
            "parsed_prescription": resp["content"],
            "mode": resp["mode"]
        }
