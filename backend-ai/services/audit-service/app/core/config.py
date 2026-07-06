import os
import app.config as cfg

class SettingsBridge:
    @property
    def ENV(self) -> str:
        return os.getenv("ENV", "development")
        
    @property
    def LOG_LEVEL(self) -> str:
        return os.getenv("LOG_LEVEL", "INFO")
        
    @property
    def LLM_PROVIDER(self) -> str:
        return os.getenv("LLM_PROVIDER", "gemini")
        
    @property
    def OPENAI_API_KEY(self) -> str:
        return os.getenv("OPENAI_API_KEY", "")
        
    @property
    def MEDGEMMA_API_URL(self) -> str:
        return os.getenv("MEDGEMMA_API_URL", "http://localhost:8000/v1")
        
    @property
    def GEMINI_API_KEY(self) -> str:
        return os.getenv("GEMINI_API_KEY", "")

settings = SettingsBridge()
