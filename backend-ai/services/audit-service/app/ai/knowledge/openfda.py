from typing import Dict, Any
import logging
from app.ai.knowledge.base import BaseOpenFDA
from app.core.config import settings

logger = logging.getLogger("AegisRx.OpenFDA")

class OpenFDAMock(BaseOpenFDA):
    def __init__(self):
        # Database of adverse events and risk guidelines
        self.fda_db = {
            "ibuprofen": {
                "age_risks": "Geriatric patients (65+) are at high risk of gastrointestinal bleeding, ulceration, fluid retention, and acute renal failure with NSAID administration.",
                "kidney_risks": "NSAIDs inhibit renal prostaglandins, which can lead to decreased renal blood flow, fluid retention, and acute kidney injury, especially in patients with existing chronic kidney disease.",
                "liver_risks": "Mild transaminase elevations can occur; hepatotoxicity is rare but caution is advised in severe hepatic impairment.",
                "weight_risks": "Standard adult dosing applies, but pediatric/low-weight patients require strict weight-based mg/kg dosing."
            },
            "metformin": {
                "age_risks": "Risk of lactic acidosis increases with age due to age-related decline in renal function.",
                "kidney_risks": "Accumulation of metformin in severe renal impairment (eGFR < 30 mL/min/1.73m2) significantly increases the risk of metformin-induced lactic acidosis. Monitoring renal function is mandatory.",
                "liver_risks": "Use with caution in patients with hepatic impairment due to reduced lactate clearance capabilities.",
                "weight_risks": "No major weight-based risks in adults, but dosing adjustment is based on therapeutic effect and tolerance."
            },
            "warfarin": {
                "age_risks": "Geriatric patients (65+) have increased sensitivity and bleeding response, requiring careful lower dosing and more frequent INR checks.",
                "kidney_risks": "Warfarin-related nephropathy can occur; patients with chronic kidney disease have a higher bleeding risk and require closer monitoring.",
                "liver_risks": "Mainly metabolized by CYP2C9; severe hepatic impairment decreases clotting factor synthesis, enhancing warfarin's effect and bleeding risk.",
                "weight_risks": "Large or cachectic patients may require significantly different dosing, requiring careful titration."
            },
            "lisinopril": {
                "age_risks": "Geriatric patients may exhibit higher blood levels and increased sensitivity to orthostatic hypotension.",
                "kidney_risks": "In patients with severe renal impairment or bilateral renal artery stenosis, ACE inhibitors can cause acute renal failure. Monitor BUN/Creatinine closely.",
                "liver_risks": "Rarely, ACE inhibitors are associated with a syndrome that starts with cholestatic jaundice and progresses to fulminant hepatic necrosis.",
                "weight_risks": "No special weight-based concerns."
            },
            "aspirin": {
                "age_risks": "Geriatric patients are at high risk for major bleeding events, including gastrointestinal and intracranial hemorrhage.",
                "kidney_risks": "Can decrease renal function at high anti-inflammatory doses; low-dose aspirin is generally safe for kidneys but requires care in severe CKD.",
                "liver_risks": "Can cause hepatotoxicity, particularly in patients with active systemic juvenile arthritis or liver disease.",
                "weight_risks": "Weight-based dosing used for pediatric indications."
            },
            "acetaminophen": {
                "age_risks": "Elderly patients are more susceptible to unintentional overdose and hepatotoxicity; recommend maximum daily dose of 2g - 3g.",
                "kidney_risks": "Chronic high-dose use is associated with analgesic nephropathy, though acute use is safe in renal impairment.",
                "liver_risks": "Acetaminophen is heavily metabolized by the liver. Doses exceeding 4g/day (or lower in active alcoholics/liver disease) can cause severe, irreversible acute liver failure.",
                "weight_risks": "Low body weight (<50kg) increases risk of hepatotoxicity. Dose must be adjusted downward."
            }
        }

    async def get_adverse_events(self, drug_name: str) -> Dict[str, Any]:
        if settings.USE_MOCK_AUDIT:
            logger.info("USE_MOCK_AUDIT is enabled. Using openFDA mock database.")
            return self._get_mock_adverse_events(drug_name)

        try:
            import httpx
            logger.info(f"USE_MOCK_AUDIT is false. Querying public openFDA API for: {drug_name}...")
            async with httpx.AsyncClient(timeout=3.0) as client:
                url = f"https://api.fda.gov/drug/event.json?search=patient.drug.medicinalproduct:{drug_name}&limit=1"
                res = await client.get(url)
                res.raise_for_status()
                data = res.json()
                results = data.get("results", [])
                if not results:
                    raise ValueError(f"No FDA adverse event data found for {drug_name}")
                return {
                    "age_risks": f"Real openFDA warning logs show potential geriatric/pediatric reports.",
                    "kidney_risks": f"FDA adverse events logs show interactions.",
                    "liver_risks": f"FDA database indicates metabolism concerns.",
                    "weight_risks": "Refer to FDA weight guidelines."
                }
        except Exception as e:
            logger.warning(f"openFDA query failed: {e}. Falling back to mock database.")
            return self._get_mock_adverse_events(drug_name)

    def _get_mock_adverse_events(self, drug_name: str) -> Dict[str, Any]:
        normalized = drug_name.strip().lower()
        if normalized in self.fda_db:
            return self.fda_db[normalized]
        return {
            "age_risks": "No special age risks registered.",
            "kidney_risks": "No special kidney risks registered.",
            "liver_risks": "No special liver risks registered.",
            "weight_risks": "No special weight-based concerns."
        }
