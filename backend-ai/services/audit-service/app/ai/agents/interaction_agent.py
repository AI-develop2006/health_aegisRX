from typing import Dict, Any, List
from app.schemas.patient import PatientContext
from app.ai.agents.base_agent import BaseAgent

class InteractionAgent(BaseAgent):
    async def analyze(self, patient: PatientContext) -> Dict[str, Any]:
        """
        Detects duplicate therapeutic medications and queries the drugbank mock
        for drug-drug interactions between new and current medications.
        """
        duplicates = []
        resolved_new = []
        resolved_current = []

        # Resolve generic names for new prescription drugs
        for med in patient.new_prescription:
            rx_details = await self.rxnorm.get_concept_details(med)
            resolved_new.append({
                "original": med,
                "generic": rx_details["generic_name"],
                "class": rx_details["drug_class"]
            })

        # Resolve generic names for current medications
        for med in patient.current_medications:
            rx_details = await self.rxnorm.get_concept_details(med)
            resolved_current.append({
                "original": med,
                "generic": rx_details["generic_name"],
                "class": rx_details["drug_class"]
            })

        # 1. Detect Duplicates (exact generic match or class overlap)
        for new_med in resolved_new:
            for cur_med in resolved_current:
                # Check for exact generic overlap
                if new_med["generic"] == cur_med["generic"]:
                    duplicates.append({
                        "drug": new_med["original"],
                        "matches_with": cur_med["original"],
                        "reason": f"Therapeutic duplicate. The patient is already taking {cur_med['original']} (resolved generic: {cur_med['generic']})."
                    })
                # Check for class overlap (e.g. taking two NSAIDs)
                elif new_med["class"] != "Unknown" and new_med["class"] == cur_med["class"]:
                    duplicates.append({
                        "drug": new_med["original"],
                        "matches_with": cur_med["original"],
                        "reason": f"Therapeutic class overlap. Both drugs are in class '{new_med['class']}' (possibility of additive side effects)."
                    })

        # 2. Check for Drug-Drug Interactions
        # Combine current and new prescription list for DrugBank query
        all_drugs_for_query = list(patient.new_prescription) + list(patient.current_medications)
        raw_interactions = await self.drugbank.get_drug_interactions(all_drugs_for_query)

        # Filter interactions that involve at least one drug from the new prescription
        interactions = []
        new_med_generics = [m["generic"] for m in resolved_new]
        new_med_originals_lower = [m["original"].lower() for m in resolved_new]

        for interaction in raw_interactions:
            # An interaction is relevant if it involves a newly prescribed drug
            involves_new_drug = False
            for drug in interaction["drugs"]:
                drug_lower = drug.lower()
                # Resolve generic for interaction drugs
                rx_info = await self.rxnorm.get_concept_details(drug_lower)
                interaction_generic = rx_info["generic_name"]
                
                if drug_lower in new_med_originals_lower or interaction_generic in new_med_generics:
                    involves_new_drug = True
                    break
            
            if involves_new_drug:
                interactions.append(interaction)

        return {
            "duplicate_detections": duplicates,
            "drug_interactions": interactions,
            "has_issues": len(duplicates) > 0 or len(interactions) > 0
        }
