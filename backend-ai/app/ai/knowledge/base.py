from abc import ABC, abstractmethod
from typing import List, Dict, Any

class BaseDrugBank(ABC):
    @abstractmethod
    async def get_drug_interactions(self, drugs: List[str]) -> List[Dict[str, Any]]:
        """Query drug-drug interactions between a list of medications."""
        pass

class BaseRxNorm(ABC):
    @abstractmethod
    async def get_concept_details(self, drug_name: str) -> Dict[str, Any]:
        """Resolve generic name, brand name, and drug class/categories."""
        pass

class BaseDailyMed(ABC):
    @abstractmethod
    async def get_drug_warnings(self, drug_name: str) -> Dict[str, Any]:
        """Retrieve warnings, indications, and pregnancy warning categories."""
        pass

class BaseOpenFDA(ABC):
    @abstractmethod
    async def get_adverse_events(self, drug_name: str) -> Dict[str, Any]:
        """Query adverse events, age risks, weight risks, or recalls."""
        pass

class BaseSNOMED(ABC):
    @abstractmethod
    async def get_concept_code(self, name: str) -> str:
        """Translate a disease or allergy name to a SNOMED CT concept ID."""
        pass
