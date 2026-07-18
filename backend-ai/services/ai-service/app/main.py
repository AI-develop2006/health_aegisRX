import logging
from fastapi import FastAPI
from app.config import settings
from app.router import router

# Initialize Logging
logging.basicConfig(level=settings.LOG_LEVEL)
logger = logging.getLogger("ai-service")

app = FastAPI(
    title="AegisRx AI & Cognitive Microservice",
    description="Handles clinical explanation, summaries, OCR document parsing, and NLP guidance.",
    version="1.0.0"
)

# Include decoupled Qwen service routes
app.include_router(router)

@app.get("/health")
def health_check():
    return {
        "status": "HEALTHY",
        "service": "ai-service",
        "llm_provider_configured": settings.LLM_PROVIDER,
        "llm_host_configured": settings.MEDGEMMA_API_URL
    }
