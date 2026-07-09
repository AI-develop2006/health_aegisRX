I’m building a Doctor Portal (Practitioner Console) for my app AegisRx / HealthLock. The portal should let doctors:

Log in securely (JWT).

Open a dashboard with their profile and active sessions.

Request and receive patient consent via QR/ID.

View patient vault history (allergies, past prescriptions).

Compose a new prescription with structured medication rows.

Call an AI audit service to check allergies, interactions, and duplications.

Override with rationale if risk is high, then cryptographically sign.

Store the prescription in MongoDB and on a Polygon ledger, and generate a QR for pharmacy.

Right now, this flow has bugs from the login page to the signing page, and the AI audit is not always behaving as designed. I want you to act as a senior backend + mobile engineer and help me fix and complete it.

Please do the following:

1. Secure doctor login with JWT (no external JWT API key)
Backend (FastAPI):

Implement or correct POST /api/doctor/login:

Validate doctor credentials (NPI or mobile + password) against MongoDB.

Use a locally configured JWT secret (e.g. JWT_SECRET, JWT_ALGORITHM="HS256" in config.py) to sign tokens.
Note: JWT does not need an external API key; it uses our own secret string for signing and verifying.

Return:

access_token (JWT)

token_type="bearer"

doctor_profile (id, name, NPI, hospital, specialty)

Implement get_current_doctor dependency:

Read Authorization: Bearer <token>.

Decode JWT using JWT_SECRET.

Fetch doctor from DB and make it available to protected routes.

Frontend (Flutter):

In doctor_login_screen.dart:

Remove any hardcoded mock tokens.

Call POST /api/doctor/login with the login form data.

On success:

Store access_token securely (e.g. flutter_secure_storage) and in AppState.

Navigate to doctor_dashboard_screen with real doctor profile.

On failure:

Show an error message and stay on the login screen.

2. Consultation creation and patient vault access
Backend:

Ensure POST /api/consultation/request:

Creates a MongoDB record with:

consultation_id

patient_id

doctor_id

status="pending"

timestamps

Ensure POST /api/consultation/accept:

Updates status to accepted.

Logs an ACCESS_GRANT event in the internal ledger.

Frontend:

In doctor_patient_search_screen.dart:

When scanning patient QR or searching by ID:

Call POST /api/consultation/request using the logged-in doctor and selected patient.

Enter a polling state until the patient accepts.

In doctor_dashboard_screen.dart:

Call an endpoint like GET /api/consultation/active?doctor_id=<id> to show:

Current active patient session (name, id, “Open Vault” button)

“No active session” if none.

In doctor_patient_history_screen.dart:

Use patient_id from the active consultation.

Call:

GET /api/patient/profile/<id> for allergies and conditions.

GET /api/prescriptions?patient=<id> for prescription history.

3. Prescription editor wired to real AI audit
Backend (audit-service / ai_service.py):

Implement POST /api/audit to return a PrescriptionSafetyAnalysis object with fields:

risk_band (LOW, MEDIUM, HIGH, CRITICAL)

risk_score (0–100)

recommendation (short text)

flagged_medicines (each with name and reason)

backend_mode (real or mock)

backend_reason (when fallback/mock is used)

Ensure:

Rule-based agents (Allergy, Interaction, Disease, Dosage) run first.

MedGemma/Gemini are called when USE_MOCK_LLM=false and keys are valid.

If rules find a conflict but LLM says SAFE, the service overrides to HIGH/CRITICAL.

Frontend (doctor_prescription_editor_screen.dart):

On medication row changes (debounced ~600 ms):

Call POST /api/audit with:

patient_id

doctor_id

full draft prescription: drug list, diagnosis, notes, etc.

Display:

Risk band, risk score, explanation from backend.

Suggested alternatives from flagged_medicines or recommendation.

Ensure:

Local _runLocalMockAudit() is only used when ENV=dev or USE_MOCK_LLM=true.

In hackathon/prod, always call the backend /api/audit.

When “Apply Alternative” is tapped:

Replace the drug row in the editor model.

Re-run audit to show updated risk.

4. Override form and cryptographic signing with ledger + Polygon
Backend (prescription_service.py, ledger_service.py, polygon_client.py):

Implement POST /api/prescriptions to:

Check AI audit result:

If risk_band is HIGH or CRITICAL, require:

Override Category

Override Rationale

Responsibility checkbox

Canonicalize prescription JSON (patient, doctor, medicines, diagnosis).

Compute SHA‑256 hash.

Apply hex‑shift signature using the doctor’s NPI.

Save prescription to prescriptions collection with:

hash, signature, consultation_id, AI audit info, override fields.

Append a CREATE_PRESCRIPTION block to the MongoDB blockchain.

If ALLOW_MOCK_POLYGON_TX=false and Polygon keys are configured:

Use polygon_client.py to call the PrescriptionLedger contract and store the hash.

Return the real transaction hash in the response.

Frontend (doctor_override_and_sign_screen.dart):

If AI risk is HIGH/CRITICAL and alternatives are not fully applied:

Show mandatory override fields:

Override Category dropdown

Override Rationale text

Responsibility checkbox

On “Sign & Commit”:

Send POST /api/prescriptions with:

Full prescription payload

consultation id

override data.

Handle response:

Show ledger/Polygon transaction hash returned by backend.

Generate a QR code representing the prescription (id + signature/hash reference) so the patient can use it at a pharmacy.

5. Short test plan for the Doctor Portal
Finally, provide a small checklist to verify the fixed portal:

Doctor login:

Valid credentials → dashboard with correct profile.

Invalid credentials → error, no navigation, no token stored.

Consultation:

QR/search → consultation/request → patient accept → consultation saved with status="accepted" and visible in doctor dashboard.

Patient history:

Shows real allergies and prescriptions from backend, not static mock data.

AI audit:

Critical test case (e.g. Penicillin allergy + Penicillin prescription) → risk_band=CRITICAL, flagged drug and alternatives from backend.

Safe case → risk_band=LOW/SAFE.

Signing:

HIGH/CRITICAL risk requires override fields.

On sign:

Prescription appears in DB with hash/signature.

Ledger block exists.

Polygon tx is recorded (if configured) and hash is visible in doctor UI.

QR is generated and usable by pharmacy.