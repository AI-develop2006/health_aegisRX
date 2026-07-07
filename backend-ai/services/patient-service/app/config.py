"""Patient Service — Configuration"""
import os
from dotenv import load_dotenv

load_dotenv(override=True)

MONGODB_URI            = os.getenv("MONGODB_URI", "mongodb://localhost:27017/")
MONGODB_DATABASE       = os.getenv("MONGODB_DATABASE", "healthcare_db")
COLLECTION_PRESCRIPTIONS = os.getenv("COLLECTION_PRESCRIPTIONS", "prescriptions")
LOG_LEVEL              = os.getenv("LOG_LEVEL", "INFO")
FORCE_MOCK_DB          = os.getenv("FORCE_MOCK_DB", "false").lower() == "true"
