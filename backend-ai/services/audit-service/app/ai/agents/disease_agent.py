import logging
from typing import Dict, Any, List
from app.schemas.patient import PatientContext
from app.ai.agents.base_agent import BaseAgent

logger = logging.getLogger("AegisRx.DiseaseAgent")

class DiseaseAgent(BaseAgent):
    async def analyze(self, patient: PatientContext) -> Dict[str, Any]:
        """
        Cross-references the patient's active diseases/medical conditions with
        drug contraindications, boxed warnings, and FDA safety data.
        """
        contraindications = []

        if not patient.diseases:
            logger.info(f"Disease Check: Patient {patient.patient_id} has no documented chronic diseases.")
            return {"disease_contraindications": [], "has_issues": False}

        logger.info(f"Disease Check: Checking new drugs {patient.new_prescription} against conditions {patient.diseases} for Patient {patient.patient_id}...")

        # Resolve SNOMED codes for patient diseases
        resolved_diseases = []
        for disease in patient.diseases:
            snomed_code = await self.snomed.get_concept_code(disease)
            resolved_diseases.append({
                "original": disease,
                "snomed_code": snomed_code
            })

        # Evaluate each new drug
        for drug in patient.new_prescription:
            drug_info = await self.rxnorm.get_concept_details(drug)
            drug_generic = drug_info["generic_name"]

            # Fetch DailyMed and OpenFDA warnings
            dm_warnings = await self.dailymed.get_drug_warnings(drug_generic)
            fda_warnings = await self.openfda.get_adverse_events(drug_generic)

            dm_contras = dm_warnings.get("contraindications", [])
            boxed_warning = dm_warnings.get("boxed_warning")
            kidney_risks = fda_warnings.get("kidney_risks", "")
            liver_risks = fda_warnings.get("liver_risks", "")

            for disease in resolved_diseases:
                disease_lower = disease["original"].lower()
                conflict_reason = None
                rule_name = None

                # Keywords mapping clinical conditions to warning flags
                kidney_terms = ["kidney", "renal", "egfr", "nephro", "ckd"]
                liver_terms = ["liver", "hepatic", "cirrhosis", "hepatitis"]
                cardio_terms = ["hypertension", "heart", "cardio", "cabg", "bp"]
                diabetes_terms = ["diabetes", "diabetic", "acidosis", "metformin"]

                # Check 1: Check DailyMed contraindications text
                for contra in dm_contras:
                    contra_lower = contra.lower()
                    if disease_lower in contra_lower:
                        conflict_reason = f"FDA Contraindication: '{contra}'"
                        rule_name = "DAILYMED_CONTRAINDICATION"
                        break
                    
                    # Synonym checks
                    if any(t in disease_lower for t in kidney_terms) and any(w in contra_lower for w in kidney_terms):
                        conflict_reason = f"FDA Contraindication (Renal): '{contra}'"
                        rule_name = "DAILYMED_RENAL_CONTRAINDICATION"
                        break
                    if any(t in disease_lower for t in liver_terms) and any(w in contra_lower for w in liver_terms):
                        conflict_reason = f"FDA Contraindication (Hepatic): '{contra}'"
                        rule_name = "DAILYMED_HEPATIC_CONTRAINDICATION"
                        break

                # Check 2: Check DailyMed Boxed Warning text
                if not conflict_reason and boxed_warning:
                    boxed_lower = boxed_warning.lower()
                    if disease_lower in boxed_lower:
                        conflict_reason = f"FDA Boxed Warning: '{boxed_warning[:150]}...'"
                        rule_name = "DAILYMED_BOXED_WARNING"
                    elif any(t in disease_lower for t in kidney_terms) and any(w in boxed_lower for w in kidney_terms):
                        conflict_reason = f"FDA Boxed Warning (Renal): '{boxed_warning[:150]}...'"
                        rule_name = "DAILYMED_RENAL_BOXED_WARNING"
                    elif any(t in disease_lower for t in liver_terms) and any(w in boxed_lower for w in liver_terms):
                        conflict_reason = f"FDA Boxed Warning (Hepatic): '{boxed_warning[:150]}...'"
                        rule_name = "DAILYMED_HEPATIC_BOXED_WARNING"

                # Check 3: Check OpenFDA Kidney/Liver risks
                if not conflict_reason:
                    if any(t in disease_lower for t in kidney_terms) and kidney_risks and "risk" in kidney_risks.lower():
                        conflict_reason = f"OpenFDA Renal Risk: '{kidney_risks}'"
                        rule_name = "OPENFDA_RENAL_RISK"
                    elif any(t in disease_lower for t in liver_terms) and liver_risks and "risk" in liver_risks.lower():
                        conflict_reason = f"OpenFDA Hepatic Risk: '{liver_risks}'"
                        rule_name = "OPENFDA_HEPATIC_RISK"

                if conflict_reason:
                    logger.warning(
                        f"Disease Check: Alert! Rule '{rule_name}' triggered for drug '{drug}' "
                        f"due to patient condition '{disease['original']}'. Details: {conflict_reason}"
                    )
                    contraindications.append({
                        "disease": disease["original"],
                        "drug": drug,
                        "description": f"Contraindication detected for '{disease['original']}'. {conflict_reason}",
                        "reason": f"{drug} – contraindicated in {disease['original']}",
                        "snomed_code": disease["snomed_code"]
                    })

        return {
            "disease_contraindications": contraindications,
            "has_issues": len(contraindications) > 0
        }
