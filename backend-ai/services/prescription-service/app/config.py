"""Prescription Service — Configuration"""
import os
import logging
from dotenv import load_dotenv

load_dotenv(override=True)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("prescription-service")

MONGODB_URI              = os.getenv("MONGODB_URI", "mongodb://localhost:27017/")
MONGODB_DATABASE         = os.getenv("MONGODB_DATABASE", "healthcare_db")
COLLECTION_PRESCRIPTIONS   = os.getenv("COLLECTION_PRESCRIPTIONS", "prescriptions")
LOG_LEVEL                = os.getenv("LOG_LEVEL", "INFO")
ENV                      = os.getenv("ENV", "development")
FORCE_MOCK_DB            = os.getenv("FORCE_MOCK_DB", "false").lower() == "true"
ALLOW_MOCK_POLYGON_TX    = os.getenv("ALLOW_MOCK_POLYGON_TX", "false").lower() == "true"

# Blockchain Config
POLYGON_RPC_URL          = os.getenv("POLYGON_RPC_URL", "https://rpc-amoy.polygon.technology")
POLYGON_CONTRACT_ADDRESS = os.getenv("POLYGON_CONTRACT_ADDRESS", "")
TEST_DOCTOR_PRIVATE_KEY  = os.getenv("TEST_DOCTOR_PRIVATE_KEY", "")

# Audit Service URL (Internal microservice call)
AUDIT_SERVICE_URL        = os.getenv("AUDIT_SERVICE_URL", "http://localhost:4005")
