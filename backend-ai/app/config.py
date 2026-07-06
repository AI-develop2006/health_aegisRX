import os
import logging
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv(override=True)

# ============================================
# MongoDB Configuration
# ============================================
MONGODB_URI = os.getenv("MONGODB_URI", "mongodb://localhost:27017/")
MONGODB_DATABASE = os.getenv("MONGODB_DATABASE", "healthcare_db")
COLLECTION_PRESCRIPTIONS = os.getenv("COLLECTION_PRESCRIPTIONS", "prescriptions")
COLLECTION_ALLERGIES = os.getenv("COLLECTION_ALLERGIES", "allergies")

# ============================================
# Rules Configuration
# ============================================
DUPLICATE_TOLERANCE_DAYS = int(os.getenv("DUPLICATE_TOLERANCE_DAYS", "30"))
PRESCRIPTION_HISTORY_DAYS = int(os.getenv("PRESCRIPTION_HISTORY_DAYS", "90"))

# ============================================
# Logging & Output Configuration
# ============================================
IS_VERCEL = os.getenv("VERCEL") == "1"

# Resolve paths relative to the backend-ai root (one level above this app/ package)
_BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

if IS_VERCEL:
    LOG_FILE = "/tmp/ai_agent.log"
    OUTPUT_DIR = "/tmp/output"
else:
    LOG_FILE = os.path.join(_BASE_DIR, "ai_agent.log")
    OUTPUT_DIR = os.path.join(_BASE_DIR, "output")

OUTPUT_FILE = "prescription_analysis.json"
LOG_LEVEL = logging.INFO

# Ensure output directory exists
os.makedirs(OUTPUT_DIR, exist_ok=True)

# ============================================
# Logging Setup
# ============================================
logging.basicConfig(
    level=LOG_LEVEL,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(LOG_FILE, encoding='utf-8'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("AI_Agent")
logger.info("app/config.py — Configuration and Logging successfully initialized")

# ============================================
# Polygon Blockchain Configuration
# ============================================
POLYGON_RPC_URL = os.getenv("POLYGON_RPC_URL", "https://rpc-amoy.polygon.technology")
POLYGON_CONTRACT_ADDRESS = os.getenv("POLYGON_CONTRACT_ADDRESS", "")

# Private Keys for Demonstration / Local Testing
TEST_DOCTOR_PRIVATE_KEY = os.getenv("TEST_DOCTOR_PRIVATE_KEY", "")
TEST_PHARMACY_PRIVATE_KEY = os.getenv("TEST_PHARMACY_PRIVATE_KEY", "")

# ============================================
# Multi-Agent AI Configuration
# ============================================
ENV = os.getenv("ENV", "development")
LLM_PROVIDER = os.getenv("LLM_PROVIDER", "gemini")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")
MEDGEMMA_API_URL = os.getenv("MEDGEMMA_API_URL", "http://localhost:8000/v1")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")


