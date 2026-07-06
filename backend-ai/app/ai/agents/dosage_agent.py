from typing import Dict, Any, List
from app.schemas.patient import PatientContext
from app.ai.agents.base_agent import BaseAgent

class DosageAgent(BaseAgent):
    async def analyze(self, patient: PatientContext) -> Dict[str, Any]:
        """
        Analyzes age-related risks (geriatric/pediatric), weight-based limitations,
        pregnancy categories (A, B, C, D, X), and organ filters.
        """
        warnings = []
        is_high_risk = False

        # 1. Pregnancy Safety Evaluation
        # Determine if pregnant (via boolean field or diseases)
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
                    warnings.append({
                        "type": "PREGNANCY_RISK",
                        "drug": drug,
                        "severity": "HIGH_RISK",
                        "description": f"Pregnancy Category {preg_category}: Contraindicated during pregnancy. {preg_warning}"
                    })
                elif preg_category == "C":
                    warnings.append({
                        "type": "PREGNANCY_RISK",
                        "drug": drug,
                        "severity": "WARNING",
                        "description": f"Pregnancy Category C: Use only if potential benefit outweighs risk. {preg_warning}"
                    })

            # 2. Age-Related Safety Evaluation
            if patient.age >= 65:
                # Beers Criteria or Geriatric warnings
                if age_risks and "geriatric" in age_risks.lower() or "elderly" in age_risks.lower():
                    warnings.append({
                        "type": "GERIATRIC_RISK",
                        "drug": drug,
                        "severity": "WARNING",
                        "description": f"Geriatric safety warning (Age {patient.age}): {age_risks}"
                    })
            elif patient.age < 18:
                # Pediatric warnings (e.g. Aspirin Reye's syndrome)
                if drug_generic == "aspirin":
                    is_high_risk = True
                    warnings.append({
                        "type": "PEDIATRIC_RISK",
                        "drug": drug,
                        "severity": "HIGH_RISK",
                        "description": "Pediatric safety warning: Aspirin is contraindicated in children/adolescents due to risk of Reye's syndrome."
                    })
                elif age_risks and "pediatric" in age_risks.lower():
                    warnings.append({
                        "type": "PEDIATRIC_RISK",
                        "drug": drug,
                        "severity": "WARNING",
                        "description": f"Pediatric warning (Age {patient.age}): {age_risks}"
                    })

            # 3. Weight-Based Limitations
            if patient.weight is not None:
                if patient.weight < 50.0:
                    if drug_generic == "acetaminophen":
                        warnings.append({
                            "type": "WEIGHT_RISK",
                            "drug": drug,
                            "severity": "WARNING",
                            "description": f"Low body weight warning ({patient.weight}kg): Risk of acetaminophen hepatotoxicity. Limit daily dose to 2g-3g."
                        })
                    elif weight_risks and "weight-based" in weight_risks.lower():
                        warnings.append({
                            "type": "WEIGHT_RISK",
                            "drug": drug,
                            "severity": "WARNING",
                            "description": f"Weight-based warning: {weight_risks}"
                        })

            # 4. Kidney and Liver organ filter warnings (if patient has kidney/liver disease)
            has_kidney_disease = any(term in "".join(patient.diseases).lower() for term in ["kidney", "renal", "ckd"])
            has_liver_disease = any(term in "".join(patient.diseases).lower() for term in ["liver", "hepatic", "cirrhosis", "hepatitis"])

            if has_kidney_disease and kidney_risks and "risk" in kidney_risks.lower():
                warnings.append({
                    "type": "ORGAN_RISK_KIDNEY",
                    "drug": drug,
                    "severity": "WARNING",
                    "description": f"Renal filter alert: {kidney_risks}"
                })
                
            if has_liver_disease and liver_risks and "risk" in liver_risks.lower():
                warnings.append({
                    "type": "ORGAN_RISK_LIVER",
                    "drug": drug,
                    "severity": "WARNING",
                    "description": f"Hepatic filter alert: {liver_risks}"
                })

        return {
            "dosage_and_demographic_warnings": warnings,
            "has_high_risk": is_high_risk,
            "has_issues": len(warnings) > 0
        }
