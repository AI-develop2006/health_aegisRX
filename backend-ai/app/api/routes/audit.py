from fastapi import APIRouter, HTTPException
from app.schemas.response import AuditLogEntry, AuditRequest
from app.ai.services.ai_service import audit_store
from typing import List, Union
import logging

logger = logging.getLogger("AegisRx.AuditRoute")
router = APIRouter()

@router.post("/audit", response_model=Union[List[AuditLogEntry], AuditLogEntry])
async def get_audit_trail(request: AuditRequest):
    """
    Returns the historical audit trail records including raw prompts, LLM responses, 
    latency metrics, and token usages.
    If analysis_id is specified, retrieves the specific analysis run.
    Otherwise, returns all historical logs.
    """
    if request.analysis_id:
        analysis_str = str(request.analysis_id)
        logger.info(f"Retrieving audit history for run ID: {analysis_str}")
        if analysis_str not in audit_store:
            logger.warning(f"Audit log entry not found for ID: {analysis_str}")
            raise HTTPException(
                status_code=404, 
                detail=f"No clinical safety audit log found matching ID: {analysis_str}"
            )
        return audit_store[analysis_str]

    # Return all logs sorted by timestamp (newest first)
    logger.info("Retrieving all historical clinical audit logs.")
    return sorted(
        list(audit_store.values()), 
        key=lambda entry: entry.timestamp, 
        reverse=True
    )
