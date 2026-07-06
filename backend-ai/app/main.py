import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.api.routes import health, analyze, audit

# Set up logging configuration to prevent leak of sensitive patient profiles in production logs
logging.basicConfig(
    level=getattr(logging, settings.LOG_LEVEL.upper(), logging.INFO),
    format="[%(asctime)s] %(levelname)s [%(name)s.%(funcName)s:%(lineno)d] %(message)s"
)
logger = logging.getLogger("AegisRx.App")

app = FastAPI(
    title="AegisRx AI Sentinel",
    description="Clinical Decision Support System (CDSS) AI Microservice analyzing drug interactions, duplicate therapy, allergies, and contraindications.",
    version="1.0.0"
)

# Enable CORS for frontend and other backend systems integration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Attach API endpoints
app.include_router(health.router, tags=["Health"])
app.include_router(analyze.router, tags=["Analysis"])
app.include_router(audit.router, tags=["Audit"])

@app.get("/")
async def root():
    """
    Landing endpoint displaying system summary.
    """
    return {
        "app": "AegisRx AI Sentinel",
        "role": "Clinical Decision Support AI Microservice",
        "documentation": "/docs",
        "status": "online"
    }
