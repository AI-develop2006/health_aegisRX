import logging
from fastapi import APIRouter, HTTPException, UploadFile, File, Form
from pydantic import BaseModel, Field
from typing import List, Optional

from app.services.explanation import ExplanationService
from app.services.education import EducationService
from app.services.history_summary import HistorySummaryService
from app.services.chat import ChatService
from app.services.ocr_summary import OcrSummaryService
from app.services.voice_parser import VoiceParserService

logger = logging.getLogger("ai-service.router")
router = APIRouter(tags=["AI & Cognitive"])

# Instantiate Services
explanation_svc = ExplanationService()
education_svc = EducationService()
history_summary_svc = HistorySummaryService()
chat_svc = ChatService()
ocr_summary_svc = OcrSummaryService()
voice_parser_svc = VoiceParserService()

# ─────────────────────────────────────────────────────────────────────────────
# 1. SCHEMAS
# ─────────────────────────────────────────────────────────────────────────────

class ExplainRequest(BaseModel):
    risk_score: int = Field(..., example=95)
    risk_level: str = Field(..., example="HIGH_RISK")
    triggered_rules: List[str] = Field(..., example=["Penicillin Allergy"])
    recommended_action: str = Field(..., example="DO_NOT_DISPENSE")
    patient_age: int = Field(..., example=65)
    patient_gender: str = Field(..., example="Male")
    patient_allergies: List[str] = Field(default_factory=list)
    patient_diseases: List[str] = Field(default_factory=list)
    current_medicines: List[str] = Field(default_factory=list)
    new_prescription_medicines: List[str] = Field(..., example=["Amoxicillin"])


class EducationRequest(BaseModel):
    medication_name: str = Field(..., example="Amoxicillin")
    instructions: str = Field(..., example="Take 1 capsule three times daily for 7 days")


class HistorySummaryRequest(BaseModel):
    patient_history: str = Field(..., example="Patient has history of asthma and mild hypertension since 2022.")


class ChatRequest(BaseModel):
    question: str = Field(..., example="Can I drink milk while taking Amoxicillin?")
    context: str = Field(default="", example="Patient is currently on Amoxicillin 500mg.")


class VoiceParserRequest(BaseModel):
    transcript: Optional[str] = Field(None, example="Give Priya Sharma Amoxicillin 500mg three times daily for ten days")
    speech_transcript: Optional[str] = Field(None, example="Give Priya Sharma Amoxicillin 500mg three times daily for ten days")
    patient_id: Optional[str] = None
    doctor_id: Optional[str] = None

# ─────────────────────────────────────────────────────────────────────────────
# 2. ROUTES
# ─────────────────────────────────────────────────────────────────────────────

@router.post("/api/ai/explain")
async def explain_clinical_assessment(payload: ExplainRequest):
    """
    Consumes deterministic clinical safety check outputs and runs local Qwen prompts
    to compile narratives. Passes input and output security guardrails.
    """
    logger.info(f"Routing explain request. Risk Score: {payload.risk_score}")
    res = await explanation_svc.generate_explanation(
        risk_score=payload.risk_score,
        risk_level=payload.risk_level,
        triggered_rules=payload.triggered_rules,
        recommended_action=payload.recommended_action,
        patient_age=payload.patient_age,
        patient_gender=payload.patient_gender,
        patient_allergies=payload.patient_allergies,
        patient_diseases=payload.patient_diseases,
        current_medicines=payload.current_medicines,
        new_prescription_medicines=payload.new_prescription_medicines
    )
    return res


@router.post("/api/ai/patient/education")
async def patient_education(payload: EducationRequest):
    logger.info(f"Routing education request for {payload.medication_name}")
    return await education_svc.generate_education(payload.medication_name, payload.instructions)


@router.post("/api/ai/patient/summary")
async def patient_summary(payload: HistorySummaryRequest):
    logger.info("Routing patient summary request")
    return await history_summary_svc.summarize_history(payload.patient_history)


@router.post("/api/ai/chat")
async def medical_chat(payload: ChatRequest):
    logger.info("Routing medical chat query")
    return await chat_svc.medical_chat(payload.question, payload.context)


@router.post("/api/ai/ocr/structure")
async def ocr_structure(file: UploadFile = File(...)):
    """
    Simulated file reader extracting raw text, then submitting to Qwen
    OCR Structurer sub-service.
    """
    logger.info(f"Routing OCR structuring request for file: {file.filename}")
    try:
        content = await file.read()
        raw_text = content.decode("utf-8", errors="ignore")
        return await ocr_summary_svc.summarize_ocr(raw_text)
    except Exception as e:
        raise HTTPException(500, f"Failed to parse OCR file: {e}")


@router.post("/api/ai/voice/parse")
async def voice_parse(payload: VoiceParserRequest):
    logger.info("Routing voice prescription transcription query")
    text = payload.transcript or payload.speech_transcript
    if not text or not text.strip():
        raise HTTPException(status_code=400, detail="Transcript text is required")
    return await voice_parser_svc.parse_voice_prescription(text)
