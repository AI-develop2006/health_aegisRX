# MASTER BACKEND IMPLEMENTATION PROMPT --- AegisRx / HealthLock

You are a senior backend architect and Python FastAPI engineer.

Your task is to COMPLETE the remaining production-quality backend for my
college project:

**AegisRx / HealthLock -- Patient Sovereign Health**

The frontend is already created.

A major part of the AI and blockchain implementation is already complete
and working correctly. You must build the missing backend around those
modules without unnecessarily rewriting, replacing, duplicating, or
breaking them.

------------------------------------------------------------------------

# 1. CRITICAL RULE: PRESERVE EXISTING WORKING FILES

The following files are already complete and working perfectly.

## Existing AI files

-   `gemini.py`
-   `ai_service.py`
-   `patient.py`
-   `response.py`
-   `config.py`

## Existing Blockchain files

-   `PrescriptionLedger.sol`
-   `polygon_client.py`
-   `ledger_service.py`
-   `prescription_service.py`
-   `pharmacy_service.py`

## Mandatory preservation rules

1.  Do not rewrite these files from scratch.
2.  Do not delete their working logic.
3.  Do not create duplicate AI or blockchain implementations.
4.  Do not replace Gemini integration with another LLM.
5.  Do not replace Polygon integration with a mock blockchain.
6.  Do not modify the Solidity contract unless an actual compatibility
    problem is proven.
7.  Reuse existing public functions, classes, schemas, and service
    methods wherever possible.
8.  If integration changes are necessary:
    -   make the smallest possible change;
    -   preserve backward compatibility;
    -   document the reason.
9.  Before coding, inspect imports, function signatures, return values,
    environment variables, and dependencies of all existing files.
10. Treat these modules as existing internal dependencies of the
    remaining backend.

The goal is:

**Complete the backend around the existing AI and blockchain
implementation.**

------------------------------------------------------------------------

# 2. PROJECT ARCHITECTURE

Use:

-   Python 3.10+
-   FastAPI
-   Pydantic v2
-   MongoDB
-   Motor async MongoDB driver
-   JWT access tokens
-   JWT refresh tokens
-   Argon2 password hashing
-   HTTPX for internal service communication
-   Docker
-   Docker Compose
-   Environment-based configuration
-   Async service methods
-   OpenAPI documentation
-   Pytest

Target microservices:

-   Gateway Service --- port `4000`
-   Auth Service --- port `4001`
-   Patient Service --- port `4002`
-   Consultation Service --- port `4003`
-   Prescription Service --- port `4004`
-   Audit/AI Service --- port `4005`
-   Pharmacy Service --- port `4006`
-   Ledger Service --- port `4007`

If the current repository already has a different but compatible
structure, preserve it and integrate into it instead of blindly
restructuring everything.

------------------------------------------------------------------------

# 3. FIRST TASK: REPOSITORY ANALYSIS

Before generating code:

1.  Scan the complete repository.
2.  Identify:
    -   existing FastAPI apps;
    -   routers;
    -   schemas;
    -   services;
    -   MongoDB utilities;
    -   environment configuration;
    -   AI modules;
    -   blockchain modules;
    -   frontend API calls;
    -   duplicated implementations;
    -   incomplete TODOs;
    -   broken imports;
    -   missing endpoints.
3.  Build an internal endpoint matrix:

`Frontend Screen -> Frontend API Call -> Required Backend Endpoint -> Existing/Missing -> Service -> Collection`

4.  Reuse existing code whenever possible.
5.  Do not ask me to manually identify every missing file.
6.  Do not stop after analysis.
7.  After analysis, implement the missing backend.

------------------------------------------------------------------------

# 4. REQUIRED DATABASE COLLECTIONS

Support the frontend using these MongoDB collections.

## Core identity

### `patients`

Fields:

-   `_id`
-   `patient_id`
-   `full_name`
-   `date_of_birth`
-   `email`
-   `phone`
-   `gender`
-   `region`
-   `password_hash`
-   `is_verified`
-   `verification_status`
-   `allergies`
-   `chronic_conditions`
-   `created_at`
-   `updated_at`
-   `is_active`

### `doctors`

Fields:

-   `_id`
-   `doctor_id`
-   `full_name`
-   `medical_license_number`
-   `npi`
-   `hospital_name`
-   `specialty`
-   `official_email`
-   `official_phone`
-   `password_hash`
-   `verification_status`
-   `wallet_address`
-   `created_at`
-   `updated_at`
-   `is_active`

Verification states:

-   `pending`
-   `verified`
-   `suspended`
-   `rejected`

### `pharmacies`

Fields:

