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

    @property
    def USE_MOCK_AUDIT(self) -> bool:
        return os.getenv("USE_MOCK_AUDIT", "false").lower() == "true"

    @property
    def USE_MOCK_LLM(self) -> bool:
        return os.getenv("USE_MOCK_LLM", "false").lower() == "true"

    @property
    def is_production(self) -> bool:
        return self.ENV.lower() == "production"

settings = SettingsBridge()
