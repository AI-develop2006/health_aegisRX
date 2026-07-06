from typing import Dict, Any
from app.ai.knowledge.base import BaseDailyMed

class DailyMedMock(BaseDailyMed):
    def __init__(self):
        # Mock label and warnings database
        self.warnings_db = {
            "ibuprofen": {
                "pregnancy_category": "C",  # Upgraded to D in 3rd trimester
                "pregnancy_warning": "NSAIDs should be avoided starting at 30 weeks of gestation (3rd trimester) due to risk of premature closure of fetal ductus arteriosus.",
                "contraindications": [
                    "Active gastrointestinal bleeding",
                    "Severe renal impairment",
                    "Coronary artery bypass graft (CABG) surgery peri-operative pain"
                ],
                "boxed_warning": "Cardiovascular Risk: NSAIDs may cause an increased risk of serious cardiovascular thrombotic events. Gastrointestinal Risk: NSAIDs cause an increased risk of serious gastrointestinal adverse events including bleeding and perforation."
            },
            "amoxicillin": {
                "pregnancy_category": "B",
                "pregnancy_warning": "Generally considered safe during pregnancy when clinically indicated.",
                "contraindications": [
                    "Hypersensitivity to penicillin class of antibiotics or other beta-lactams"
                ],
                "boxed_warning": None
            },
            "warfarin": {
                "pregnancy_category": "X",
                "pregnancy_warning": "Contraindicated in pregnant women (except in women with mechanical heart valves) because it passes the placental barrier and causes fatal hemorrhage and birth defects.",
                "contraindications": [
                    "Pregnancy",
                    "Active hemorrhage or bleeding tendencies",
                    "Severe, uncontrolled hypertension"
                ],
                "boxed_warning": "Bleeding Risk: Warfarin can cause major or fatal bleeding. Perform regular INR monitoring."
            },
            "metformin": {
                "pregnancy_category": "B",
                "pregnancy_warning": "Generally considered safe, but insulin is preferred for gestational diabetes.",
                "contraindications": [
                    "Severe renal impairment (eGFR < 30 mL/min/1.73m2)",
                    "Acute or chronic metabolic acidosis (including diabetic ketoacidosis)"
                ],
                "boxed_warning": "Lactic Acidosis: Metformin accumulation can cause lactic acidosis, which is a rare but serious metabolic complication."
            },
            "lisinopril": {
                "pregnancy_category": "D",
                "pregnancy_warning": "Contraindicated. Drugs that act on the renin-angiotensin system can cause injury and death to the developing fetus when used in pregnancy.",
                "contraindications": [
                    "History of angioedema related to previous ACE inhibitor treatment",
                    "Co-administration with aliskiren in patients with diabetes"
                ],
                "boxed_warning": "Fetal Toxicity: When pregnancy is detected, discontinue lisinopril as soon as possible."
            },
            "aspirin": {
                "pregnancy_category": "D",
                "pregnancy_warning": "Avoid in the third trimester of pregnancy due to risks of bleeding and premature closure of fetal ductus arteriosus.",
                "contraindications": [
                    "Bleeding disorders (e.g. hemophilia)",
                    "Active peptic ulcer disease",
                    "Asthma with nasal polyps"
                ],
                "boxed_warning": None
            },
            "acetaminophen": {
                "pregnancy_category": "B",
                "pregnancy_warning": "Considered the analgesic of choice during pregnancy, but should be used at the lowest effective dose.",
                "contraindications": [
                    "Severe hepatic impairment or active liver disease",
                    "Hypersensitivity to acetaminophen"
                ],
                "boxed_warning": "Severe Liver Injury: Acetaminophen is associated with cases of acute liver failure, at times resulting in liver transplant or death."
            }
        }

    async def get_drug_warnings(self, drug_name: str) -> Dict[str, Any]:
        normalized = drug_name.strip().lower()
        if normalized in self.warnings_db:
            return self.warnings_db[normalized]
        return {
            "pregnancy_category": "Unknown",
            "pregnancy_warning": "Safety in pregnancy not established. Consult clinician.",
            "contraindications": [],
            "boxed_warning": None
        }