-   `_id`
-   `pharmacy_id`
-   `pharmacy_name`
-   `license_id`
-   `address`
-   `created_at`
-   `updated_at`
-   `is_active`

### `pharmacy_users`

Fields:

-   `_id`
-   `staff_id`
-   `pharmacy_id`
-   `full_name`
-   `email`
-   `password_hash`
-   `role`
-   `is_active`
-   `created_at`

------------------------------------------------------------------------

# 5. RELATIONSHIP COLLECTIONS

## `doctor_hospital_map`

Fields:

-   `doctor_id`
-   `hospital_id`
-   `hospital_name`
-   `status`
-   `created_at`

## `doctor_patient_map`

Fields:

-   `doctor_id`
-   `patient_id`
-   `consultation_id`
-   `access_token_id`
-   `access_status`
-   `granted_at`
-   `expires_at`
-   `revoked_at`

Access states:

-   `pending`
-   `active`
-   `expired`
-   `revoked`

------------------------------------------------------------------------

# 6. CONSULTATION AND ENCOUNTER COLLECTIONS

## `consultations`

Fields:

-   `consultation_id`
-   `patient_id`
-   `doctor_id`
-   `patient_name`
-   `doctor_name`
-   `status`
-   `created_at`
-   `accepted_at`
-   `rejected_at`
-   `closed_at`

States:

-   `pending`
-   `accepted`
-   `rejected`
-   `closed`

## `encounters`

Fields:

-   `encounter_id`
-   `consultation_id`
-   `patient_id`
-   `doctor_id`
-   `reason`
-   `diagnosis`
-   `status`
-   `started_at`
-   `closed_at`

## `encounter_notes`

Fields:

-   `note_id`
-   `encounter_id`
-   `doctor_id`
-   `patient_id`
-   `summary`
-   `notes`
-   `created_at`
-   `updated_at`

------------------------------------------------------------------------

# 7. PRESCRIPTION COLLECTIONS

Preserve compatibility with the existing working
`prescription_service.py`.

## `prescriptions`

Support existing fields and extend safely:

-   `id`
-   `patient_id`
-   `doctor_id`
-   `encounter_id`
-   `doctorName`
-   `hospitalName`
-   `patientName`
-   `disease`
-   `date`
-   `time`
-   `medicines`
-   `signature`
-   `doctorSignId`
-   `isDispensed`
-   `onchainHash`
-   `onchainCreateTx`
-   `onchainDispenseTx`
-   `status`
-   `audit_id`
-   `override_id`
-   `created_at`
-   `updated_at`

Do not break existing field names used by blockchain code.

## `prescription_items`

Fields:

-   `item_id`
-   `prescription_id`
-   `drug_name`
-   `dose`
-   `route`
-   `frequency`
-   `duration`
-   `quantity`
-   `indication`
-   `special_notes`
-   `created_at`

The backend may keep the existing embedded `medicines` array for
blockchain/signature compatibility while also storing normalized item
records if required by the frontend.

The canonical signed payload must remain deterministic.

------------------------------------------------------------------------

# 8. AI AUDIT PERSISTENCE

The AI implementation already exists.

Do not rewrite it.

Create integration and persistence around it.

## `audit_references`

Fields:

-   `audit_id`
-   `patient_id`
-   `doctor_id`
-   `encounter_id`
-   `prescription_id`
-   `request_snapshot`
-   `response_snapshot`
-   `risk_band`
-   `risk_score`
-   `recommendation`
-   `flagged_medicines`
-   `risk_reasons`
-   `safe_alternatives`
-   `model_provider`
-   `created_at`

Required behavior:

1.  Doctor submits prescription draft.
2.  Backend validates patient access.
3.  Backend calls existing AI service.
4.  Existing AI result is returned.
5.  Persist an immutable audit snapshot.
6.  Return frontend-compatible response.

Do not silently change AI output semantics.

Normalize only at the API boundary when required.

------------------------------------------------------------------------

# 9. OVERRIDE WORKFLOW

Create:

## `override_events`

Fields:

-   `override_id`
-   `audit_id`
-   `prescription_id`
-   `patient_id`
-   `doctor_id`
-   `risk_band`
-   `risk_score`
-   `category`
-   `rationale`
-   `ai_reasons`
-   `created_at`

Categories:

-   `emergency`
-   `clinical_judgment`
-   `other`

Rules:

-   LOW risk: normal sign flow.
-   MODERATE risk: configurable policy.
-   HIGH risk: require explicit rationale.
-   CRITICAL risk: block by default unless configured project policy
    explicitly allows override.
-   Never allow the frontend alone to decide override permission.
-   Backend must enforce policy.

------------------------------------------------------------------------

# 10. SIGNATURE RECORDS

