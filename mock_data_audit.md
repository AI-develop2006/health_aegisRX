# AegisRx Mock Data Usage Audit

This document catalogs where mock or fallback datasets are used in the AegisRx Patient, Doctor, and Pharmacy systems, the reason they exist, and how they behave in development versus production environments.

---

## 1. Frontend Portal Mock Gaps

### Patient Profile Defaults
* **Location**: [app_state.dart](file:///c:/Users/srima/hackathon%20votexa/health_lock/lib/core/state/app_state.dart)
* **Wording/Fields**: Default guest state name `Elena Vance` and mock mobile ID `992818`.
* **Reason**: Enables demo usage of the client shell in offline guest mode.
* **Production Behavior**: Overwritten as soon as the patient authenticates via their actual email/password or registers a new credential.

### JWT Authentication Tokens
* **Location**: [patient_unlock_setup_screen.dart](file:///c:/Users/srima/hackathon%20votexa/health_lock/lib/features/patient/screens/patient_auth_Screen/patient_unlock_setup_screen.dart) and [pharmacy_login_screen.dart](file:///c:/Users/srima/hackathon%20votexa/health_lock/lib/features/pharmacy/screens/pharmacy_login_screen.dart)
* **Wording/Fields**: Hardcoded token strings like `mock-jwt-token-patient-alex` and `mock-jwt-token-pharmacy-[LICENSE]`.
* **Reason**: Allows testing secure screens before checking auth-service certificates.
* **Production Behavior**: Strictly replaced by cryptographically signed JWT hashes issued by the gateway container.

### ID Document Attachments
* **Location**: [patient_signup_screen.dart](file:///c:/Users/srima/hackathon%20votexa/health_lock/lib/features/patient/screens/patient_auth_Screen/patient_signup_screen.dart)
* **Wording/Fields**: Auto-generated string `id_proof_document_[id_type].pdf` with a popup dialog message `[ID Type] Document uploaded successfully (mock)`.
* **Reason**: Simulates file upload workflow prior to integrating cloud media buckets.
* **Production Behavior**: Calls the actual document scanner and uploads binary assets to the gateway server.

### Doctor Override Signatures
* **Location**: [doctor_override_and_sign_screen.dart](file:///c:/Users/srima/hackathon%20votexa/health_lock/lib/features/doctor/screens/doctor_override_and_sign_screen.dart)
* **Wording/Fields**: Mock txn hash generator `_generateMockHash()` producing random hexadecimal bytes if transactions fail.
* **Reason**: Avoids crashing the composer screen if the on-chain Polygon node is offline.
* **Production Behavior**: Requires positive block confirmation from the Ethereum/Polygon mainnet, raising high-priority errors if off-chain transactions mismatch.

### Clinical Pre-Flight Safety Checker
* **Location**: [doctor_prescription_editor_screen.dart](file:///c:/Users/srima/hackathon%20votexa/health_lock/lib/features/doctor/screens/doctor_prescription_editor_screen.dart)
* **Wording/Fields**: Local penicillin rule check inside `_runLocalMockAudit()` that triggers a 95 risk score.
* **Reason**: Serves as a deterministic offline-safe fallback checks system if the hybrid AI service fails or faces latency.
* **Production Behavior**: Always routes to the `audit-service` via API Gateway, requesting active LLM audits.

---

## 2. Backend Microservice Mock Gaps

### MedGemma / Cerebras API Fallbacks
* **Location**: `audit-service/app/ai/services/ai_service.py`
* **Wording/Fields**: Falls back to mock JSON payload structure with `backend_mode="mock"` and `backend_reason="..."` explaining LLM key errors.
* **Reason**: Prevents prescription compositions from blocking when Cerebras inference engines are unreachable.
* **Production Behavior**: Requires live API tokens and model queries, failing loudly if credentials expire.

### Polygon RPC Credentials
* **Location**: `prescription-service/app/service.py` and `pharmacy-service/app/service.py`
* **Wording/Fields**: Mock transaction hashes are logged when private key settings are blank.
* **Reason**: Allows microservices to start and execute off-chain MongoDB logs without blocking on EVM node setups.
* **Production Behavior**: Rejects all dispensation queries if the zero-knowledge single-use token fails to commit on-chain.
