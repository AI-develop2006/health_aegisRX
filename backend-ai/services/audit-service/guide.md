# AegisRx Audit-Service Safety & Enhancement Guide

> **IMPORTANT SAFETY NOTICE**: The `backend-ai/services/audit-service` codebase already contains a fully implemented, asynchronous, class-based multi-agent Clinical Decision Support System (CDSS) and LLM Orchestration flow.
>
> **DO NOT** rewrite this codebase into synchronous helper functions, dummy placeholders, or hardcoded overrides. Doing so will break the integration with the doctor/patient consoles and disable real-time medical checks.

This document guides developers on how to safely configure, test, and enhance the existing AI audit module without making destructive code modifications or breaking current API contracts.

---

## 🛡️ 1. Safety Principles for Enhancements

If you need to add or refine clinical safety checks, adhere to the following architectural guidelines:

### 1.1 Maintain Asynchronous Operations
All safety agents (`AllergyAgent`, `InteractionAgent`, `DiseaseAgent`, `DosageAgent`) inherit from `BaseAgent` and implement:
```python
async def analyze(self, patient: PatientContext) -> Dict[str, Any]
```
Ensure all database and network IO calls remain asynchronous. Do not block the event loop.

### 1.2 Utilize the Knowledge Layer (No Direct API Calls)
Do not query third-party APIs directly inside agents. All medical fact lookups (RxNorm, DrugBank, DailyMed, OpenFDA, SNOMED) must go through the classes defined in `app/ai/knowledge/`. This decouples data sourcing from clinical analysis rules.

### 1.3 Strict PHI / HIPAA Compliance
Patient health logs must be handled securely:
* **No PII/PHI in LLM Prompt logs**: Never log patient names, email addresses, or specific user IDs directly to external log files or cloud LLM calls if it can be avoided. 
* **Use Hash/Opaque IDs**: Refer to patients using internal UUIDs (`patient_id`) rather than clear-text identifiers in audit logs.

### 1.4 Strict Network Timeouts
To prevent cascading latency in the doctor console, all external requests (NIH RxNorm, OpenFDA, and LLM calls) must enforce a timeout threshold of **at most 3.0 seconds** (e.g. `timeout=3.0` in `httpx.AsyncClient`).

### 1.5 Safety Policy Overrides
If the LLM call times out or encounters a JSON parsing error, the system relies on the deterministic clinical rules compiled in `RecommendationAgent.compile_clinical_overrides(...)`. Even if the LLM output is successfully parsed but erroneously flags a critical risk as `SAFE`, the rules engine **must override** and upgrade the risk severity to protect patient safety.

---

## ⚙️ 2. Configuration & Test Settings

The service behavior is controlled via environment variables. You can configure them in `.env` without modifying code files:

| Environment Variable | Allowed Values | Purpose |
| :--- | :--- | :--- |
| `LLM_PROVIDER` | `gemini`, `gpt`, `medgemma`, `hybrid` | Selects which LLM handles the reasoning summary. |
| `USE_MOCK_AUDIT` | `True`, `False` | When `True`, queries local mock files. When `False`, queries live NIH RxNorm/OpenFDA APIs. |
| `GEMINI_API_KEY` | *(your-key)* | Active when `LLM_PROVIDER` is `gemini` or `hybrid`. |

---

## 🧪 3. Safe Verification Workflows

### 3.1 Automated Testing
To verify the audit service behaves correctly, run the test suites locally using the following command inside the workspace directory:

```bash
pytest backend-ai/services/audit-service/tests
```

### 3.2 Manual Testing with cURL
You can safely test the `/audit` API endpoint directly from your terminal with a POST payload:

```bash
curl -X POST "http://localhost:8000/audit" \
     -H "Content-Type: application/json" \
     -d '{
       "patient_id": "demo-patient",
       "doctor_id": "doc-01",
       "new_medicine": "ibuprofen",
       "new_dosage": "400mg",
       "disease": "chronic kidney disease"
     }'
```

Expected Response structure includes:
* `analysis_id`
* `risk_level` (e.g. `HIGH_RISK`, `WARNING`, `SAFE`)
* `clinical_explanation`
* `allergy_check` & `interaction_check`

---

## 🚀 4. How to Safely Add a New Clinical Rule

To introduce a new check (e.g., checking for specific drug duplication risks):

1. **Modify the corresponding Agent class**:
   Open the target agent (e.g. `app/ai/agents/dosage_agent.py`) and append your rule evaluation inside the `analyze` method.
2. **Do NOT change the input/output signature**:
   Keep the method signature: `async def analyze(self, patient: PatientContext) -> Dict[str, Any]`
3. **Register/Update overrides in the RecommendationAgent**:
   In `app/ai/agents/recommendation_agent.py`, ensure your rule flags are evaluated inside `compile_clinical_overrides(...)` so that they can safely override the LLM output in case of critical warnings.

---

## 🗺️ 5. AI Safety Agents Logic & Roadmap

For a detailed analysis of safety agent rule logic, external dependencies, and clinical gaps, please refer to the central inspection document:
📄 **[app_safety_agent_roadmap.md](file:///C:/Users/srima/.gemini/antigravity-ide/brain/07c66083-b6bc-4528-a614-5b008181504f/app_safety_agent_roadmap.md)**

### Short Summary of the Strengthening Roadmap:
* **Allergy Agent**: Add related-class cross-reactivity checks (e.g., Penicillins and Cephalosporins) and utilize hierarchical SNOMED mappings.
* **Disease Agent**: Support `CRITICAL` severity flags for absolute label contraindications and expand pregnancy / organ clearance rules.
* **Dosage Agent**: Integrate numeric dose quantity parsing (e.g. max daily limits of `"400mg TID"`) and eGFR/CrCl kidney clearance boundaries.
* **Interaction Agent**: Expand drug-drug interaction databases and add dual-therapy exception rules (e.g., dual antiplatelet therapy Aspirin + Clopidogrel).
* **Recommendation Agent**: Suggest patient-tailored alternatives (e.g. filter alternative lists to avoid creating new conflicts for patients with chronic diseases like CKD).