from typing import Dict, Any
from app.ai.knowledge.base import BaseRxNorm

class RxNormMock(BaseRxNorm):
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
                "brand_names": ["Tylenol", "Mapap", "Panadol"],
                "drug_class": "Analgesic / Antipyretic",
                "rxcui": "161"
            },
            "penicillin": {
                "generic_name": "penicillin",
                "brand_names": ["Pen-Vee K"],
                "drug_class": "Penicillin-class Antibiotic",
                "rxcui": "7980"
            }
        }

    async def get_concept_details(self, drug_name: str) -> Dict[str, Any]:
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
