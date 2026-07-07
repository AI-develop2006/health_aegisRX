# AegisRx QA Gap Analysis: Frontend-to-Backend Connection Review

This review identifies critical gaps across the **AegisRx** Patient, Doctor, and Pharmacist portals where front-end inputs are mocked, disconnected, or dropped, and where database/blockchain records are not correctly synchronized or fetched.

---

## 1. Patient Portal Gaps

### Gap 1.1: Registration Data Loss on Signup
* **Problem**: The patient signup screen collects a rich profile (mobile number, date of birth, gender, country, ID type, ID number, and uploaded proof file), but the authentication client only sends name, email, and password. The additional data is completely ignored by the backend registration schema.
* **Screen / Flow Affected**: Patient Signup (`PatientSignUpScreen` -> `signUpWithEmail`).
* **Backend Endpoint / Entity**: `/api/patient/register` in `auth-service` / MongoDB `patients` collection schema.
* **Exact Fix Recommendation**:
  1. Expand the `PatientSignup` Pydantic schema in `auth-service/app/models.py` to include: `mobile`, `dob`, `gender`, `country`, `id_type`, `id_number`, and `uploaded_file_name`.
  2. Update the registration service logic in `auth-service/app/service.py` to persist all these fields into the `patients` MongoDB collection.
  3. Modify `app_state.dart` (`signUpWithEmail`) to serialize and send all collected controller values to the backend.
* **Priority**: **HIGH** (Prevents critical patient profile loss).

### Gap 1.2: Hardcoded Semicircle RiskGauge Text
* **Problem**: The `RiskGauge` widget correctly takes a `severityScore` but has its indicator text dynamically locked to "LOW RISK" and color-styled in medical teal.
* **Screen / Flow Affected**: Patient Dashboard (`PatientDashboardScreen` -> `RiskGauge`).
* **Backend Endpoint / Entity**: UI-side rendering only.
* **Exact Fix Recommendation**:
  - Refactor `RiskGauge` to dynamically set the display label and color theme based on the score threshold:
    - `0 - 30`: "LOW RISK" (Teal: `0xFF2E8B90`)
    - `31 - 70`: "MEDIUM RISK" (Amber: `0xFFD97736`)
    - `71 - 100`: "CRITICAL RISK" (Red: `0xFFB33A3A`)
* **Priority**: **MEDIUM** (Avoids misleading risk representations).

### Gap 1.3: Hardcoded Mock Inventory Tracker
* **Problem**: The `InventoryTracker` widget renders static rows for "Metformin" and "Aspirin" and is not connected to active prescriptions in the database or the client's `AppState`.
* **Screen / Flow Affected**: Patient Dashboard (`PatientDashboardScreen` -> `InventoryTracker`).
* **Backend Endpoint / Entity**: UI-side rendering only.
* **Exact Fix Recommendation**:
  - Modify `InventoryTracker` to accept a list of active `Prescription` models from `AppState.patientVault`.
  - Parse the active medicines and calculate remaining doses based on the duration value and unit. Display live indicators instead of hardcoded items.
* **Priority**: **MEDIUM** (Aligns medication counts with actual vault state).

### Gap 1.4: Disconnected DangerBanner and Allergy Logs
* **Problem**: The `DangerBanner` widget exists to highlight severe allergy warnings, but it is not imported or used in the `PatientDashboardScreen`.
* **Screen / Flow Affected**: Patient Dashboard (`PatientDashboardScreen`).
* **Backend Endpoint / Entity**: DB `allergies` collection data.
* **Exact Fix Recommendation**:
  - Import `danger_banner.dart` in `patient_dashboard_screen.dart`.
  - Query active patient allergies from the database, and display the `DangerBanner` prominently if conflicts are active.
* **Priority**: **HIGH** (Critical clinical safety indicator).

### Gap 1.5: Hidden Visits Ledger and Activity Logs
* **Problem**: The patient state client fetches both ledger-tracked visit history (`_visitHistory` via `/api/visit-history/{name}`) and general activity logs (`_activityLogs` via `/api/activity-logs`), but these are never referenced or displayed on any screens.
* **Screen / Flow Affected**: Patient History / Ledger logs audit.
* **Backend Endpoint / Entity**: `/api/visit-history/{patient_name}` and `/api/activity-logs`.
* **Exact Fix Recommendation**:
  - Expand the `PatientHistoryScreen` with a tabbed view: "Active Prescriptions" and "Sovereign Ledger Audit".
  - Render the visit blocks and activity entries to allow patients to see the tamperproof ledger trail (e.g., when doctor access was granted/revoked, and when prescriptions were verified and dispensed).
* **Priority**: **HIGH** (Vital for patient-sovereign transparency).

---

## 2. Doctor Portal Gaps

### Gap 2.1: Missing Doctor Name in Session State
* **Problem**: The logged-in doctor's full name is never saved in `AppState` upon login/registration. As a result, prescription submissions fall back to the license ID (e.g., "Dr. 889218") or a hardcoded string ("Dr. Alexander Vance").
* **Screen / Flow Affected**: Clinical Composer (`DoctorOverrideAndSignScreen` -> `createPrescription`).
* **Backend Endpoint / Entity**: `/api/prescriptions` in `prescription-service` (`doctorName` field).
* **Exact Fix Recommendation**:
  - Retrieve the doctor's name from the JSON body in `AppState.loginDoctor` and `AppState.registerDoctor` and save it to a new state variable `_doctorName`.
  - Send `_doctorName` in the `createPrescription` payload.
