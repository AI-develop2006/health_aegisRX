import logging
from typing import Dict, Any, List
from app.services.explanation import ExplanationService
from app.services.education import EducationService
from app.services.history_summary import HistorySummaryService
from app.services.chat import ChatService
from app.services.ocr_summary import OcrSummaryService
from app.services.voice_parser import VoiceParserService

logger = logging.getLogger("ai-service.service-facade")

class AIServiceFacade:
    def __init__(self):
        self.explanation_svc = ExplanationService()
        self.education_svc = EducationService()
        self.history_summary_svc = HistorySummaryService()
        self.chat_svc = ChatService()
        self.ocr_summary_svc = OcrSummaryService()
        self.voice_parser_svc = VoiceParserService()

    async def explain(
        self,
        risk_score: int,
        risk_level: str,
        triggered_rules: List[str],
        recommended_action: str,
        patient_age: int,
        patient_gender: str,
        patient_allergies: List[str],
        patient_diseases: List[str],
        current_medicines: List[str],
        new_prescription_medicines: List[str]
    ) -> Dict[str, Any]:
        """Orchestrates explanation narrative generation and validations."""
        return await self.explanation_svc.generate_explanation(
            risk_score=risk_score,
            risk_level=risk_level,
            triggered_rules=triggered_rules,
            recommended_action=recommended_action,
            patient_age=patient_age,
            patient_gender=patient_gender,
            patient_allergies=patient_allergies,
            patient_diseases=patient_diseases,
            current_medicines=current_medicines,
            new_prescription_medicines=new_prescription_medicines
        )
