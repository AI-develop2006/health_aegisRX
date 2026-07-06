from typing import List, Dict, Any, Set
from app.ai.knowledge.base import BaseDrugBank

class DrugBankMock(BaseDrugBank):
    def __init__(self):
        # Database of drug interactions by generic drug pairs (sorted tuple)
        self.interactions_db = {
            ("ibuprofen", "warfarin"): {
                "severity": "MAJOR",
                "description": "Ibuprofen can increase bleeding risk when taken with Warfarin by inhibiting platelet aggregation and causing gastric mucosal damage."
            },
            ("aspirin", "warfarin"): {
                "severity": "MAJOR",
                "description": "Aspirin increases bleeding risk when co-administered with Warfarin due to additive antiplatelet and anticoagulant effects."
            },
            ("ibuprofen", "lisinopril"): {
                "severity": "MODERATE",
                "description": "NSAIDs like Ibuprofen may decrease the antihypertensive effect of ACE inhibitors like Lisinopril and increase risk of renal impairment."
            },
            ("aspirin", "ibuprofen"): {
                "severity": "MINOR",
                "description": "Ibuprofen may decrease the cardioprotective antiplatelet effect of low-dose Aspirin if co-administered."
            }
        }

    async def get_drug_interactions(self, drugs: List[str]) -> List[Dict[str, Any]]:
        # Normalize and clean drug list
        cleaned_drugs = list(set([d.strip().lower() for d in drugs if d.strip()]))
        found_interactions = []

        # Compare pairs
        for i in range(len(cleaned_drugs)):
            for j in range(i + 1, len(cleaned_drugs)):
                pair = tuple(sorted([cleaned_drugs[i], cleaned_drugs[j]]))
                if pair in self.interactions_db:
                    detail = self.interactions_db[pair]
                    found_interactions.append({
                        "severity": detail["severity"],
                        "drugs": [pair[0].capitalize(), pair[1].capitalize()],
                        "description": detail["description"]
                    })
        return found_interactions
