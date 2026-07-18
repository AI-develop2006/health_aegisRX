import logging
import json
import asyncio
from typing import Dict, Any, List
from datetime import datetime
from app.schemas.patient import PatientContext
from app.ai.agents.base_agent import BaseAgent, AgentResult
from app.ai.services.patient_context import parse_duration_days

logger = logging.getLogger("AegisRx.DoctorAgent")

class DoctorAgent(BaseAgent):
    async def analyze(self, patient: PatientContext) -> Dict[str, Any]:
        """
        Simulates an experienced clinical physician. Evaluates the new prescription
        against the complete historical prescription database and patient conditions.
        """
        logger.info(f"Doctor Check: Performing clinical consultation for Patient {patient.patient_id}...")
        
        complications = []
        severity = "LOW"
        explanation = "The new prescription appears to be safe and compatible with the patient's complete clinical history."
        
        # 1. Deterministic/Failsafe Clinical Check
        now = datetime.now()
        new_generics = []
        for drug in patient.new_prescription:
            info = await self.rxnorm.get_concept_details(drug)
            gen = info["generic_name"].strip().lower()
            if gen == "paracetamol":
                gen = "acetaminophen"
            new_generics.append(gen)
            
        # Check historical prescriptions for duplicates, therapy swaps, and multi-provider transitions
        new_doc_id = patient.doctor_id or "Unknown"
        for rx in patient.all_prescriptions:
            rx_date_str = rx.get("date")
            rx_doc_id = rx.get("doctor_id") or rx.get("doctorName") or "Unknown"
            rx_disease = rx.get("disease", "")
            
            diff_days = None
            rx_date = None
            if rx_date_str:
                try:
                    date_clean = rx_date_str.split("+")[0]
                    rx_date = datetime.fromisoformat(date_clean)
                    diff_days = abs((now - rx_date).days)
                except Exception as e:
                    logger.warning(f"Doctor Agent: Error parsing prescription date '{rx_date_str}': {e}")

            for med in rx.get("medicines", []):
                med_name = med.get("name", "")
                med_dosage = med.get("dosage", "")
                med_info = await self.rxnorm.get_concept_details(med_name)
                med_generic = med_info["generic_name"].strip().lower()
                if med_generic == "paracetamol":
                    med_generic = "acetaminophen"
                med_class = med_info["drug_class"]
                
                dur_str = med.get("duration", "30 days")
                dur_days = parse_duration_days(dur_str)
                
                is_active_overlap = False
                if diff_days is not None and diff_days <= dur_days:
                    is_active_overlap = True
                
                for new_drug, new_gen in zip(patient.new_prescription, new_generics):
                    new_info = await self.rxnorm.get_concept_details(new_drug)
                    new_class = new_info["drug_class"]
                    
                    if is_active_overlap:
                        if new_gen == med_generic:
                            # Direct duplicate!
                            if new_doc_id != "Unknown" and rx_doc_id != "Unknown" and new_doc_id != rx_doc_id:
                                # Different Doctor: Therapy Swap / Doctor shopping warning
                                severity = "HIGH"
                                complications.append(
                                    f"Therapy Swap / Multi-Doctor duplication warning: Patient has an active duplicate therapy "
                                    f"for {new_drug} prescribed by a different physician (Dr. {rx_doc_id}) {diff_days} days ago. "
                                    f"Ensure the patient is instructed to discontinue the old therapy."
                                )
                            else:
                                # Same Doctor: Duplicate overdose hazard
                                severity = "HIGH"
                                complications.append(
                                    f"Active duplicate drug hazard: Patient is already taking {med_name} {med_dosage} "
                                    f"(prescribed {diff_days} days ago). Overlapping therapy risks cumulative high-dosage toxicity/overdose."
                                )
                        elif new_class != "Unknown" and new_class == med_class:
                            # Active Class Overlap
                            severity = "HIGH" if severity != "CRITICAL" else "CRITICAL"
                            complications.append(
                                f"Therapeutic class overlap warning: Prescribing {new_drug} concurrently with "
                                f"active {med_name} (both are '{new_class}') increases systemic complications."
                            )
                    
                    # Indication-based Switch/Transition check (regardless of whether active or completed!)
                    # If the historical disease matches the new indication, but the generic medication is different,
                    # this indicates a therapy swap or treatment case transition.
                    if rx_disease and any(rx_disease.lower() in d.lower() or d.lower() in rx_disease.lower() for d in patient.diseases):
                        if new_gen != med_generic:
                            transition_status = "active overlap" if is_active_overlap else "historical case"
                            complications.append(
                                f"Therapy Transition Detected: Patient is transitioning from {med_name} ({transition_status}, prescribed by Dr. {rx_doc_id}) "
                                f"to {new_drug} for indication '{rx_disease}'. Instruct patient to discontinue the previous therapy if it was not supportive or ineffective."
                            )
                            if severity == "LOW":
                                severity = "MEDIUM"

        # Check drug-disease complications
        diseases_lower = [d.lower() for d in patient.diseases]
        for drug, gen in zip(patient.new_prescription, new_generics):
            # NSAIDs + Ulcer
            if gen in ["warfarin", "aspirin", "ibuprofen"] and any("ulcer" in d or "peptic" in d for d in diseases_lower):
                severity = "HIGH"
                complications.append(
                    f"Clinical Contraindication: Prescribing anticoagulant/NSAID '{drug}' to a patient with active peptic ulcer disease "
                    f"poses an extreme risk of severe gastrointestinal hemorrhage."
                )
            # Metformin + CKD
            if gen == "metformin" and any("kidney" in d or "renal" in d or "ckd" in d for d in diseases_lower):
                severity = "HIGH"
                complications.append(
                    f"Clinical Contraindication: Metformin clearance is reduced in renal impairment. "
                    f"Accumulation risks fatal lactic acidosis."
                )
            # Corticosteroid + Diabetes
            if gen == "prednisone" and any("diabetes" in d or "diabetic" in d for d in diseases_lower):
                severity = "MEDIUM" if severity == "LOW" else severity
                complications.append(
                    f"Clinical Caution: Corticosteroid '{drug}' causes severe glycemic spikes. "
                    f"Requires blood glucose monitoring and dosage adjustments for diabetic patients."
                )

        # De-duplicate complications list
        complications = list(set(complications))
        if complications:
            explanation = "Clinical safety warning: " + "; ".join(complications)
        
        return {
            "complications": complications,
            "severity": severity,
            "explanation": explanation,
            "has_issues": len(complications) > 0
        }

async def run_doctor_agent(context: PatientContext) -> AgentResult:
    from app.ai.knowledge.rxnorm import RxNormMock
    from app.ai.knowledge.drugbank import DrugBankMock
    from app.ai.knowledge.dailymed import DailyMedMock
    from app.ai.knowledge.openfda import OpenFDAMock
    from app.ai.knowledge.snomed import SNOMEDMock
    
    rxnorm = RxNormMock()
    drugbank = DrugBankMock()
    dailymed = DailyMedMock()
    openfda = OpenFDAMock()
    snomed = SNOMEDMock()
    
    agent = DoctorAgent(rxnorm, drugbank, dailymed, openfda, snomed)
    res = await agent.analyze(context)
    
    return AgentResult(
        name="doctor",
        severity=res["severity"],
        issues=res["complications"],
        affected_medicines=context.new_prescription,
        meta={"explanation": res["explanation"], "complications": res["complications"]}
    )
