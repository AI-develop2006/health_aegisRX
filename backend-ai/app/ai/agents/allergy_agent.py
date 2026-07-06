from typing import Dict, Any, List
from app.schemas.patient import PatientContext
from app.ai.agents.base_agent import BaseAgent

class AllergyAgent(BaseAgent):
    async def analyze(self, patient: PatientContext) -> Dict[str, Any]:
        """
        Compares new prescriptions against patient allergies, detecting direct drug
        matches, cross-reactivity, and allergy class warnings.
        """
        allergy_conflicts = []

        if not patient.allergies:
            return {"allergy_conflicts": [], "has_issues": False}

        # Resolve allergy concepts
        resolved_allergies = []
        for allergy in patient.allergies:
            allergy_info = await self.rxnorm.get_concept_details(allergy)
            # Resolve SNOMED code
            snomed_code = await self.snomed.get_concept_code(allergy)
            resolved_allergies.append({
                "original": allergy,
                "generic": allergy_info["generic_name"],
                "class": allergy_info["drug_class"],
                "snomed_code": snomed_code
            })

        # Check each new drug
        for drug in patient.new_prescription:
            drug_info = await self.rxnorm.get_concept_details(drug)
            drug_generic = drug_info["generic_name"]
            drug_class = drug_info["drug_class"]
            
            # Fetch DailyMed labeling warnings to check contraindications
            dm_warnings = await self.dailymed.get_drug_warnings(drug_generic)
            contraindications = dm_warnings.get("contraindications", [])

            for allergy in resolved_allergies:
                conflict_reason = None
                
                # Check 1: Direct generic name match
                if drug_generic == allergy["generic"]:
                    conflict_reason = f"Direct allergy conflict. Patient is allergic to {allergy['original']} and was prescribed {drug}."
                
                # Check 2: Drug class cross-reactivity match
                elif drug_class != "Unknown" and (drug_class == allergy["class"] or drug_class.lower() in allergy["original"].lower() or allergy["class"].lower() in drug_class.lower()):
                    conflict_reason = f"Class-based allergy risk. Prescribed drug {drug} belongs to '{drug_class}' which matches patient allergy to {allergy['original']}."

                # Check 3: Check drug contraindications list for allergy terms
                if not conflict_reason:
                    for contra in contraindications:
                        contra_lower = contra.lower()
                        if "hypersensitivity" in contra_lower or "allergy" in contra_lower:
                            if allergy["generic"] in contra_lower or allergy["class"].lower() in contra_lower or allergy["original"].lower() in contra_lower:
                                conflict_reason = f"FDA labeled contraindication warning: '{contra}' matching patient allergy to {allergy['original']}."
                                break

                if conflict_reason:
                    allergy_conflicts.append({
                        "allergy": allergy["original"],
                        "drug": drug,
                        "description": conflict_reason,
                        "snomed_code": allergy["snomed_code"]
                    })

        return {
            "allergy_conflicts": allergy_conflicts,
            "has_issues": len(allergy_conflicts) > 0
        }