Create:

## `signature_records`

Fields:

-   `signature_id`
-   `prescription_id`
-   `doctor_id`
-   `doctor_sign_id`
-   `canonical_hash`
-   `signature`
-   `algorithm`
-   `signed_at`
-   `verification_status`

Use the existing prescription signature implementation.

Do not invent a second signature algorithm.

------------------------------------------------------------------------

# 11. FOLLOW-UP SUPPORT

Create:

## `followups`

Fields:

-   `followup_id`
-   `patient_id`
-   `doctor_id`
-   `encounter_id`
-   `prescription_id`
-   `scheduled_at`
-   `reason`
-   `status`
-   `created_at`

States:

-   `scheduled`
-   `completed`
-   `cancelled`

------------------------------------------------------------------------

# 12. AUTH SERVICE --- PORT 4001

Implement complete authentication.

Required endpoints:

### Patient

`POST /auth/patient/signup`

Request:

-   full_name
-   date_of_birth
-   email or phone
-   password
-   optional gender
-   optional region
-   privacy_policy_accepted

`POST /auth/patient/verify`

Request:

-   identifier
-   verification_code

`POST /auth/patient/resend-code`

`POST /auth/patient/login`

`POST /auth/patient/refresh`

### Doctor

`POST /auth/doctor/login`

Only verified doctors should receive normal doctor access.

Pending/suspended doctors must be handled safely.

### Pharmacy

`POST /auth/pharmacy/login`

### Common

`POST /auth/refresh`

`POST /auth/logout`

`POST /auth/forgot-password`

`POST /auth/reset-password`

`GET /auth/me`

Authentication response:

-   `access_token`
-   `refresh_token`
-   `token_type`
-   `expires_in`
-   `role`
-   `user_id`

JWT claims:

-   `sub`
-   `role`
-   `jti`
-   `iat`
-   `exp`

Implement refresh-token rotation.

Store hashed refresh tokens, not raw tokens.

Create:

## `sessions`

Fields:

-   `session_id`
-   `user_id`
-   `role`
-   `refresh_token_hash`
-   `created_at`
-   `expires_at`
-   `revoked_at`
-   `device_info`

Use Argon2 for passwords.

Never store plaintext passwords.

------------------------------------------------------------------------

# 13. PATIENT SERVICE --- PORT 4002

Required endpoints:

`GET /patient/me`

`PATCH /patient/me`

`GET /patient/dashboard`

Dashboard response must support:

-   patient identity
-   age
-   gender
-   risk band
-   numeric risk score
-   active alerts
-   medication schedule
-   inventory overview
-   active prescription count

`GET /patient/history`

Support pagination.

`GET /patient/history/{entry_id}`

Return:

-   encounter details
-   doctor
-   diagnosis
-   notes summary
-   prescription items
-   risk snapshot
-   override information

`GET /patient/prescriptions`

`GET /patient/prescriptions/{rx_id}`

`GET /patient/alerts`

Do not accept arbitrary `patientId` from the frontend for protected
self-service endpoints.

Derive patient identity from JWT.

------------------------------------------------------------------------

# 14. PATIENT APP UNLOCK SUPPORT

The frontend contains PIN/biometric unlock.

Do not store raw biometric data.

Implement only backend support that is actually appropriate.

Possible endpoints:

`POST /patient/security/pin/setup`

`POST /patient/security/pin/verify`

`DELETE /patient/security/pin`

Store only a secure PIN hash if server-side PIN support is required.

If biometric unlock is entirely device-local, do not fake a backend
biometric system.

Document that biometric verification remains device-side and backend
receives only normal authenticated requests.

------------------------------------------------------------------------

# 15. DOCTOR ONBOARDING

Required endpoints:

`POST /doctors/onboarding`

Request:

-   full_name
-   medical_license_number
-   hospital_name
-   specialty
-   official_email
-   official_phone
-   password if current flow requires it

`GET /doctors/verification-status`

`GET /doctors/me`

`PATCH /doctors/me`

For this college project, implement a safe mock/manual verification
mechanism instead of claiming real government medical-license
verification.

Example:

-   new doctor -\> `pending`
-   admin/dev verification -\> `verified`

Do not falsely represent mock verification as government verification.

------------------------------------------------------------------------

# 16. DOCTOR DASHBOARD

Required:

`GET /doctors/dashboard`

Response:

-   today_appointments
-   active_consultations
-   high_risk_patient_count
-   recent_override_count
-   recent_prescriptions

Additional endpoints:

`GET /doctors/prescriptions`

`GET /doctors/prescriptions/{rx_id}`

------------------------------------------------------------------------

# 17. DOCTOR PATIENT ACCESS

