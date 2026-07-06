# AegisRx UI Flows Prompt – Data & Screens (No Theme)

Design a complete, multi‑screen UI for the healthcare system “AegisRx – Patient Sovereign Health” with three portals: **Patient**, **Doctor**, and **Pharmacist**.

Ignore visual theme/styling; focus only on:

- The **screens** required.
- The **data fields** shown on each screen.
- The **flow** between screens.
- How authentication, verification, and security concepts are represented in the UI.

---

## 1. Common app shell & role selection (before auth)

### Screens to design

1. **Splash Screen**
   - Elements:
     - App name: “AegisRx – Patient Sovereign Health”.
     - Simple loading indicator.
   - Purpose:
     - Initial app startup, brief loading.

2. **Onboarding Carousel**
   - 3 slides, each contains:
     - Title text.
     - Short description text.
   - Slide content:
     - Slide 1:
       - Title: “Your health data is under your control.”
       - Description: Explain patient‑sovereign data briefly.
     - Slide 2:
       - Title: “Doctors and pharmacies see only what they need.”
       - Description: Explain limited, consent‑based sharing.
     - Slide 3:
       - Title: “AI audits prescriptions for safety.”
       - Description: Explain AI risk checks (interactions, allergies).
   - Controls:
     - “Next” / “Previous”.
     - “Skip” to go directly to role selection.

3. **Role Selection Screen (Portal Choice)**
   - Elements:
     - Title: “Choose how you want to use AegisRx.”
     - Three role options:
       - Patient
       - Doctor
       - Pharmacist
     - For each role:
       - Role name.
       - One‑line description:
         - Patient: “Manage your prescriptions, risk dashboard, and sharing tokens.”
         - Doctor: “Review history, run safety audits, and sign prescriptions.”
         - Pharmacist: “Verify tokens and dispense medications safely.”
     - Button: “Continue” (changes target based on selected role).
   - Behavior:
     - When user selects Patient → go to Patient sign‑up/login flow.
     - When user selects Doctor → go to Doctor onboarding/login flow.
     - When user selects Pharmacist → go to Pharmacy login/terminal auth flow.

---

## 2. Patient portal – sign‑up, verification, login, unlock, and vault

### 2.1 Patient sign‑up & verification (Cognito)

**Screens:**

1. **Patient Sign‑Up Screen**
   - Data fields:
     - Full name.
     - Date of birth (date picker).
     - Email OR phone number (used as login identifier).
     - Optional: gender.
     - Optional: region or country.
     - Checkbox: “I agree to the privacy policy.”
   - Actions:
     - Button: “Create account”.
   - Backend expectations:
     - On submit, call sign‑up API (Cognito or backend).
     - Show “Verification code sent to email/phone” message.

2. **Patient Verification Screen**
   - Data fields:
     - 6‑digit verification code input.
   - Actions:
     - Button: “Verify”.
     - Link: “Resend code”.
   - Behavior:
     - After correct code:
       - Mark account as verified.
       - Option to proceed to login.

### 2.2 Patient login (Cognito)

**Screen: Patient Login Screen**

- Data fields:
  - Email/phone.
  - Password.
- Actions:
  - Button: “Sign in”.
  - Link: “Forgot password”.
  - Link: “Back to role selection.”
- Optional:
  - If MFA/OTP, show separate screen:
    - Data field: OTP code.
    - Button: “Confirm”.

### 2.3 Patient device unlock (local security)

**Screen: Patient Unlock Screen**

- Data collected / shown:
  - Status: “Session token present” (meaning Cognito login succeeded).
  - Options:
    - Set app PIN (first time):
      - PIN input (4–6 digits).
      - Confirm PIN.
    - Biometric unlock toggle (if supported on device).
  - For returning users:
    - PIN input field OR biometric prompt.
- Behavior:
  - Only after successful unlock should user proceed to **Patient Dashboard**.

### 2.4 Patient dashboard & data

**Screen: Patient Dashboard Screen**

- Data to display:
  - Patient identity:
    - Name or initials.
    - Basic info: age, optional gender.
  - Risk summary:
    - Risk band: LOW / MODERATE / HIGH / CRITICAL.
    - (Optional) numeric risk score (0–100).
  - Alerts:
    - List of active alerts:
      - Example: “Allergy risk with current medication.”
      - Example: “Potential interaction between Drug A and Drug B.”
  - Today’s medication schedule:
    - Sections for Morning / Afternoon / Night.
    - For each section:
      - List of medications due, with:
        - Name.
        - Dose.
        - Status: Taken / Due / Overdue.
  - Inventory overview:
    - For each active medication:
      - Name.
      - Remaining pill count.
      - Estimated days left.
  - Actions:
    - Button: “View history”.
    - Button: “Share with Doctor”.
    - Button: “Share with Pharmacy”.

