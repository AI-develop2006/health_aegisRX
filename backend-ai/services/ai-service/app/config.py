import os
from pathlib import Path
from dotenv import load_dotenv

# Load env variables
BASE_DIR = Path(__file__).resolve().parent.parent.parent
load_dotenv(BASE_DIR / ".env", override=True)

class Settings:
    ENV: str = os.getenv("ENV", "development")
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")
    LLM_PROVIDER: str = os.getenv("LLM_PROVIDER", "gemini")
    OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "")
    MEDGEMMA_API_URL: str = os.getenv("MEDGEMMA_API_URL", "http://localhost:8000/v1")
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
    USE_MOCK_LLM: bool = os.getenv("USE_MOCK_LLM", "false").lower() == "true"
    MONGODB_URI: str = os.getenv("MONGODB_URI", "mongodb://localhost:27017")
    MONGODB_DATABASE: str = os.getenv("MONGODB_DATABASE", "healthcare_db_fresh")

    @property
    def is_production(self) -> bool:
        return self.ENV.lower() == "production"

settings = Settings()