The frontend supports search and QR scan.

Patient privacy must be enforced.

Required endpoints:

`GET /doctors/patients/search?q=...`

Search must not expose full medical history without valid access.

Return minimal result:

-   patient initials
-   age
-   masked patient ID
-   last encounter date only if policy permits

`POST /doctors/patient-access/scan`

Request:

-   QR token

Validate:

-   token type
-   token hash
-   expiry
-   audience
-   doctor identity
-   revocation
-   current state

`GET /doctors/patients/{patient_id}/history`

Require active doctor-patient consent/access.

`GET /doctors/patients/{patient_id}/profile`

Return only clinically relevant authorized fields:

-   identity
-   age
-   allergies
-   chronic conditions

------------------------------------------------------------------------

# 18. CONSULTATION SERVICE --- PORT 4003

Implement:

`POST /consultation/request`

`GET /consultation/pending`

`POST /consultation/{id}/accept`

`POST /consultation/{id}/reject`

`POST /consultation/{id}/close`

`GET /consultation/active`

`GET /consultation/{id}`

Lifecycle:

1.  Doctor requests access.
2.  Consultation becomes `pending`.
3.  Patient accepts.
4.  Consultation becomes `accepted`.
5.  Doctor-patient map becomes active.
6.  Reuse existing Ledger Service to append `ACCESS_GRANT`.
7.  Doctor performs encounter.
8.  Prescription is signed and committed.
9.  Consultation closes.
10. Access is revoked.
11. Reuse existing Ledger Service to append `ACCESS_REVOKE`.

Make transitions idempotent.

Reject invalid transitions.

Example:

-   rejected -\> accepted must fail unless explicit new request is
    created.
-   closed -\> accepted must fail.

------------------------------------------------------------------------

# 19. QR ACCESS TOKEN SYSTEM

The frontend requires short-lived QR sharing.

Create:

## `access_tokens`

Fields:

-   `token_id`
-   `token_hash`
-   `patient_id`
-   `audience`
-   `purpose`
-   `status`
-   `created_at`
-   `expires_at`
-   `used_at`
-   `revoked_at`
-   `created_by`

Audience:

-   `doctor`
-   `pharmacy`

Status:

-   `active`
-   `used`
-   `expired`
-   `revoked`
-   `blocked`

Never store raw QR bearer tokens.

Store SHA-256 token hashes.

Generate raw token with `secrets.token_urlsafe()`.

Required patient endpoints:

`POST /patient/share/doctor`

Response:

-   `token`
-   `token_id`
-   `expires_at`
-   `qr_payload`

`POST /patient/share/pharmacy`

`GET /patient/share/{token_id}/status`

`POST /patient/share/{token_id}/revoke`

Rules:

-   short expiry
-   audience binding
-   patient ownership
-   server-side validation
-   revocation support

Important:

Doctor consent/access QR tokens and pharmacy prescription redemption
tokens are not interchangeable.

------------------------------------------------------------------------

# 20. PRESCRIPTION SERVICE --- PORT 4004

Reuse existing working `prescription_service.py`.

Required endpoints:

`POST /prescriptions/drafts`

`PATCH /prescriptions/drafts/{draft_id}`

`GET /prescriptions/drafts/{draft_id}`

`POST /prescriptions/{draft_id}/audit`

`POST /prescriptions/{draft_id}/sign-commit`

`GET /prescriptions/{rx_id}`

`GET /prescriptions`

Sign and commit flow:

1.  Authenticate doctor.
2.  Confirm doctor is verified.
3.  Confirm active patient access.
4.  Confirm encounter is active.
5.  Load prescription draft.
6.  Confirm valid AI audit exists.
7.  Check override requirement.
8.  If override required:
    -   validate category;
    -   validate rationale;
    -   persist override event.
9.  Build final deterministic prescription payload.
10. Reuse existing canonicalization.
11. Reuse existing SHA-256 hashing.
12. Reuse existing signature logic.
13. Persist prescription.
14. Persist prescription items.
15. Persist signature record.
16. Link audit reference.
17. Reuse existing Ledger Service.
18. Reuse existing Polygon create-prescription logic.
19. Save transaction hash.
20. Close encounter.
21. Revoke doctor access.
22. Append access-revoke event through existing ledger integration.
23. Return final committed prescription.

This workflow must be transaction-aware.

MongoDB operations should use a transaction where supported.

External Polygon calls cannot be rolled back like MongoDB writes.

Therefore model blockchain submission status explicitly.

Suggested fields:

-   `chain_status`
-   `chain_error`
-   `chain_retry_count`
-   `chain_submitted_at`

Do not falsely mark chain commit successful if transaction submission
fails.

