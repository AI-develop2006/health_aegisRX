from fastapi import APIRouter
from app.core.config import settings

router = APIRouter()

@router.get("/health")
async def health_check():
    """
    Returns service health status, current environment, and LLM configuration details.
    """
    return {
        "status": "healthy",
        "env": settings.ENV,
        "llm_provider": settings.LLM_PROVIDER,
        "medgemma_api_url": settings.MEDGEMMA_API_URL
    }
