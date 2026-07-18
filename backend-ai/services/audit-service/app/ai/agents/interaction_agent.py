import logging
from typing import Dict, Any, List
from app.schemas.patient import PatientContext
from app.ai.agents.base_agent import BaseAgent

logger = logging.getLogger("AegisRx.InteractionAgent")

class InteractionAgent(BaseAgent):
    async def analyze(self, patient: PatientContext) -> Dict[str, Any]:
        """
        Detects duplicate therapeutic medications and queries the drugbank mock
        for drug-drug interactions between new and current medications.
        """
        duplicates = []
        resolved_new = []
        resolved_current = []

        logger.info(f"Interaction Check: Checking new prescription {patient.new_prescription} against current therapies {patient.current_medications} for Patient {patient.patient_id}...")

        # Resolve generic names for new prescription drugs
        for med in patient.new_prescription:
            rx_details = await self.rxnorm.get_concept_details(med)
            gen = rx_details["generic_name"].strip().lower()
            if gen == "paracetamol":
                gen = "acetaminophen"
            resolved_new.append({
                "original": med,
                "generic": gen,
                "class": rx_details["drug_class"]
            })

        # Resolve generic names for current medications
        for med in patient.current_medications:
            rx_details = await self.rxnorm.get_concept_details(med)
            gen = rx_details["generic_name"].strip().lower()
            if gen == "paracetamol":
                gen = "acetaminophen"
            resolved_current.append({
                "original": med,
                "generic": gen,
                "class": rx_details["drug_class"]
            })

        # 1. Detect Duplicates (exact generic match or class overlap)
        for new_med in resolved_new:
            for cur_med in resolved_current:
                # Check for exact generic overlap
                if new_med["generic"] == cur_med["generic"]:
                    desc = f"Therapeutic duplicate. The patient is already taking {cur_med['original']} (resolved generic: {cur_med['generic']})."
                    logger.warning(f"Interaction Check: Alert! Rule 'THERAPEUTIC_DUPLICATE' triggered. {new_med['original']} matches {cur_med['original']}.")
                    duplicates.append({
                        "drug": new_med["original"],
                        "matches_with": cur_med["original"],
                        "reason": f"{new_med['original']} – therapeutic duplicate (generic: {new_med['generic']})",
                        "description": desc
                    })
                # Check for class overlap (e.g. taking two NSAIDs)
                elif new_med["class"] != "Unknown" and new_med["class"] == cur_med["class"]:
                    desc = f"Therapeutic class overlap. Both drugs are in class '{new_med['class']}' (possibility of additive side effects)."
                    logger.warning(f"Interaction Check: Alert! Rule 'THERAPEUTIC_CLASS_OVERLAP' triggered. {new_med['original']} matches {cur_med['original']} on class {new_med['class']}.")
                    duplicates.append({
                        "drug": new_med["original"],
                        "matches_with": cur_med["original"],
                        "reason": f"{new_med['original']} – therapeutic class overlap (class: {new_med['class']})",
                        "description": desc
                    })

        # 2. Check for Drug-Drug Interactions
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
                logger.warning(
                    f"Interaction Check: Alert! Rule 'DRUG_DRUG_INTERACTION' triggered between {interaction['drugs']} "
                    f"with severity {interaction['severity']}. Details: {interaction['description']}"
                )
                drug1 = interaction["drugs"][0] if len(interaction["drugs"]) > 0 else "Unknown"
                drug2 = interaction["drugs"][1] if len(interaction["drugs"]) > 1 else "Unknown"
                interaction_copy = dict(interaction)
                interaction_copy["reason"] = f"{drug1} + {drug2} – drug interaction risk ({interaction['severity']})"
                interactions.append(interaction_copy)

        return {
            "duplicate_detections": duplicates,
            "drug_interactions": interactions,
            "has_issues": len(duplicates) > 0 or len(interactions) > 0
        }

from app.ai.agents.base_agent import AgentResult
from app.ai.knowledge.rxnorm import RxNormMock
from app.ai.knowledge.drugbank import DrugBankMock
from app.ai.knowledge.dailymed import DailyMedMock
from app.ai.knowledge.openfda import OpenFDAMock
from app.ai.knowledge.snomed import SNOMEDMock

async def run_interaction_agent(context: PatientContext) -> AgentResult:
    rxnorm = RxNormMock()
    drugbank = DrugBankMock()
    dailymed = DailyMedMock()
    openfda = OpenFDAMock()
    snomed = SNOMEDMock()
    
    agent = InteractionAgent(rxnorm, drugbank, dailymed, openfda, snomed)
    res = await agent.analyze(context)
    
    issues = [d["description"] for d in res["duplicate_detections"]] + [i["description"] for i in res["drug_interactions"]]
    affected = [d["drug"] for d in res["duplicate_detections"]]
    for i in res["drug_interactions"]:
        affected.extend(i["drugs"])
    affected = list(set(affected))
    
    severities = [i.get("severity", "LOW") for i in res["drug_interactions"]]
    if any(s.upper() == "MAJOR" for s in severities) or len(res["duplicate_detections"]) > 0:
        severity = "HIGH"
    elif any(s.upper() == "MODERATE" for s in severities):
        severity = "MEDIUM"
    elif res["has_issues"]:
        severity = "MEDIUM"
    else:
        severity = "LOW"
        
    return AgentResult(
        name="interaction",
        severity=severity,
        issues=issues,
        affected_medicines=affected,
        meta={
            "duplicate_detections": res["duplicate_detections"],
            "drug_interactions": res["drug_interactions"]
        }
    )

