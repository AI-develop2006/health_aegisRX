import os
from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict

# Find workspace root or backend-ai root where .env is stored
BASE_DIR = Path(__file__).resolve().parent.parent.parent

class Settings(BaseSettings):
    ENV: str = "development"
    LOG_LEVEL: str = "INFO"
    LLM_PROVIDER: str = "gpt"  # 'gpt' or 'medgemma'
    OPENAI_API_KEY: str = ""
    MEDGEMMA_API_URL: str = "http://localhost:8000/v1"
    GEMINI_API_KEY: str = ""

    # Pydantic v2 settings configuration
    model_config = SettingsConfigDict(
        env_file=os.path.join(BASE_DIR, ".env"),
        env_file_encoding="utf-8",
        extra="ignore"
    )

settings = Settings()
