from app.ai.knowledge.base import BaseSNOMED

class SNOMEDMock(BaseSNOMED):
    def __init__(self):
        # Database mapping conditions and allergies to SNOMED codes
        self.code_db = {
            "chronic kidney disease": "709044004",
            "ckd": "709044004",
            "hypertension": "38341003",
            "high blood pressure": "38341003",
            "diabetes": "44054006",
            "diabetes mellitus": "44054006",
            "liver cirrhosis": "19943007",
            "cirrhosis": "19943007",
            "penicillin": "91936005",
            "penicillins": "91936005",
            "sulfa": "419082005",
            "sulfonamides": "419082005",
            "aspirin": "294657003",
            "nsaids": "293586001",
            "asthma": "195967001",
            "peptic ulcer": "13200003"
        }

    async def get_concept_code(self, name: str) -> str:
        normalized = name.strip().lower()
        if normalized in self.code_db:
            return self.code_db[normalized]
            
        # Partial match
        for key, code in self.code_db.items():
            if key in normalized or normalized in key:
                return code
                
        # Default code for unmapped concepts
        return "UNKNOWN_SNOMED_CODE"
