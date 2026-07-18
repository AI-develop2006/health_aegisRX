from abc import ABC, abstractmethod
from typing import Dict, Any, List, Optional
from pydantic import BaseModel
from app.schemas.patient import PatientContext
from app.ai.knowledge.base import BaseDrugBank, BaseRxNorm, BaseDailyMed, BaseOpenFDA, BaseSNOMED

class AgentResult(BaseModel):
    name: str
    severity: Optional[str]
    issues: List[str]
    affected_medicines: List[str]
    meta: Dict = {}


class BaseAgent(ABC):
    def __init__(
        self,
        rxnorm_service: BaseRxNorm,
        drugbank_service: BaseDrugBank,
        dailymed_service: BaseDailyMed,
        openfda_service: BaseOpenFDA,
        snomed_service: BaseSNOMED
    ):
        self.rxnorm = rxnorm_service
        self.drugbank = drugbank_service
        self.dailymed = dailymed_service
        self.openfda = openfda_service
        self.snomed = snomed_service

    @abstractmethod
    async def analyze(self, patient: PatientContext) -> Dict[str, Any]:
        """Perform domain-specific clinical analysis on the patient context."""
        pass
