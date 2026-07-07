"""Audit Service — Configuration"""
import os
import logging
from dotenv import load_dotenv

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("audit-service")

load_dotenv(override=True)

ENV                    = os.getenv("ENV", "development")
USE_MOCK_AUDIT         = os.getenv("USE_MOCK_AUDIT", "false").lower() == "true"
USE_MOCK_LLM           = os.getenv("USE_MOCK_LLM", "false").lower() == "true"
MONGODB_URI            = os.getenv("MONGODB_URI", "mongodb://localhost:27017/")
MONGODB_DATABASE       = os.getenv("MONGODB_DATABASE", "healthcare_db")
COLLECTION_PRESCRIPTIONS = os.getenv("COLLECTION_PRESCRIPTIONS", "prescriptions")
COLLECTION_ALLERGIES   = os.getenv("COLLECTION_ALLERGIES", "allergies")
LOG_LEVEL              = os.getenv("LOG_LEVEL", "INFO")
FORCE_MOCK_DB          = os.getenv("FORCE_MOCK_DB", "false").lower() == "true"
LLM_PROVIDER           = os.getenv("LLM_PROVIDER", "gemini")
GEMINI_API_KEY         = os.getenv("GEMINI_API_KEY", "")
OPENAI_API_KEY         = os.getenv("OPENAI_API_KEY", "")
MEDGEMMA_API_URL       = os.getenv("MEDGEMMA_API_URL", "http://localhost:8000/v1")
