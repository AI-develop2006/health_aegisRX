import asyncio
import logging
import time
import json
from uuid import uuid4, UUID
from typing import Dict, Any, List, Optional
from datetime import datetime

from app.core.config import settings
from app.schemas.patient import PatientContext
from app.schemas.response import (
    PrescriptionSafetyAnalysis, 
    AuditLogEntry, 
    DrugInteractionDetail, 
    AllergyRiskDetail, 
    DiseaseContraindicationDetail
)
from app.ai.knowledge import (
    RxNormMock, 
    DrugBankMock, 
    DailyMedMock, 
    OpenFDAMock, 
    SNOMEDMock
)
from app.ai.agents import (
    InteractionAgent, 
    AllergyAgent, 
    DiseaseAgent, 
    DosageAgent, 
    RecommendationAgent
)
from app.ai.llm import GPTClient, MedGemmaClient, GeminiClient, PromptBuilder
from app.ai.services.patient_context import PatientContextService

logger = logging.getLogger("AegisRx.AIService")

# In-memory audit database
audit_store: Dict[str, AuditLogEntry] = {}

class AIService:
    def __init__(self):
        # 1. Initialize Medical Knowledge Layer
        self.rxnorm = RxNormMock()
        self.drugbank = DrugBankMock()
        self.dailymed = DailyMedMock()
        self.openfda = OpenFDAMock()
        self.snomed = SNOMEDMock()

        # 2. Initialize Safety Agents
        self.interaction_agent = InteractionAgent(self.rxnorm, self.drugbank, self.dailymed, self.openfda, self.snomed)
        self.allergy_agent = AllergyAgent(self.rxnorm, self.drugbank, self.dailymed, self.openfda, self.snomed)
        self.disease_agent = DiseaseAgent(self.rxnorm, self.drugbank, self.dailymed, self.openfda, self.snomed)
        self.dosage_agent = DosageAgent(self.rxnorm, self.drugbank, self.dailymed, self.openfda, self.snomed)
        self.recommendation_agent = RecommendationAgent(self.rxnorm, self.drugbank, self.dailymed, self.openfda, self.snomed)

        # 3. Initialize LLM Client
        provider = settings.LLM_PROVIDER.lower()
        if provider == "gpt":
            self.llm = GPTClient()
        elif provider == "medgemma":
            self.llm = MedGemmaClient()
        elif provider == "gemini":
            self.llm = GeminiClient()
        elif provider == "hybrid":
            self.medgemma_client = MedGemmaClient()
            self.gemini_client = GeminiClient()
            self.llm = self.gemini_client
        else:
            logger.warning(f"Unknown LLM Provider '{provider}'. Defaulting to GPTClient.")
            self.llm = GPTClient()

    async def analyze_prescription(self, patient: PatientContext) -> PrescriptionSafetyAnalysis:
        start_time = time.time()
        analysis_id = uuid4()
        logger.info(f"Starting safety analysis run {analysis_id} for Patient {patient.patient_id}")

        # Step 1: Preprocess patient context
        cleaned_patient = PatientContextService.preprocess_context(patient)

        # Step 2: Run sub-agents in parallel to check clinical rules
        logger.info("Executing clinical safety agents in parallel...")
        interaction_task = self.interaction_agent.analyze(cleaned_patient)
        allergy_task = self.allergy_agent.analyze(cleaned_patient)
        disease_task = self.disease_agent.analyze(cleaned_patient)
        dosage_task = self.dosage_agent.analyze(cleaned_patient)

        agent_results = await asyncio.gather(
            interaction_task,
            allergy_task,
            disease_task,
            dosage_task
        )

        interaction_res, allergy_res, disease_res, dosage_res = agent_results
        logger.info("Clinical agents successfully finished execution.")

        # Step 3: Compile rule-based safety overrides
        clinical_overrides = self.recommendation_agent.compile_clinical_overrides(
            interaction_res, allergy_res, disease_res, dosage_res
        )

        # Step 4: Gather fact retrievals to provide context to LLM
        knowledge_facts = await self._gather_knowledge_facts(cleaned_patient)

        # Step 5: Build prompt
        system_prompt = PromptBuilder.build_system_prompt()
        user_prompt = PromptBuilder.build_user_prompt(
            cleaned_patient,
            {
                "interactions": interaction_res,
                "allergies": allergy_res,
                "diseases": disease_res,
                "demographics": dosage_res
            },
            knowledge_facts
        )
        
        logger.info("Built prompts for LLM call.")
        logger.debug(f"System Prompt:\n{system_prompt}\nUser Prompt:\n{user_prompt}")

        # Step 6: Call LLM with error handling, timeouts, and fallback
        raw_llm_response = ""
        parsed_llm_analysis = None
        llm_error_flag = False
        provider = settings.LLM_PROVIDER.lower()
        
        llm_mode = "mock"
        llm_reason = None

        try:
            if provider == "hybrid":
                logger.info("Hybrid AI Mode: Running local MedGemma inference first...")
                medgemma_prompt = (
                    "You are a clinical NLP model. Analyze the following patient case and medication request. "
                    "Extract clinical summaries and highlight potential drug interactions, allergies, or contraindications."
                )
                medgemma_res = await self.medgemma_client.safe_generate_response(medgemma_prompt, user_prompt)
                medgemma_summary = medgemma_res["content"]
                
                llm_mode = medgemma_res["mode"]
                if medgemma_res["reason"]:
                    llm_reason = f"MedGemma: {medgemma_res['reason']}"

                hybrid_user_prompt = (
                    f"{user_prompt}\n\n"
                    f"--- Local MedGemma Clinical Analysis ---\n"
                    f"{medgemma_summary}\n"
                    f"-----------------------------------------\n"
                    f"Using the local MedGemma analysis and your own medical reasoning, perform the final safety analysis."
                )
                
                logger.info("Hybrid AI Mode: Calling Gemini cloud model for final safety determination...")
                gemini_res = await self.gemini_client.safe_generate_response(system_prompt, hybrid_user_prompt)
                raw_llm_response = gemini_res["content"]
                
                # If either is mock, overall is mock
                if gemini_res["mode"] == "mock":
                    llm_mode = "mock"
                    gem_reason = gemini_res["reason"] or "Gemini fallback"
                    llm_reason = f"{llm_reason or ''}; Gemini: {gem_reason}".strip("; ")
                else:
                    if llm_mode == "real":
                        llm_mode = "real"
            else:
                res = await self.llm.safe_generate_response(system_prompt, user_prompt)
                raw_llm_response = res["content"]
                llm_mode = res["mode"]
                llm_reason = res["reason"]
            
            # Remove any possible markdown blocks around JSON (like ```json ... ```)
            cleaned_json = raw_llm_response.strip()
            if cleaned_json.startswith("```"):
                lines = cleaned_json.split("\n")
                if lines[0].startswith("```"):
                    lines = lines[1:]
                if lines[-1].startswith("```"):
                    lines = lines[:-1]
                cleaned_json = "\n".join(lines).strip()

            parsed_json = json.loads(cleaned_json)
            
            # Map lists to schema models
            interactions_list = [
                DrugInteractionDetail(**i) for i in parsed_json.get("detected_drug_interactions", [])
            ]
            allergies_list = [
                AllergyRiskDetail(**a) for a in parsed_json.get("detected_allergy_risks", [])
            ]
            diseases_list = [
                DiseaseContraindicationDetail(**d) for d in parsed_json.get("disease_contraindications", [])
            ]

            parsed_llm_analysis = PrescriptionSafetyAnalysis(
                analysis_id=analysis_id,
                risk_level=parsed_json.get("risk_level", "SAFE"),
                confidence_score=parsed_json.get("confidence_score", 0.90),
                reasons=parsed_json.get("reasons", []),
                detected_drug_interactions=interactions_list,
                detected_allergy_risks=allergies_list,
                disease_contraindications=diseases_list,
                suggested_alternative_medicines=parsed_json.get("suggested_alternative_medicines", []),
                clinical_explanation=parsed_json.get("clinical_explanation", "Analysis completed."),
                recommended_action=parsed_json.get("recommended_action", "SAFE_TO_DISPENSE"),
                metadata={"provider": settings.LLM_PROVIDER, "fallback_mode": False},
                backend_mode=llm_mode,
                backend_reason=llm_reason
            )

            # Map the RiskSnapshot fields
            parsed_llm_analysis.risk_band = parsed_json.get("risk_band") or parsed_json.get("riskBand") or (
                "LOW" if parsed_llm_analysis.risk_level == "SAFE" else
                "MEDIUM" if parsed_llm_analysis.risk_level == "WARNING" else "CRITICAL"
            )
            parsed_llm_analysis.risk_score = int(parsed_json.get("risk_score") or parsed_json.get("riskScore") or (
                10 if parsed_llm_analysis.risk_band == "LOW" else
                50 if parsed_llm_analysis.risk_band == "MEDIUM" else 95
            ))
            parsed_llm_analysis.recommendation = parsed_json.get("recommendation") or parsed_llm_analysis.clinical_explanation[:120]

        except Exception as e:
            logger.error(f"LLM execution, JSON parsing, or timeout failed: {str(e)}. Falling back to deterministic rules.")
            llm_error_flag = True
            raw_llm_response = f"ERROR_FALLBACK: {str(e)}"
            
            # Formulate response based purely on clinical rules engine
            parsed_llm_analysis = PrescriptionSafetyAnalysis(
                analysis_id=analysis_id,
                risk_level=clinical_overrides["risk_level"],
                confidence_score=clinical_overrides["confidence_score"],
                reasons=clinical_overrides["reasons"],
                detected_drug_interactions=[
                    DrugInteractionDetail(**i) for i in interaction_res.get("drug_interactions", [])
                ],
                detected_allergy_risks=[
                    AllergyRiskDetail(**a) for a in allergy_res.get("allergy_conflicts", [])
                ],
                disease_contraindications=[
                    DiseaseContraindicationDetail(**d) for d in disease_res.get("disease_contraindications", [])
                ],
                suggested_alternative_medicines=clinical_overrides["suggested_alternative_medicines"],
                clinical_explanation=(
                    "Failsafe Mode active (LLM timeout or connection failure). Reasoning generated via the clinical rule engine. "
                    "Detected conflicts present in allergies, diseases, or drug interactions."
                ) if clinical_overrides["risk_level"] != "SAFE" else "Failsafe Mode active (LLM timeout or connection failure). No safety rules violated.",
                recommended_action=clinical_overrides["recommended_action"],
                metadata={"provider": "rules_engine_fallback", "fallback_mode": True, "error": str(e)},
                backend_mode="mock",
                backend_reason=f"LLM parsing or unexpected error: {str(e)}"
            )

            # Map the RiskSnapshot fields for fallback
            parsed_llm_analysis.risk_band = (
                "LOW" if parsed_llm_analysis.risk_level == "SAFE" else
                "MEDIUM" if parsed_llm_analysis.risk_level == "WARNING" else "CRITICAL"
            )
            parsed_llm_analysis.risk_score = (
                10 if parsed_llm_analysis.risk_band == "LOW" else
                50 if parsed_llm_analysis.risk_band == "MEDIUM" else 95
            )
            parsed_llm_analysis.recommendation = "Safety Warning: rules-engine flagged potential risks." if parsed_llm_analysis.risk_band != "LOW" else "Prescription evaluated as safe by clinical rules."

        # Step 7: Apply Clinical Safety Overrides (Safe-by-design policy)
        # Even if LLM says SAFE, if rules engine found HIGH_RISK or WARNING, upgrade the rating
        if not llm_error_flag:
            safety_triggered = False
            
            # Override to HIGH_RISK if rule engine found HIGH_RISK
            if clinical_overrides["risk_level"] == "HIGH_RISK" and parsed_llm_analysis.risk_level != "HIGH_RISK":
                parsed_llm_analysis.risk_level = "HIGH_RISK"
                parsed_llm_analysis.recommended_action = clinical_overrides["recommended_action"]
                parsed_llm_analysis.risk_band = "CRITICAL"
                parsed_llm_analysis.risk_score = 95
                parsed_llm_analysis.recommendation = "Clinical override triggered: High-risk patient safety conflict detected."
                safety_triggered = True
                logger.warning("Clinical Policy Override: Risk level upgraded to HIGH_RISK.")
                
            # Override to WARNING if rules engine found WARNING and LLM said SAFE
            elif clinical_overrides["risk_level"] == "WARNING" and parsed_llm_analysis.risk_level == "SAFE":
                parsed_llm_analysis.risk_level = "WARNING"
                parsed_llm_analysis.recommended_action = clinical_overrides["recommended_action"]
                parsed_llm_analysis.risk_band = "MEDIUM"
                parsed_llm_analysis.risk_score = 60
                parsed_llm_analysis.recommendation = "Clinical override triggered: Medium-risk patient safety caution detected."
                safety_triggered = True
                logger.warning("Clinical Policy Override: Risk level upgraded to WARNING.")

            if safety_triggered:
                # Merge clinical reasons not mentioned by LLM
                for r in clinical_overrides["reasons"]:
                    if r not in parsed_llm_analysis.reasons:
                        parsed_llm_analysis.reasons.append(r)
                parsed_llm_analysis.clinical_explanation += (
                    " [Clinical Override Applied: Risk level has been upgraded for safety based on CDSS rules.]"
                )
                
                # Merge alternatives
                for alt in clinical_overrides["suggested_alternative_medicines"]:
                    if alt not in parsed_llm_analysis.suggested_alternative_medicines:
                        parsed_llm_analysis.suggested_alternative_medicines.append(alt)

        # Scan all list items to dynamically compile flagged_medicines and enforce reasons
        flagged = set()
        for item in parsed_llm_analysis.detected_drug_interactions:
            flagged.update(item.drugs)
            if not item.reason:
                item.reason = f"{item.drugs[0]} + {item.drugs[1]} – interaction risk ({item.severity})"
        for item in parsed_llm_analysis.detected_allergy_risks:
            flagged.add(item.drug)
            if not item.reason:
                item.reason = f"{item.drug} – allergy risk ({item.allergy})"
        for item in parsed_llm_analysis.disease_contraindications:
            flagged.add(item.drug)
            if not item.reason:
                item.reason = f"{item.drug} – contraindicated in {item.disease}"
                
        parsed_llm_analysis.flagged_medicines = list(flagged)

        # Compute total latency
        latency_ms = (time.time() - start_time) * 1000
        parsed_llm_analysis.metadata["latency_ms"] = latency_ms
        logger.info(f"Prescription safety analysis completed in {latency_ms:.2f}ms. Outcome: {parsed_llm_analysis.risk_level}")

        # Save to Audit Log Store
        audit_entry = AuditLogEntry(
            analysis_id=analysis_id,
            timestamp=datetime.utcnow().isoformat() + "Z",
            patient_context=patient.model_dump(),
            analysis_result=parsed_llm_analysis,
            raw_prompt_system=system_prompt,
            raw_prompt_user=user_prompt,
            raw_llm_response=raw_llm_response,
            latency_ms=latency_ms,
            token_usage={"prompt_tokens": 0, "completion_tokens": 0, "total_tokens": 0}  # Mocked / logged in clients
        )
        audit_store[str(analysis_id)] = audit_entry

        return parsed_llm_analysis

    async def _gather_knowledge_facts(self, patient: PatientContext) -> List[str]:
        """Queries the Medical Knowledge Layer to gather facts for prompt context."""
        facts = []
        for med in patient.new_prescription:
            rx_info = await self.rxnorm.get_concept_details(med)
            generic = rx_info["generic_name"]

            # Pregnancy
            dm_warn = await self.dailymed.get_drug_warnings(generic)
            facts.append(f"DailyMed {generic.upper()} pregnancy category: {dm_warn['pregnancy_category']}. Warning: {dm_warn['pregnancy_warning']}")
            
            # Contraindications
            for c in dm_warn.get("contraindications", []):
                facts.append(f"DailyMed {generic.upper()} Contraindication: {c}")

            # OpenFDA
            fda_warn = await self.openfda.get_adverse_events(generic)
            if fda_warn["age_risks"] and "no specific" not in fda_warn["age_risks"].lower():
                facts.append(f"OpenFDA {generic.upper()} Geriatric/Pediatric risk: {fda_warn['age_risks']}")
            if fda_warn["kidney_risks"] and "no specific" not in fda_warn["kidney_risks"].lower():
                facts.append(f"OpenFDA {generic.upper()} Renal risk: {fda_warn['kidney_risks']}")
            if fda_warn["liver_risks"] and "no specific" not in fda_warn["liver_risks"].lower():
                facts.append(f"OpenFDA {generic.upper()} Hepatic risk: {fda_warn['liver_risks']}")

        # Drug interactions
        all_drugs = list(patient.new_prescription) + list(patient.current_medications)
        raw_ints = await self.drugbank.get_drug_interactions(all_drugs)
        for r in raw_ints:
            facts.append(f"DrugBank Interaction ({r['severity']}) between {', '.join(r['drugs'])}: {r['description']}")

        return facts
