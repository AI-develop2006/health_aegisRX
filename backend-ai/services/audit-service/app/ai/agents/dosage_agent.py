import logging
from typing import Dict, Any, List
from app.schemas.patient import PatientContext
from app.ai.agents.base_agent import BaseAgent

logger = logging.getLogger("AegisRx.DosageAgent")

class DosageAgent(BaseAgent):
    async def analyze(self, patient: PatientContext) -> Dict[str, Any]:
        """
        Analyzes age-related risks (geriatric/pediatric), weight-based limitations,
        pregnancy categories (A, B, C, D, X), and organ filters.
        """
        warnings = []
        is_high_risk = False

        logger.info(f"Dosage Check: Reviewing drug dosage & demographics for Patient {patient.patient_id}...")

        # 1. Pregnancy Safety Evaluation
        is_pregnant = patient.is_pregnant or any("pregnan" in d.lower() for d in patient.diseases)
        
        for drug in patient.new_prescription:
            drug_info = await self.rxnorm.get_concept_details(drug)
            drug_generic = drug_info["generic_name"]

            # Fetch DailyMed and OpenFDA data
            dm_warnings = await self.dailymed.get_drug_warnings(drug_generic)
            fda_warnings = await self.openfda.get_adverse_events(drug_generic)

            preg_category = dm_warnings.get("pregnancy_category", "Unknown")
            preg_warning = dm_warnings.get("pregnancy_warning", "")
            age_risks = fda_warnings.get("age_risks", "")
            weight_risks = fda_warnings.get("weight_risks", "")
            kidney_risks = fda_warnings.get("kidney_risks", "")
            liver_risks = fda_warnings.get("liver_risks", "")

            # Pregnancy analysis
            if is_pregnant:
                if preg_category in ["X", "D"]:
                    is_high_risk = True
                    desc = f"Pregnancy Category {preg_category}: Contraindicated during pregnancy. {preg_warning}"
                    logger.warning(f"Dosage Check: Alert! Rule 'PREGNANCY_CRITICAL' triggered for {drug}.")
                    warnings.append({
                        "type": "PREGNANCY_RISK",
                        "drug": drug,
                        "severity": "HIGH_RISK",
                        "description": desc,
                        "reason": f"{drug} – contraindicated in pregnancy (Category {preg_category})"
                    })
                elif preg_category == "C":
                    desc = f"Pregnancy Category C: Use only if potential benefit outweighs risk. {preg_warning}"
                    logger.warning(f"Dosage Check: Alert! Rule 'PREGNANCY_WARNING' triggered for {drug}.")
                    warnings.append({
                        "type": "PREGNANCY_RISK",
                        "drug": drug,
                        "severity": "WARNING",
                        "description": desc,
                        "reason": f"{drug} – warning in pregnancy (Category C)"
                    })

            # 2. Age-Related Safety Evaluation
            if patient.age >= 65:
                if age_risks and ("geriatric" in age_risks.lower() or "elderly" in age_risks.lower()):
                    desc = f"Geriatric safety warning (Age {patient.age}): {age_risks}"
                    logger.warning(f"Dosage Check: Alert! Rule 'GERIATRIC_RISK' triggered for {drug}.")
                    warnings.append({
                        "type": "GERIATRIC_RISK",
                        "drug": drug,
                        "severity": "WARNING",
                        "description": desc,
                        "reason": f"{drug} – geriatric safety precaution (Age {patient.age})"
                    })
            elif patient.age < 18:
                if drug_generic == "aspirin":
                    is_high_risk = True
                    logger.warning(f"Dosage Check: Alert! Rule 'PEDIATRIC_REYES_CRITICAL' triggered for Aspirin.")
                    warnings.append({
                        "type": "PEDIATRIC_RISK",
                        "drug": drug,
                        "severity": "HIGH_RISK",
                        "description": "Pediatric safety warning: Aspirin is contraindicated in children/adolescents due to risk of Reye's syndrome.",
                        "reason": f"{drug} – contraindicated in pediatrics (Reye's syndrome risk)"
                    })
                elif age_risks and "pediatric" in age_risks.lower():
                    desc = f"Pediatric warning (Age {patient.age}): {age_risks}"
                    logger.warning(f"Dosage Check: Alert! Rule 'PEDIATRIC_WARNING' triggered for {drug}.")
                    warnings.append({
                        "type": "PEDIATRIC_RISK",
                        "drug": drug,
                        "severity": "WARNING",
                        "description": desc,
                        "reason": f"{drug} – pediatric safety warning (Age {patient.age})"
                    })

            # 3. Weight-Based Limitations
            if patient.weight is not None:
                if patient.weight < 50.0:
                    if drug_generic == "acetaminophen":
                        logger.warning(f"Dosage Check: Alert! Rule 'LOW_WEIGHT_ACETAMINOPHEN' triggered.")
                        warnings.append({
                            "type": "WEIGHT_RISK",
                            "drug": drug,
                            "severity": "WARNING",
                            "description": f"Low body weight warning ({patient.weight}kg): Risk of acetaminophen hepatotoxicity. Limit daily dose to 2g-3g.",
                            "reason": f"{drug} – weight-based limit precaution ({patient.weight}kg)"
                        })
                    elif weight_risks and "weight-based" in weight_risks.lower():
                        logger.warning(f"Dosage Check: Alert! Rule 'WEIGHT_LIMIT' triggered for {drug}.")
                        warnings.append({
                            "type": "WEIGHT_RISK",
                            "drug": drug,
                            "severity": "WARNING",
                            "description": f"Weight-based warning: {weight_risks}",
                            "reason": f"{drug} – weight-based safety warning"
                        })

            # 4. Kidney and Liver organ filter warnings
            has_kidney_disease = any(term in "".join(patient.diseases).lower() for term in ["kidney", "renal", "ckd"])
            has_liver_disease = any(term in "".join(patient.diseases).lower() for term in ["liver", "hepatic", "cirrhosis", "hepatitis"])

            if has_kidney_disease and kidney_risks and "risk" in kidney_risks.lower():
                logger.warning(f"Dosage Check: Alert! Rule 'ORGAN_KIDNEY_FILTER' triggered for {drug}.")
                warnings.append({
                    "type": "ORGAN_RISK_KIDNEY",
                    "drug": drug,
                    "severity": "WARNING",
                    "description": f"Renal filter alert: {kidney_risks}",
                    "reason": f"{drug} – renal filtration caution"
                })
                
            if has_liver_disease and liver_risks and "risk" in liver_risks.lower():
                logger.warning(f"Dosage Check: Alert! Rule 'ORGAN_LIVER_FILTER' triggered for {drug}.")
                warnings.append({
                    "type": "ORGAN_RISK_LIVER",
                    "drug": drug,
                    "severity": "WARNING",
                    "description": f"Hepatic filter alert: {liver_risks}",
                    "reason": f"{drug} – hepatic metabolism caution"
                })

        return {
            "dosage_and_demographic_warnings": warnings,
            "has_high_risk": is_high_risk,
            "has_issues": len(warnings) > 0
        }