### 2.5 Patient history

**Screen: Patient History List**

- Data:
  - List of past entries (encounters and prescriptions) with:
    - Date.
    - Doctor name or ID.
    - Summary (e.g., diagnosis or reason visit).
    - Status: Active / Completed / Discontinued.
- Action:
  - Tap an entry to open **History Detail Screen**.

**Screen: History Detail Screen**

- Data:
  - Encounter details:
    - Date.
    - Doctor name/ID.
    - Encounter notes summary.
  - Prescription details:
    - List of medications:
      - Name.
      - Dose.
      - Frequency.
      - Duration.
    - Risk snapshot:
      - Risk band at the time.
      - Reasons for risk.
    - Override info (if any):
      - Whether doctor overrode AI.
      - Short override rationale.

### 2.6 Patient QR share

**Screen: Patient QR Share Screen**

- Modes:
  - “Share with Doctor”.
  - “Share with Pharmacy”.
- Data:
  - Selected mode.
  - Session status:
    - “Ready to scan”.
    - “Connected to doctor [ID]” or “Connected to pharmacy [ID]”.
  - Token expiry countdown.
- UI elements:
  - QR code representing a short‑lived token.
  - Text: “Token expires in X seconds/minutes.”
  - Button: “End session / Revoke access”.

---

## 3. Doctor portal – onboarding, verification, login, console, and audit

### 3.1 Doctor onboarding & verification

**Screen: Doctor Onboarding Request Screen**

- Data fields:
  - Full name.
  - Medical license number / NPI / registration ID.
  - Hospital / clinic name (search/select).
  - Specialty (dropdown: cardiology, internal medicine, etc.).
  - Official email.
  - Official phone number.
- Actions:
  - Button: “Submit verification request.”
- Behavior:
  - After submit, show status:
    - “Your details will be verified. You will receive an invite to complete account setup.”
  - Backend uses this to populate:
    - `doctors`.
    - `doctor_hospital_map`.

**Screen: Doctor Verification Status Screen**

- Data:
  - Doctor name.
  - Hospital.
  - Specialty.
  - Verification status: Verified / Pending / Suspended.
- Behavior:
  - If status = Pending:
    - Message: “Verification in progress. You can view limited data only.”
  - If status = Verified:
    - Button: “Go to Doctor Login”.

### 3.2 Doctor login

**Screen: Doctor Login Screen**

- Data fields:
  - Email.
  - Password.
- Optional MFA screen:
  - OTP input.
- Behavior:
  - On success:
    - Doctor role set.
    - Backend confirms mapping to `doctors` table and `doctor_hospital_map`.

### 3.3 Doctor dashboard (clinical console)

**Screen: Doctor Dashboard Screen**

- Data:
  - Today’s appointments:
    - For each: patient name/ID, time, basic reason.
  - Active consultations:
    - Patients with ongoing QR sessions.
  - Alerts:
    - List of high‑risk patients.
    - Count of recent overrides.
  - Quick actions:
    - “Search patient / Scan QR”.
    - “View my recent prescriptions”.
    - “AI pattern analysis” (optional link).

### 3.4 Doctor patient search & history

**Screen: Doctor Patient Search Screen**

- Data fields:
  - Search input: patient name / ID / phone.
- Actions:
  - Button: “Scan patient QR”.
- Results:
  - Each result row:
    - Patient initials.
    - Age.
    - Last encounter date.
- Tap a result → go to **Doctor Patient History Screen**.

**Screen: Doctor Patient History Screen**

- Data:
  - Patient header: name/initials, age, allergies list, chronic conditions.
  - Encounter timeline:
    - For each encounter:
      - Date.
      - Reason/diagnosis.
      - Summary of outcome.
  - Prescription summary:
    - Past prescriptions with risk bands, override flags.
- Actions:
  - Button: “Write new prescription for this patient”.

### 3.5 Doctor prescription editor & AI audit

**Screen: Doctor Prescription Editor Screen**

- Data fields:
  - Drug name.
  - Dose.
  - Route (e.g., oral, IV).
  - Frequency (e.g., twice daily).
  - Duration (e.g., 7 days).
  - Indication (why prescribing).
  - Special notes (e.g., renal impairment, pregnancy).
- Actions:
  - Button: “Run AI Safety Audit”.
  - Button: “Save draft” (optional).