------------------------------------------------------------------------

# 21. AI SERVICE --- PORT 4005

Existing AI files are complete.

Expose/integrate:

`POST /api/audit`

Expected request:

-   patient_id
-   doctor_id
-   new_medicine
-   new_dosage
-   disease

If the existing AI module supports richer fields, preserve them.

Response should support:

-   patient_id
-   risk_band
-   risk_score
-   recommendation
-   flagged_medicines
-   risk_reasons
-   safe_alternatives
-   override_allowed

The API adapter may normalize naming differences but must not rewrite AI
reasoning logic.

Add:

`GET /api/audit/{audit_id}`

Only authorized patient/doctor access.

------------------------------------------------------------------------

# 22. PHARMACY AUTHENTICATION

Required endpoints:

`POST /pharmacy/auth/login`

`GET /pharmacy/me`

Reuse common auth infrastructure where practical.

Do not duplicate password logic.

------------------------------------------------------------------------

# 23. PHARMACY TERMINAL TRUST

The frontend requires terminal authentication.

Create:

## `pharmacy_terminals`

Fields:

-   `terminal_id`
-   `pharmacy_id`
-   `workstation_id`
-   `device_certificate_fingerprint`
-   `hardware_key_id`
-   `trust_status`
-   `last_verified_at`
-   `created_at`
-   `revoked_at`

Trust states:

-   `trusted`
-   `untrusted`
-   `revoked`

Required endpoints:

`POST /pharmacy/terminal/register`

`POST /pharmacy/terminal/verify`

`GET /pharmacy/terminal/status`

For a college project:

-   implement a clearly documented simulated terminal trust flow if real
    hardware keys/certificates are unavailable;
-   never claim simulated trust is real hardware attestation.

Protected token APIs must check trusted terminal status.

------------------------------------------------------------------------

# 24. PHARMACY QR VERIFICATION

Reuse existing working `pharmacy_service.py`.

Required:

`POST /pharmacy/verify-scan`

Flow:

1.  Authenticate pharmacist.
2.  Verify trusted terminal.
3.  Validate QR/token.
4.  Check token audience = pharmacy.
5.  Check expiry.
6.  Check revocation.
7.  Check used/burned state.
8.  Load prescription.
9.  Reuse existing signature verification.
10. Recompute local canonical hash.
11. Reuse existing Ledger Service.
12. Reuse existing Polygon read.
13. Compare local hash with on-chain hash.
14. Check on-chain dispensed state.
15. Return minimal patient data.
16. Return prescription summary.
17. Return token state.

Possible frontend statuses:

-   `ACTIVE`
-   `HIGH_RISK_OVERRIDE`
-   `USED`
-   `EXPIRED`
-   `BLOCKED`

Never expose full patient medical history to pharmacy.

------------------------------------------------------------------------

# 25. DISPENSE AND BURN

Required:

`POST /pharmacy/dispense`

Request:

-   prescription_id
-   token_id
-   confirmation
-   optional inventory deductions

Flow:

1.  Authenticate pharmacist.
2.  Validate trusted terminal.
3.  Validate token again.
4.  Validate prescription again.
5.  Ensure not already dispensed.
6.  Ensure token not already used.
7.  Confirm signature.
8.  Confirm ledger state.
9.  Confirm Polygon state.
10. Set local dispense operation to pending.
11. Reuse existing Polygon `markDispensed`.
12. Save on-chain transaction hash.
13. Update prescription `isDispensed = true` only according to defined
    chain-confirmation policy.
14. Mark token `used`.
15. Record burn timestamp.
16. Append internal `DISPENSE_PRESCRIPTION` event.
17. Update inventory if enabled.
18. Write activity log.
19. Return ledger proof metadata.

This endpoint must be idempotent.

Repeated requests must never dispense twice.

Use a unique idempotency key or equivalent protection.

------------------------------------------------------------------------

# 26. PHARMACY INVENTORY

Create:

## `pharmacy_inventory`

Fields:

-   `inventory_id`
-   `pharmacy_id`
-   `drug_name`
-   `batch_number`
-   `quantity_available`
-   `expiry_date`
-   `updated_at`

Endpoints:

`GET /pharmacy/inventory`

`POST /pharmacy/inventory`

`PATCH /pharmacy/inventory/{inventory_id}`

`GET /pharmacy/inventory/search?q=...`

Only pharmacy users from the same pharmacy may access inventory.

------------------------------------------------------------------------

# 27. ACTIVITY AND SECURITY LOGGING

Create:

## `activity_logs`

Fields:

