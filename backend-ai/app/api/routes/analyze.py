from fastapi import APIRouter, HTTPException, Depends
from app.schemas.patient import PatientContext
from app.schemas.response import PrescriptionSafetyAnalysis
from app.ai.services.ai_service import AIService
from app.ai.report.report_generator import ReportGenerator
import logging

logger = logging.getLogger("AegisRx.AnalyzeRoute")
router = APIRouter()

# Dependency injection for AIService to keep things modular and unit-testable
def get_ai_service() -> AIService:
    return AIService()

@router.post("/analyze", response_model=PrescriptionSafetyAnalysis)
async def analyze_prescription(
    patient: PatientContext,
    ai_service: AIService = Depends(get_ai_service)
):
    """
    Accepts patient history and new prescriptions, performs safety analysis
    via clinical agents and LLM, and returns the structured report.
    """
    try:
        # Validate that patient name or ID or other fields are appropriate
        if not patient.patient_id.strip():
            raise HTTPException(status_code=400, detail="Invalid patient_id")
            
        logger.info(f"Received safety analysis request for patient: {patient.patient_id}")
        
        # Perform prescription safety analysis
        analysis_result = await ai_service.analyze_prescription(patient)
        
        # Standardize report using ReportGenerator (e.g., append clinical disclaimers)
        final_report = ReportGenerator.generate_report(analysis_result)
        
        return final_report

    except ValueError as val_err:
        logger.error(f"Validation error in request parameters: {str(val_err)}")
        raise HTTPException(status_code=400, detail=f"Invalid request data: {str(val_err)}")
    except HTTPException as http_err:
        raise http_err
    except Exception as exc:
        logger.error(f"Internal error processing safety analysis: {str(exc)}", exc_info=True)
        raise HTTPException(
            status_code=500, 
            detail=f"An internal error occurred during clinical safety evaluation: {str(exc)}"
        )