**Screen: Doctor AI Audit Result Screen**

- Data:
  - Risk band: LOW / MODERATE / HIGH / CRITICAL.
  - Risk score: 0–100.
  - Risk reasons: list of textual reasons (e.g., interactions, allergies).
  - Safe alternatives: list of alternative meds or strategies.
  - Override guidance:
    - “Override allowed: Yes/No”.
    - Short text: override notes.
- Actions:
  - Button: “Apply safe alternative”.
  - Button: “Proceed with override & sign” (if allowed).

### 3.6 Doctor override & sign

**Screen: Doctor Override & Sign Screen**

- Data:
  - Final prescription summary:
    - Drugs, doses, frequencies, durations.
  - AI risk summary:
    - Risk band and reasons.
  - Override input:
    - Text field for rationale.
    - Override category:
      - Emergency.
      - Clinical judgment.
      - Other.
- Actions:
  - Button: “Sign & Commit”.
- Backend effect:
  - Write to:
    - `prescriptions`.
    - `prescription_items`.
    - `override_events`.
    - `signature_records`.
    - `audit_references`.
    - `followups` (if any).

---

## 4. Pharmacy portal – staff login, terminal auth, verification, dispense

### 4.1 Pharmacy staff login

**Screen: Pharmacy Staff Login Screen**

- Data fields:
  - Staff ID or email.
  - Password.
- Context:
  - Pharmacy name.
  - Pharmacy license ID.
- Behavior:
  - On success:
    - Map user to `pharmacies` and `pharmacy_inventory`.
    - Role = pharmacist.

### 4.2 Terminal / hardware authentication

**Screen: Pharmacy Terminal Authentication Screen**

- Data:
  - Staff identity:
    - Staff name.
    - Pharmacy name.
  - Terminal status:
    - Workstation ID.
    - Hardware key presence (e.g., “Key connected / not connected”).
    - Device certificate status (trusted / untrusted).
- Actions:
  - Button: “Verify terminal”.
- Display:
  - Overall status:
    - “Terminal authenticated: YES/NO”.
    - If NO, show message: “Cannot use token APIs from this device.”

### 4.3 Pharmacy QR scan

**Screen: Pharmacy QR Scan Screen**

- Data:
  - Terminal status indicator (trusted/untrusted).
- Actions:
  - QR scanning view.
  - Button: “Enter prescription ID manually”.
- Behavior:
  - After scan:
    - Backend checks token and terminal.
    - Navigate to **Pharmacy Verification Screen**.

### 4.4 Pharmacy verification

**Screen: Pharmacy Verification Screen**

- Data:
  - Token status:
    - ACTIVE / HIGH‑RISK OVERRIDE / USED / EXPIRED / BLOCKED.
  - Patient info (minimal):
    - Initials.
    - Age bracket (e.g., “F, 56”).
  - Prescription summary:
    - Drug name.
    - Dose.
    - Quantity.
    - Token expiry date/time.
  - Warnings:
    - If HIGH‑RISK OVERRIDE: text like “Consult doctor before dispensing.”
    - If EXPIRED/BLOCKED: text like “Token cannot be redeemed.”
- Actions:
  - Button: “Proceed to dispense” (only if status allows).

### 4.5 Pharmacy dispense & burn

**Screen: Pharmacy Dispense & Burn Screen**

- Data:
  - Final prescription items to be dispensed:
    - Drug name.
    - Dose.
    - Quantity.
  - Token details:
    - Token ID.
    - Current state (READY).
- Actions:
  - Checkbox: “I confirm the medications match the prescription.”
  - Button: “Confirm Dispense & Burn Token”.
- Result view:
  - Message: “Dispensed successfully.”
  - Token final state: USED/BURNED.
  - Optional:
    - “Ledger proof recorded” indicator.

---

## 5. Output expectations

The UI design output should include:

- All screens listed above for:
  - Common shell and role selection.
  - Patient portal.
  - Doctor portal.
  - Pharmacy portal.
- Clear navigation between screens:
  - What screen follows what (e.g., Sign‑up → Verification → Login → Unlock → Dashboard).
- Data elements on each screen:
  - Each form field, each data label, each status indicator.
- No styling/theme is required; focus purely on **flows and data placement** so a developer can implement the screens and hook them to APIs and database structures like:
  - `patients`, `doctors`, `doctor_hospital_map`, `doctor_patient_map`, `encounters`, `encounter_notes`, `prescriptions`, `prescription_items`, `availability_cache`, `pharmacy_inventory`, `pharmacies`, `override_events`, `signature_records`, `audit_references`, and `followups`.