-   `log_id`
-   `actor_id`
-   `actor_role`
-   `action`
-   `resource_type`
-   `resource_id`
-   `result`
-   `ip_address`
-   `user_agent`
-   `timestamp`
-   `metadata`

Log:

-   login success
-   login failure
-   token refresh
-   access request
-   access grant
-   access revoke
-   QR generation
-   QR scan
-   AI audit
-   override
-   prescription signing
-   prescription commit
-   blockchain submission
-   pharmacy verification
-   dispense
-   terminal verification

Do not log:

-   passwords
-   raw JWTs
-   raw refresh tokens
-   raw QR bearer tokens
-   private keys
-   full secrets

------------------------------------------------------------------------

# 28. LEDGER SERVICE --- PORT 4007

The blockchain files already work.

Do not rebuild them.

Expose/adapt existing methods through endpoints only if needed:

`GET /ledger/verify`

`POST /ledger/heal`

`GET /ledger/prescriptions/{rx_id}`

`GET /ledger/events/{resource_id}`

Reuse:

-   `polygon_client.py`
-   `ledger_service.py`
-   `PrescriptionLedger.sol`

Do not create a competing blockchain implementation.

------------------------------------------------------------------------

# 29. GATEWAY SERVICE --- PORT 4000

Implement API gateway routing.

Routes:

-   `/auth/*` -\> Auth Service 4001
-   `/patient/*` -\> Patient Service 4002
-   `/doctors/*` -\> appropriate doctor/auth/consultation backend
-   `/consultation/*` -\> Consultation Service 4003
-   `/prescriptions/*` -\> Prescription Service 4004
-   `/api/audit/*` -\> AI Service 4005
-   `/pharmacy/*` -\> Pharmacy Service 4006
-   `/ledger/*` -\> Ledger Service 4007

Requirements:

-   request ID middleware
-   CORS configuration
-   timeout handling
-   service unavailable handling
-   forwarding Authorization header
-   forwarding request ID
-   structured errors

Do not trust role headers sent directly by clients.

Roles must come from validated JWT claims.

------------------------------------------------------------------------

# 30. ROLE-BASED ACCESS CONTROL

Implement reusable dependencies:

-   `get_current_user`
-   `require_patient`
-   `require_doctor`
-   `require_verified_doctor`
-   `require_pharmacist`
-   `require_trusted_terminal`
-   `require_patient_access`

Example:

Patient-only:

-   dashboard
-   personal history
-   QR generation
-   revoke sharing

Doctor-only:

-   patient access request
-   prescription draft
-   AI audit
-   sign
-   override

Pharmacist-only:

-   verify prescription
-   dispense
-   inventory

Ledger mutation endpoints should be internal-only where possible.

------------------------------------------------------------------------

# 31. STANDARD API RESPONSE FORMAT

Use a consistent response envelope where it does not break existing
clients.

Success:

``` json
{
  "success": true,
  "data": {},
  "message": "Operation successful",
  "request_id": "..."
}
```

Error:

``` json
{
  "success": false,
  "error": {
    "code": "TOKEN_EXPIRED",
    "message": "The sharing token has expired",
    "details": {}
  },
  "request_id": "..."
}
```

Important error codes:

-   `INVALID_CREDENTIALS`
-   `ACCOUNT_NOT_VERIFIED`
-   `DOCTOR_NOT_VERIFIED`
-   `TOKEN_EXPIRED`
-   `TOKEN_REVOKED`
-   `TOKEN_ALREADY_USED`
-   `INVALID_TOKEN_AUDIENCE`
-   `ACCESS_DENIED`
-   `CONSULTATION_NOT_ACTIVE`
-   `AUDIT_REQUIRED`
-   `OVERRIDE_RATIONALE_REQUIRED`
-   `TERMINAL_NOT_TRUSTED`
-   `PRESCRIPTION_ALREADY_DISPENSED`
-   `SIGNATURE_INVALID`
-   `LEDGER_MISMATCH`
-   `BLOCKCHAIN_UNAVAILABLE`

------------------------------------------------------------------------

# 32. VALIDATION RULES

Use strict Pydantic schemas.

Validate:

-   email
-   phone
-   date of birth
-   password length
-   medical license format where practical
-   prescription item count
-   drug names
-   dose
-   route
-   frequency
-   duration
-   quantity
-   token expiry
-   override rationale minimum length
-   ObjectId conversion

Never trust frontend input.

------------------------------------------------------------------------

# 33. MONGODB INDEXES

Create indexes.

Examples:

Unique:

-   `patients.email`
-   `patients.phone` where present
-   `patients.patient_id`
-   `doctors.doctor_id`
-   `doctors.official_email`
-   `doctors.medical_license_number`
-   `pharmacy_users.staff_id`
-   `prescriptions.id`
-   `access_tokens.token_hash`
-   `sessions.session_id`