* **Priority**: **HIGH** (Prevents corrupting signature identifiers on ledger).

### Gap 2.2: Mocked AI Safety Audit in Editor Screen
* **Problem**: Clicking "Run AI Safety Audit" in the prescription editor triggers a 400ms delay and runs a hardcoded client-side Penicillin check for patient `elena_vance`. It never communicates with the backend AI service.
* **Screen / Flow Affected**: Clinical Composer (`DoctorPrescriptionEditorScreen` -> `_runAiAudit`).
* **Backend Endpoint / Entity**: `/api/audit` (API Gateway routes port 4000 -> 4005).
* **Exact Fix Recommendation**:
  - Replace the local `_runAiAudit` mock delay with an HTTP call to the API Gateway `/api/audit` routing to `audit-service`.
  - Send the patient's name/ID, current drugs, and the proposed drug, strength, and diagnosis. Update the UI states using the returned `risk_level`, `risk_score`, and safe drug alternatives.
* **Priority**: **HIGH** (Enables real-time multi-agent safety checking).

### Gap 2.3: Ignored Specialty and Profile Fields on Onboarding
* **Problem**: The doctor onboarding form collects specialty, official email, and official phone numbers, but the register API payload drops them.
* **Screen / Flow Affected**: Doctor Onboarding (`DoctorOnboardingScreen`).
* **Backend Endpoint / Entity**: `/api/doctor/register` in `auth-service` / MongoDB `doctors` collection.
* **Exact Fix Recommendation**:
  - Expand the `DoctorRegisterInput` Pydantic model in `auth-service/app/models.py` to accept `specialty`, `email`, and `phone`.
  - Update `doctor_register` in `auth-service/app/service.py` to save these variables in the `doctors` collection.
* **Priority**: **MEDIUM** (Needed for auditing practitioner details).

---

## 3. Pharmacist Portal Gaps

### Gap 3.1: Technical Check Inputs Dropped on Dispensation
* **Problem**: The pharmacist verification screen captures lot numbers, expiry dates, and signatures, but the dispense endpoint `/api/prescriptions/dispense` only receives the prescription ID. The technical checklist details are discarded.
* **Screen / Flow Affected**: Pharmacy Dispense (`PharmacyVerificationScreen` -> `PharmacyDispenseScreen`).
* **Backend Endpoint / Entity**: `/api/prescriptions/dispense` in `pharmacy-service` / `prescriptions` MongoDB collection.
* **Exact Fix Recommendation**:
  - Update the Pydantic schema `DispenseInput` in `pharmacy-service/app/models.py` to accept: `batch_number`, `expiry_date`, `touch_signature`, and `delivery_tracking_id`.
  - Update `dispense_prescription` in `pharmacy-service/app/service.py` to store these parameters in the prescription record and create a more detailed block in the ledger.
* **Priority**: **MEDIUM** (Critical for tracking drug recall batches).

---

## 4. AI Safety Engine Gaps

### Gap 4.1: Hidden Model Performance and Fallback Metadata
* **Problem**: The backend AI audit service returns helpful metadata showing whether it ran in real LLM mode or rule-engine fallback, along with latency. The doctor UI fails to display this, masking LLM failures.
* **Screen / Flow Affected**: Clinical Composer (`DoctorPrescriptionEditorScreen` / `DoctorOverrideAndSignScreen`).
* **Backend Endpoint / Entity**: `/api/audit` response metadata fields.
* **Exact Fix Recommendation**:
  - Add a small metadata badge to the Clinical Composer safety panel indicating if the audit completed via a real service (e.g., Cerebras) or deterministically via the clinical rules engine (mock/fallback mode), along with the execution latency.
* **Priority**: **MEDIUM** (Critical for testing and auditing model reliability).

---

## 5. Ledger / Blockchain Gaps

### Gap 5.1: Missing Verification Logs on Checkouts
* **Problem**: Cryptographic checkups verify signature integrity and run hash matching against the Polygon network. The verification results are shown in text alerts, but the validation metrics (e.g., checksum match, tamper check, Polygon confirmation status) are not logged or visualized.
* **Screen / Flow Affected**: Pharmacy Verification Screen (`PharmacyVerificationScreen`).
* **Backend Endpoint / Entity**: `/api/prescriptions/verify-scan` response.
* **Exact Fix Recommendation**:
  - Render checklist lines showing validation passes: (1) Local payload matches database signature, (2) Decrypted signature equals computed hash, (3) On-chain hash matches local hash.
* **Priority**: **HIGH** (Establishes verification audit trail).

---

## 6. Service Failure & Downstate Handling

### Gap 6.1: Silent Client Hang on Server Failures
* **Problem**: If the API gateway or downstream services are unreachable, the Flutter app hangs on loading overlays without notifying the user or showing failure screens.
* **Screen / Flow Affected**: Throughout all state-driven screens.
* **Backend Endpoint / Entity**: API Gateway error responses.
* **Exact Fix Recommendation**:
  - Catch connection and timeout exceptions in `app_state.dart`. Update a new variable `_networkError` when endpoints are unreachable.
  - Implement a fallback error widget/banner across key views with a "Retry Connection" button.
* **Priority**: **HIGH** (Essential for system resilience).
