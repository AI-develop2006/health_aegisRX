import json
import logging
import time
from typing import Optional, Type
from openai import AsyncOpenAI, APIConnectionError, APITimeoutError, APIStatusError
from pydantic import BaseModel
from app.core.config import settings
from app.ai.llm.base import BaseLLM

logger = logging.getLogger("AegisRx.GPTClient")

class GPTClient(BaseLLM):
    def __init__(self):
        self.api_key = settings.OPENAI_API_KEY
        # Only initialize AsyncOpenAI if we have a seemingly real key
        if self.api_key and not self.api_key.startswith("mock"):
            self.client = AsyncOpenAI(api_key=self.api_key)
        else:
            self.client = None
            logger.warning("OPENAI_API_KEY is not configured or is a mock key. GPTClient will operate in Mock Fallback Mode.")

    async def generate_response(
        self, 
        system_prompt: str, 
        user_prompt: str, 
        response_format: Optional[Type[BaseModel]] = None
    ) -> str:
        # Check if in mock fallback mode
        if not self.client:
            return self._generate_mock_fallback(user_prompt)

        try:
            logger.info("Sending request to OpenAI GPT model...")
            start_time = time.time()
            
            # Use structured output if a response format is provided
            kwargs = {
                "model": "gpt-4o",  # Standard production model
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                "temperature": 0.1,
                "timeout": 15.0
            }
            
            if response_format:
                # Use OpenAI's structured outputs via response_format parameter
                kwargs["response_format"] = response_format
                
            response = await self.client.beta.chat.completions.parse(**kwargs)
            latency = (time.time() - start_time) * 1000
            
            choice = response.choices[0]
            logger.info(f"OpenAI GPT response received in {latency:.2f}ms. Finish reason: {choice.finish_reason}")
            
            # Record token usage for auditing (could be attached to request context or logging)
            usage = response.usage
            logger.info(f"Tokens used: Prompt={usage.prompt_tokens}, Completion={usage.completion_tokens}, Total={usage.total_tokens}")
            
            # Return raw message string
            return choice.message.content

        except (APIConnectionError, APITimeoutError) as e:
            logger.error(f"OpenAI connection/timeout error: {str(e)}")
            raise RuntimeError(f"LLM service timeout or connection failure: {str(e)}")
        except APIStatusError as e:
            logger.error(f"OpenAI API returned status error {e.status_code}: {e.message}")
            raise RuntimeError(f"LLM service API error ({e.status_code}): {e.message}")
        except Exception as e:
            logger.error(f"Unexpected error in GPTClient: {str(e)}")
            raise RuntimeError(f"LLM execution failed: {str(e)}")

    def _generate_mock_fallback(self, user_prompt: str) -> str:
        """
        Deterministic Mock LLM generator that parses the user prompt inputs 
        and creates realistic CDSS structured JSON matches.
        """
        logger.info("Executing mock LLM fallback generation...")
        
        user_prompt_lower = user_prompt.lower()
        patient_data = None

        # Try to extract patient clinical profile JSON
        try:
            profile_start = user_prompt.find("--- PATIENT CLINICAL PROFILE ---")
            if profile_start != -1:
                profile_start += len("--- PATIENT CLINICAL PROFILE ---")
                profile_end = user_prompt.find("--- CLINICAL AGENT RULE FINDINGS")
                profile_json_str = user_prompt[profile_start:profile_end].strip()
                patient_data = json.loads(profile_json_str)
        except Exception as e:
            logger.error(f"Mock LLM failed to parse patient profile: {e}")
            patient_data = None

        # Dual-strategy configuration mapping
        if patient_data:
            age = patient_data.get("age", 0)
            is_pregnant = patient_data.get("is_pregnant") is True
            diseases = [d.lower() for d in patient_data.get("active_diseases", [])]
            if "pregnancy" in diseases or "pregnant" in diseases:
                is_pregnant = True
                
            allergies = [a.lower() for a in patient_data.get("allergies", [])]
            current_meds = [m.lower() for m in patient_data.get("current_medications", [])]
            new_prescription = [n.lower() for n in patient_data.get("new_prescription_to_evaluate", [])]
            all_meds = current_meds + new_prescription
            
            has_penicillin_allergy = any("penicillin" in a for a in allergies)
            has_ckd = any("chronic kidney disease" in d or "ckd" in d for d in diseases)
        else:
            # Fall back to naive keyword extraction
            logger.info("No structured patient profile found. Defaulting to naive keyword matching.")
            age = 65 if "age: 65" in user_prompt_lower or "65" in user_prompt_lower else 30
            is_pregnant = "pregnant" in user_prompt_lower or "pregnancy" in user_prompt_lower
            has_penicillin_allergy = "penicillin" in user_prompt_lower
            has_ckd = "chronic kidney disease" in user_prompt_lower or "ckd" in user_prompt_lower
            
            # Simple keyword matching for medications
            new_prescription = []
            current_meds = []
            if "ibuprofen" in user_prompt_lower:
                new_prescription.append("ibuprofen")
            if "amoxicillin" in user_prompt_lower:
                new_prescription.append("amoxicillin")
            if "warfarin" in user_prompt_lower:
                if "prescribed warfarin" in user_prompt_lower or "new_prescription" in user_prompt_lower:
                    new_prescription.append("warfarin")
                else:
                    current_meds.append("warfarin")
            if "metformin" in user_prompt_lower:
                current_meds.append("metformin")
            all_meds = current_meds + new_prescription

        # Defaults
        risk_level = "SAFE"
        confidence_score = 0.95
        reasons = ["No major drug interactions, allergy risks, or disease contraindications detected."]
        detected_drug_interactions = []
        detected_allergy_risks = []
        disease_contraindications = []
        suggested_alternative_medicines = []
        clinical_explanation = "The new prescription appears to be safe and compatible with the patient's current medical history."
        recommended_action = "SAFE_TO_DISPENSE"

        # 1. Drug-drug interactions: Warfarin + Ibuprofen
        if "warfarin" in all_meds and "ibuprofen" in all_meds:
            if "ibuprofen" in new_prescription or "warfarin" in new_prescription or not patient_data:
                risk_level = "HIGH_RISK"
                confidence_score = 0.98
                reasons = ["Severe drug-drug interaction detected between Warfarin and Ibuprofen."]
                detected_drug_interactions.append({
                    "severity": "MAJOR",
                    "drugs": ["Warfarin", "Ibuprofen"],
                    "description": "Ibuprofen can increase bleeding risk when taken with Warfarin by inhibiting platelet aggregation and causing gastric mucosal damage."
                })
                suggested_alternative_medicines.append("Acetaminophen")
                clinical_explanation = "Co-administration of NSAIDs (Ibuprofen) with oral anticoagulants (Warfarin) increases gastrointestinal bleed risks. Prostaglandins inhibition by Ibuprofen compromises the gastric mucosa while Warfarin impairs clotting factors synthesis."
                recommended_action = "DO_NOT_DISPENSE"

        # 2. Allergy conflicts: Penicillin allergy + Amoxicillin
        if has_penicillin_allergy and "amoxicillin" in new_prescription:
            risk_level = "HIGH_RISK"
            confidence_score = 0.99
            reasons = ["Severe allergy conflict: Amoxicillin belongs to penicillin class of antibiotics."]
            detected_allergy_risks.append({
                "allergy": "Penicillin",
                "drug": "Amoxicillin",
                "description": "Amoxicillin is a beta-lactam antibiotic. The patient has a documented allergy to Penicillin, posing an extreme risk of immediate hypersensitivity or anaphylaxis."
            })
            suggested_alternative_medicines.append("Clarithromycin")
            suggested_alternative_medicines.append("Azithromycin")
            clinical_explanation = "The patient is allergic to Penicillin. Amoxicillin shares the beta-lactam ring, indicating cross-reactivity and potential for severe allergic reactions or anaphylaxis."
            recommended_action = "DO_NOT_DISPENSE"

        # 3. Disease contraindications: Chronic Kidney Disease + Ibuprofen
        if has_ckd and "ibuprofen" in new_prescription:
            risk_level = "HIGH_RISK"
            confidence_score = 0.95
            if "Severe drug-drug interaction" in "".join(reasons):
                reasons.append("Disease contraindication: NSAIDs are contraindicated in severe renal impairment.")
            else:
                reasons = ["Disease contraindication: NSAIDs are contraindicated in severe renal impairment."]
            disease_contraindications.append({
                "disease": "Chronic Kidney Disease",
                "drug": "Ibuprofen",
                "description": "Ibuprofen can worsen renal function through renal prostaglandin inhibition, potentially leading to acute kidney injury (AKI) or hyperkalemia."
            })
            if "Acetaminophen" not in suggested_alternative_medicines:
                suggested_alternative_medicines.append("Acetaminophen")
            clinical_explanation = "NSAIDs (Ibuprofen) decrease renal blood flow via afferent arteriolar constriction (prostaglandin synthesis inhibition). In Chronic Kidney Disease, this worsens glomerular filtration rate and risks acute kidney injury."
            recommended_action = "DO_NOT_DISPENSE"

        # 4. Pregnancy risks: Pregnancy + Warfarin
        if is_pregnant and "warfarin" in new_prescription:
            risk_level = "HIGH_RISK"
            confidence_score = 0.99
            reasons = ["Pregnancy contraindication: Warfarin is pregnancy category X."]
            disease_contraindications.append({
                "disease": "Pregnancy",
                "drug": "Warfarin",
                "description": "Warfarin is teratogenic, easily crosses the placenta, and causes fetal warfarin syndrome (skeletal abnormalities, CNS defects, and risk of fatal hemorrhage)."
            })
            suggested_alternative_medicines.append("Low Molecular Weight Heparin (LMWH)")
            clinical_explanation = "Warfarin is contraindicated during pregnancy due to high teratogenic potential and risks of fetal intracranial bleeding."
            recommended_action = "CONTACT_DOCTOR_IMMEDIATELY"

        # 5. Age risks: Age 65+ and Ibuprofen (Beers Criteria warning)
        if age >= 65 and "ibuprofen" in new_prescription:
            if risk_level == "SAFE":
                risk_level = "WARNING"
                confidence_score = 0.90
                reasons = ["Geriatric age-related risk: Beers Criteria warning for NSAIDs in elderly patients."]
                clinical_explanation = "Elderly patients have higher risks of gastrointestinal bleeding and kidney injury from NSAIDs."
                recommended_action = "DOCTOR_REVIEW"

        # Compile final mock response
        mock_response = {
            "risk_level": risk_level,
            "confidence_score": confidence_score,
            "reasons": reasons,
            "detected_drug_interactions": detected_drug_interactions,
            "detected_allergy_risks": detected_allergy_risks,
            "disease_contraindications": disease_contraindications,
            "suggested_alternative_medicines": suggested_alternative_medicines,
            "clinical_explanation": clinical_explanation,
            "recommended_action": recommended_action
        }
        return json.dumps(mock_response)