Compound:

-   `consultations(patient_id, status)`
-   `consultations(doctor_id, status)`
-   `prescriptions(patient_id, created_at)`
-   `prescriptions(doctor_id, created_at)`
-   `audit_references(patient_id, created_at)`
-   `doctor_patient_map(doctor_id, patient_id, access_status)`

TTL where appropriate:

-   verification codes
-   temporary sessions
-   expired ephemeral tokens if deletion policy allows

Do not TTL-delete records required for audit history.

------------------------------------------------------------------------

# 34. ENVIRONMENT CONFIGURATION

Create/update `.env.example`.

Never place real secrets in source code.

Required variables may include:

-   `ENV`
-   `LOG_LEVEL`
-   `MONGO_URI`
-   `MONGO_DB_NAME`
-   `JWT_SECRET_KEY`
-   `JWT_ALGORITHM`
-   `ACCESS_TOKEN_EXPIRE_MINUTES`
-   `REFRESH_TOKEN_EXPIRE_DAYS`
-   `GEMINI_API_KEY`
-   `POLYGON_RPC_URL`
-   `POLYGON_CHAIN_ID`
-   `POLYGON_CONTRACT_ADDRESS`
-   `POLYGON_PRIVATE_KEY`
-   `CORS_ORIGINS`
-   service URLs

Preserve existing environment variable names where existing modules
depend on them.

Do not rename working variables without compatibility aliases.

------------------------------------------------------------------------

# 35. DOCKER

Create/update Docker support.

Each service must have:

-   Dockerfile
-   health check
-   dependency installation
-   correct startup command

Create root:

`docker-compose.yml`

Include:

-   gateway
-   auth-service
-   patient-service
-   consultation-service
-   prescription-service
-   audit-ai-service
-   pharmacy-service
-   ledger-service
-   MongoDB if local development requires it

Use Docker service DNS names for internal communication.

Do not use `localhost` between containers.

Example:

-   `http://auth-service:4001`
-   `http://patient-service:4002`

------------------------------------------------------------------------

# 36. HEALTH ENDPOINTS

Every service:

`GET /health`

Return:

-   service name
-   status
-   timestamp
-   version

Optional readiness:

`GET /ready`

Check required dependencies carefully.

------------------------------------------------------------------------

# 37. FRONTEND CORS

The frontend already exists.

Inspect frontend configuration and determine actual origins.

Configure CORS through environment variables.

Support local development origins such as:

-   frontend Vite development server
-   production frontend URL

Do not use wildcard origins together with credentials.

------------------------------------------------------------------------

# 38. FRONTEND API COMPATIBILITY

Inspect all frontend source files.

Search for:

-   `fetch(`
-   `axios`
-   API client modules
-   environment API URLs
-   endpoint constants

For every frontend call:

1.  Match the backend route.
2.  Match HTTP method.
3.  Match request body.
4.  Match response shape.
5.  Match authentication expectations.
6.  Match error handling.

Do not force unnecessary frontend rewrites.

If the frontend expects a different shape, add a backend adapter when
reasonable.

------------------------------------------------------------------------

# 39. TESTING

Create meaningful tests.

## Auth tests

-   patient signup
-   duplicate account
-   verification
-   wrong verification code
-   login
-   wrong password
-   refresh rotation
-   revoked refresh token
-   role enforcement

## Consultation tests

-   request
-   accept
-   reject
-   invalid transition
-   close
-   access revoke

## QR tests

-   valid token
-   expired token
-   revoked token
-   wrong audience
-   used token

## Prescription tests

-   unauthorized doctor
-   unverified doctor
-   no patient access
-   audit required
-   override required
-   successful sign
-   deterministic canonical hash

## Pharmacy tests

-   untrusted terminal
-   invalid signature
-   ledger mismatch
-   already dispensed
-   successful dispense
-   duplicate dispense request

## Existing AI tests

Do not replace AI logic.

Mock only external Gemini network calls when needed.

## Existing Polygon tests

Do not replace blockchain logic.

Mock RPC calls in unit tests.

Add optional integration tests for configured testnet.

------------------------------------------------------------------------

# 40. SECURITY REQUIREMENTS

Implement:

-   Argon2 password hashing
-   JWT expiry
-   refresh rotation
-   hashed refresh tokens
-   hashed QR tokens
-   RBAC
-   consent enforcement
-   least-privilege patient access
-   terminal trust checks
-   no raw secret logging
-   no private key logging
-   generic login failure messages
-   basic rate limiting where practical
-   idempotency for dispense
-   deterministic prescription canonicalization
-   safe Mongo query construction

