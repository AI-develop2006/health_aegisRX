# Mock vs. Real Data Audit — AegisRx Architecture

This document evaluates the 20 safety, compliance, and UX checklist items against the current AegisRx implementation and outlines concrete implementation plans for items that are partial or not implemented.

---

### Item 1: Secure local storage for tokens / IDs
* **Status:** `Partial`
* **Implementation Plan:**
  * **Flutter:** Replace `shared_preferences` references in [app_state.dart](file:///c:/Users/srima/hackathon%20votexa/health_lock/lib/core/state/app_state.dart) for storing sensitive JWT session keys and NPI/license IDs with the `flutter_secure_storage` package.
  * **Files to modify:** Update `pubspec.yaml` to import `flutter_secure_storage: ^9.0.0` and update `AppState.saveToken` / `AppState.loadToken` methods.

---

### Item 2: All API calls using HTTPS/TLS
* **Status:** `Implemented`
* **Details:**
  * **FastAPI:** All AWS Lambda microservices automatically enforce HTTPS/TLS connections in production under AWS API Gateway configuration.
  * **Flutter:** Plain `http` endpoint URLs are used only in local development (configured via local IP); the production flavor configuration resolves the domain via secure `https://` prefix.

---

### Item 3: QR payloads include expiry timestamp, nonce, and narrow scope
* **Status:** `Implemented`
* **Details:**
  * **Flutter:** Generates a secure checkout QR payload containing the prescription hash, an expiry timestamp (10 minutes in the future), a unique session nonce, and a narrow `DISPENSE` scope.
  * **FastAPI:** The pharmacy microservice verifies that `currentTime < expiry` and that the authorization scope strictly matches `DISPENSE` to protect against token replay and unauthorized access.

```mermaid
flowchart TD
    %% Scanned Payload Entry
    Start([Pharmacist scans QR Code]) --> ReceivePayload[Receive fullPayload: data##signature]
    ReceivePayload --> SplitParts[Split fullPayload by '##']
    SplitParts --> ExtractData[parts[0]: rawPayload <br> parts[1]: signature]
    ExtractData --> SendAPI[Post to /api/prescriptions/verify-scan]
    
    %% API Verification Pipeline
    SendAPI --> SplitPipes[Split rawPayload by '|']
    SplitPipes --> CheckLength{Length >= 12?}
    
    %% Length checks
    CheckLength -- "No (Legacy Mode)" --> CheckHash[Verify SHA-256 Hash & Signature]
    CheckLength -- "Yes (Secure Mode)" --> ParseParams[Extract: expiry, nonce, scope]
    
    %% Expiry Check
    ParseParams --> CheckExpiry{currentTime > expiry?}
    CheckExpiry -- "Yes" --> TokenExpired[Return error: Single-use session token expired]
    
    %% Scope Check
    CheckExpiry -- "No" --> CheckScope{scope == 'DISPENSE'? }
    CheckScope -- "No" --> InvalidScope[Return error: Invalid token scope authorization]
    
    %% Signature & Blockchain Check
    CheckScope -- "Yes" --> CheckHash
    CheckHash --> QueryBlockchain[Fetch On-chain Hash from Polygon Smart Contract]
    QueryBlockchain --> VerifySign[Decrypt Signature & Verify Hash Matches Database]
    VerifySign --> FinalDecision{All Checks Match?}
    FinalDecision -- "Yes" --> AllowDispense([Dispensation Desk Authorized])
    FinalDecision -- "No" --> BlockDispense([Block Dispensation - Show Tamper Warning])
```

---

### Item 4: QR payload does NOT contain full patient details
* **Status:** `Implemented`
* **Details:**
  * QR payloads contain only secure, minimal connection keys (e.g. `patient_id` and token) rather than sensitive PII or medical ledger files. Full patient details are retrieved only through backend P2P REST APIs after permission handshakes.

---

### Item 5: Backend enforces role-based access control
* **Status:** `Implemented`
* **Details:**
  * The FastAPI Gateway Service routes and validates JSON Web Tokens (JWT) containing `role` payloads (patient, doctor, or pharmacy) and rejects requests if a user role queries an unauthorized endpoint route.

---

### Item 6: Doctor and pharmacy views only show necessary fields
* **Status:** `Implemented`
* **Details:**
  * The frontend dashboards and portals are clean, showing only appropriate metadata. Full raw microservice audit trails and backend internal logs are hidden from the clinician and pharmacist viewports.

---

### Item 7: RxNorm normalization of medication names
* **Status:** `Implemented`
* **Details:**
  * The `RxNorm` client in the audit service queries the real-time National Institutes of Health (NIH) RxNorm database when `USE_MOCK_AUDIT=false`, resolving drug strings to standard RxCUI codes.

---

### Item 8: openFDA integration for basic side effects
* **Status:** `Implemented`
* **Details:**
  * The `openFDA` client queries the live public FDA adverse event databases in real-time to load side effects and warnings, which are subsequently injected into the LLM system prompt.

---

### Item 9: AI audit output is structured JSON
* **Status:** `Implemented`
* **Details:**
  * The prompt builder restricts the model to return structured JSON. The Gemini client verifies and parses this string into the structured `PrescriptionAnalysis` schema correctly.

---

### Item 10: Doctor override of WARNING/CRITICAL logs reason in DB
* **Status:** `Implemented`
* **Details:**
  * When a doctor decides to override a clinical warning, they are prompted to type an override justification. This is sent to the backend and saved inside the `prescriptions` MongoDB collection.

---

### Item 11: Doctor override also logs an event on the ledger
* **Status:** `Implemented`
* **Details:**
  * **FastAPI:** When a doctor submits a prescription override, the prescription service logs a secure `PrescriptionOverridden` event mapping the Rx ID and clinical justification to the transaction block receipt, verifying the audit trail on-chain.

---

### Item 12: Prescription details stored fully in Mongo; only hashes on-chain
* **Status:** `Implemented`
* **Details:**
  * Full prescription text data is stored in the MongoDB Atlas cloud database. Only the unique cryptographic SHA-256 fingerprint hash of the prescription is registered on the Polygon blockchain ledger.

---

### Item 13: Pharmacy verify step checks both DB and on-chain hash
* **Status:** `Implemented`
* **Details:**
  * In [pharmacy_verification_screen.dart](file:///c:/Users/srima/hackathon%20votexa/health_lock/lib/features/pharmacy/screens/pharmacy_verification_screen.dart), the verification step queries the local database and the smart contract `getPrescription` function, checking that the on-chain hash matches the database hash exactly.

---

### Item 14: Pharmacy shows a clear tamper warning + blocks dispense on mismatch
* **Status:** `Implemented`
* **Details:**
  * If the SHA-256 hashes do not match (suggesting database tampering), the pharmacy desk displays a prominent red warning banner and disables the "Mark Dispensed" action.

---

### Item 15: Patient vault has a visible “Prescription timeline”
* **Status:** `Implemented`
* **Details:**
  * **Flutter:** The prescription detail screen integrates a visual vertical stepper timeline depicting the complete transaction lifecycle: `Prescription Issued` (signed by doctor) ➔ `On-Chain Hash Confirmed` (securely registered) ➔ `Medication Dispensed` / `Dispensation Pending` (live verification status from the pharmacy ledger).

---

### Item 16: Judge/demo mode that guides user flow step-by-step
* **Status:** `Implemented`
* **Details:**
  * The application routes are wired to guide presenters seamlessly through the complete workflow (P2P Handshake -> Compose -> AI Audit Warning -> Override & Sign -> Pharmacy verification and dispensation).

---

### Item 17: Visible status chips/badges in UI
* **Status:** `Implemented`
* **Details:**
  * Displays status indicators like "On-chain: Verified" (Teal/Silver badge), "AI: CRITICAL" (Red badge), and "Dispensed" in the prescription ledger views.

---

### Item 18: Graceful fallback when AI audit fails
* **Status:** `Implemented`
* **Details:**
  * If Gemini or MedGemma fail to respond within their timeout window, the system falls back to database-backed clinical rules checks and logs `Failsafe Mode active`.

---

### Item 19: Graceful fallback when Polygon/RPC fails
* **Status:** `Implemented`
* **Details:**
  * If the Polygon RPC endpoint is unreachable or returns gas errors, the backend triggers the `ALLOW_MOCK_POLYGON_TX` path to generate mock signatures and keep the workflow functional.

---

### Item 20: Documentation sections mentioning HIPAA-style safeguards
* **Status:** `Implemented`
* **Details:**
  * Mentioned throughout `mdfolders/flow.md` and `DOCTOR_FLOW.MD`, explaining end-to-end cryptographic hashing, data minimization, and P2P permission controls.