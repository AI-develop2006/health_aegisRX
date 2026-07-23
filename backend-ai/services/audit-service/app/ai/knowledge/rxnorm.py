from typing import Dict, Any
from app.ai.knowledge.base import BaseRxNorm

import logging
from app.core.config import settings

logger = logging.getLogger("AegisRx.RxNorm")

class RxNormMock(BaseRxNorm):
    _cache = {}

    def __init__(self):
        # Local mock database for common medicines
        self.db = {
            "ibuprofen": {
                "generic_name": "ibuprofen",
                "brand_names": ["Advil", "Motrin", "Nurofen"],
                "drug_class": "NSAID",
                "rxcui": "5640"
            },
            "amoxicillin": {
                "generic_name": "amoxicillin",
                "brand_names": ["Amoxil", "Moxatag", "Trimox"],
                "drug_class": "Penicillin-class Antibiotic",
                "rxcui": "723"
            },
            "warfarin": {
                "generic_name": "warfarin",
                "brand_names": ["Coumadin", "Jantoven"],
                "drug_class": "Anticoagulant",
                "rxcui": "11289"
            },
            "metformin": {
                "generic_name": "metformin",
                "brand_names": ["Glucophage", "Fortamet", "Glumetza"],
                "drug_class": "Biguanide Antidiabetic",
                "rxcui": "6809"
            },
            "aspirin": {
                "generic_name": "aspirin",
                "brand_names": ["Bayer Aspirin", "Ecotrin", "Buffex"],
                "drug_class": "NSAID / Antiplatelet",
                "rxcui": "1191"
            },
            "lisinopril": {
                "generic_name": "lisinopril",
                "brand_names": ["Prinivil", "Zestril"],
                "drug_class": "ACE Inhibitor",
                "rxcui": "29046"
            },
            "acetaminophen": {
                "generic_name": "acetaminophen",
                "brand_names": ["Tylenol", "Mapap", "Panadol", "Paracetamol", "Dolo", "Dolo 650"],
                "drug_class": "Analgesic / Antipyretic",
                "rxcui": "161"
            },
            "penicillin": {
                "generic_name": "penicillin",
                "brand_names": ["Pen-Vee K"],
                "drug_class": "Penicillin-class Antibiotic",
                "rxcui": "7980"
            },
            "prednisone": {
                "generic_name": "prednisone",
                "brand_names": ["Deltasone", "Rayos", "Sterapred"],
                "drug_class": "Corticosteroid",
                "rxcui": "8640"
            }

        }

    async def get_concept_details(self, drug_name: str) -> Dict[str, Any]:
        drug_name_clean = drug_name.strip().lower()
        if drug_name_clean in self._cache:
            logger.info(f"RxNorm cache hit for: {drug_name_clean}")
            return self._cache[drug_name_clean]

        if settings.USE_MOCK_AUDIT:
            logger.info("USE_MOCK_AUDIT is enabled. Using RxNorm mock database.")
            return self._get_mock_concept_details(drug_name)

        try:
            import httpx
            logger.info(f"USE_MOCK_AUDIT is false. Querying NIH RxNorm API for: {drug_name}...")
            async with httpx.AsyncClient(timeout=10.0) as client:
                url = f"https://rxnav.nlm.nih.gov/REST/rxcui.json?name={drug_name}"
                res = await client.get(url)
                res.raise_for_status()
                data = res.json()
                rxcui = data.get("idGroup", {}).get("rxnormId", [None])[0]
                if not rxcui:
                    raise ValueError(f"No RxNorm concept ID found for: {drug_name}")
                
                # Fetch drug class details
                class_url = f"https://rxnav.nlm.nih.gov/REST/rxclass/class/byRxcui.json?rxcui={rxcui}"
                class_res = await client.get(class_url)
                class_res.raise_for_status()
                class_data = class_res.json()
                
                drug_class = "Unknown"
                concepts = class_data.get("rxclassDrugInfoList", {}).get("rxclassDrugInfo", [])
                if concepts:
                    drug_class = concepts[0].get("rxclassMinCard", {}).get("className", "Unknown")

                result = {
                    "generic_name": drug_name.strip().lower(),
                    "brand_names": [],
                    "drug_class": drug_class,
                    "rxcui": str(rxcui)
                }
                self._cache[drug_name_clean] = result
                return result
        except Exception as e:
            logger.warning(f"NIH RxNorm query failed for '{drug_name}': {e}. Falling back to local mock registry.")
            return self._get_mock_concept_details(drug_name)

    def _get_mock_concept_details(self, drug_name: str) -> Dict[str, Any]:
        normalized = drug_name.strip().lower()
        
        # Simple lookup: check if it matches generic or brand name
        for generic, details in self.db.items():
            if normalized == generic or any(brand.lower() == normalized for brand in details["brand_names"]):
                return details
                
        # Default fallback for unknown drug
        return {
            "generic_name": normalized,
            "brand_names": [],
            "drug_class": "Unknown",
            "rxcui": "0"
        }