Never claim:

-   HIPAA certification
-   GDPR compliance
-   government verification
-   production medical-device approval

unless actually implemented and independently verified.

This is a college project and must represent mock/simulated components
accurately.

------------------------------------------------------------------------

# 41. EXPECTED PROJECT STRUCTURE

Prefer a structure similar to:

``` text
backend/
├── gateway/
│   ├── main.py
│   ├── routes.py
│   ├── proxy.py
│   └── Dockerfile
│
├── services/
│   ├── auth_service/
│   │   ├── main.py
│   │   ├── api/
│   │   ├── models/
│   │   ├── schemas/
│   │   ├── services/
│   │   └── Dockerfile
│   │
│   ├── patient_service/
│   ├── consultation_service/
│   ├── prescription_service/
│   ├── ai_service/
│   ├── pharmacy_service/
│   └── ledger_service/
│
├── shared/
│   ├── auth/
│   ├── database/
│   ├── middleware/
│   ├── errors/
│   ├── logging/
│   └── utils/
│
├── tests/
├── scripts/
├── docker-compose.yml
├── .env.example
└── README.md
```

However:

If the existing repository already has a reasonable structure, adapt to
it.

Do not create unnecessary duplicate directories merely to match this
example.

------------------------------------------------------------------------

# 42. IMPLEMENTATION ORDER

Implement in this exact dependency-aware order:

## Phase 1 --- Repository inspection

-   inspect complete project
-   inspect frontend API usage
-   inspect existing AI modules
-   inspect existing blockchain modules
-   identify missing pieces

## Phase 2 --- Shared infrastructure

-   settings
-   MongoDB
-   IDs
-   timestamps
-   errors
-   logging
-   JWT
-   RBAC
-   password hashing

## Phase 3 --- Authentication

-   patient auth
-   doctor auth
-   pharmacy auth
-   sessions
-   refresh tokens

## Phase 4 --- Identity services

-   patient profile
-   doctor onboarding
-   doctor verification status
-   pharmacy identity

## Phase 5 --- Consent

-   consultations
-   access grants
-   doctor-patient mapping
-   QR access tokens
-   revocation

## Phase 6 --- Clinical data

-   encounters
-   encounter notes
-   history
-   dashboard aggregation

## Phase 7 --- Prescription integration

-   drafts
-   items
-   existing AI audit integration
-   audit persistence
-   overrides
-   existing signature integration
-   existing Polygon integration

## Phase 8 --- Pharmacy

-   terminal trust
-   QR scan
-   existing verification integration
-   dispense
-   token burn
-   inventory

## Phase 9 --- Gateway

-   routing
-   middleware
-   CORS
-   request IDs
-   error handling

## Phase 10 --- DevOps and quality

-   Docker
-   Docker Compose
-   tests
-   indexes
-   README
-   OpenAPI validation

------------------------------------------------------------------------

# 43. REQUIRED FINAL OUTPUT FROM YOU

Do not only explain what should be built.

Actually implement it.

For each implementation phase:

1.  State what existing files were found.
2.  State which files will be preserved.
3.  State which missing files will be created.
4.  Implement complete code.
5.  Fix imports.
6.  Wire routers into FastAPI apps.
7.  Add MongoDB integration.
8.  Add validation.
9.  Add authentication.
10. Add tests.
11. Run available tests.
12. Fix failures.
13. Run syntax/import checks.
14. Continue to the next phase.

At completion provide:

-   final folder tree
-   endpoint matrix
-   environment variable list
-   Docker commands
-   local startup commands
-   test commands
-   frontend base URL configuration
-   remaining mock/simulated components
-   any genuine limitations

------------------------------------------------------------------------

# 44. NON-NEGOTIABLE CONSTRAINTS

-   Do not destroy working AI code.
-   Do not destroy working blockchain code.
-   Do not duplicate AI implementation.
-   Do not duplicate Polygon implementation.
-   Do not expose secrets.
-   Do not store plaintext passwords.
-   Do not store raw refresh tokens.
-   Do not store raw QR bearer tokens.
-   Do not trust frontend role values.
-   Do not allow arbitrary patient history access.
-   Do not let pharmacy access full medical history.
-   Do not allow duplicate dispensing.
-   Do not claim mock verification is real verification.
-   Do not stop after creating empty scaffolding.
-   Do not leave major functions as TODO.
-   Do not return fake success responses for unimplemented operations.
-   Do not silently swallow blockchain failures.
-   Do not modify frontend unnecessarily.
-   Do not ask for confirmation after every file.

Start by scanning the repository and producing the endpoint gap matrix,
then immediately implement the missing backend phase by phase.
