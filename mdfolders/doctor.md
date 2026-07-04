# AegisRx Doctor Portal – Complete Flow Specification (Version 1)

This document specifies the **doctor portal** flow for AegisRx, matching the depth and structure of the patient flow. It assumes Splash + Onboarding are **shared** for all three portals and focuses only on the **doctor side**.

All screens use the global 60‑30‑10 theme from `app_theme.dart` (same as patient app). [web:266][web:269]

---

## 1. High‑Level Flow (QR + Auto‑AI)

1. Doctor logs in to the doctor portal.  
2. Doctor opens dashboard → selects patient via search or QR scan.  
3. QR scan starts a **live session** with that patient and auto‑fills patient + doctor header.  
4. Doctor fills **structured fields**:
   - Problem / diagnosis  
   - Medicines (structured rows)  
5. AI safety check runs **automatically** whenever problem/med fields change. [web:254][web:256][web:277]  
6. AI result appears in a **separate panel/screen**:
   - Risk band, score, reasons, safer alternatives.  
7. Doctor either:
   - Accepts AI suggestions, or  
   - Overrides and signs with rationale → prescription committed to chain / vault. [web:276][web:279]

---

## 2. Onboarding & Verification (Doctor)

### 2.1 DoctorOnboardingRequestScreen (optional)

**Purpose:** Capture doctor information for admin verification before enabling full console access.

**Suggested file:**  
`lib/features/doctor/screens/auth/doctor_onboarding_request_screen.dart`

**Fields:**

- Full name (text)  
- Medical license / registration ID (text)  
- Hospital / clinic name (text)  
- Specialty (dropdown: Cardiology, Internal Medicine, etc.)  
- Official email (text)  
- Official phone (text)  
- Checkbox: “I confirm these details are accurate”

**Action:**

- Button: **“Submit verification request”**
  - For now: mock submit  
  - On success → `DoctorVerificationStatusScreen`

---

### 2.2 DoctorVerificationStatusScreen

**Purpose:** Show whether the doctor is allowed to use the portal.

**Suggested file:**  
`lib/features/doctor/screens/auth/doctor_verification_status_screen.dart`

**Displays:**

- Doctor name  
- Hospital / clinic  
- Specialty  
- Status badge: **Pending / Verified / Suspended**

**Behavior:**

- **Pending:**  
  - Message: “Verification in progress. You can view limited data.”  
  - No login button.

- **Verified:**  
  - Button: “Go to Doctor Login” → `DoctorLoginScreen`.

- **Suspended:**  
  - Message: “Your account is suspended. Contact support.”

---

## 3. Doctor Login & Entry

### 3.1 DoctorLoginScreen

**Purpose:** Authenticate doctor into the doctor portal.

**Suggested file:**  
`lib/features/doctor/screens/auth/doctor_login_screen.dart`

**Fields:**

- Email (text)  
- Password (password)

**Actions:**

- Button: **“Sign in”**
  - If fields not empty → mock success → navigate to `DoctorDashboardScreen`.

---

## 4. Doctor Dashboard & Starting a Session

### 4.1 DoctorDashboardScreen

**Purpose:** Main landing screen after doctor login.

**Suggested file:**  
`lib/features/doctor/screens/main/doctor_dashboard_screen.dart`

**Content (mock data acceptable):**

- **Header:**
  - Dr. [Name]  
  - Specialty (e.g., Cardiologist)  
  - Hospital / clinic

- **Section: “Today’s appointments”**
  - List of 2–3 appointments:
    - Patient name / ID  
    - Time  
    - Reason

- **Section: “Active consultations”**
  - List of currently active QR sessions (mock).

- **Section: “Alerts / AI findings” (optional)**  
  - Simple cards:  
    - “High‑risk override yesterday – Patient X”

**Primary action:**

- Button: **“Search patient / Scan QR”** → `DoctorPatientSearchScreen`.

---

## 5. Patient Selection & QR Session

### 5.1 DoctorPatientSearchScreen

**Purpose:** Let doctor pick a patient via search or start a live session via QR scan.

**Suggested file:**  
`lib/features/doctor/screens/session/doctor_patient_search_screen.dart`

**Search part:**

- Search input: “Patient name / ID / phone”  
- Search button → fills list with mock patients:
  - Name/initials  
  - Age  
  - Last encounter date  

**On tapping a search result:**

- Navigate to `DoctorPatientHistoryScreen(patientId)`.

**QR section:**

- Label: “Scan patient QR”  
- Camera preview placeholder  
- Status text: “Scanning… / QR recognized / Invalid QR”

**On QR recognized:**

- Mock validation of patient consent token.  
- Start a **Doctor–Patient session** (sessionId).  
- Navigate to `DoctorPatientHistoryScreen(sessionId, patientId)`. [web:272][web:278]

---

## 6. Patient History (Doctor View)

### 6.1 DoctorPatientHistoryScreen

**Purpose:** Read‑only overview of this patient’s history, as seen by the doctor.

**Suggested file:**  
`lib/features/doctor/screens/session/doctor_patient_history_screen.dart`

**Sections (mock data):**

- **Patient header:**
  - Name / initials  
  - Age  
  - Gender  
  - Allergies (chips)  
  - Chronic conditions (chips)

- **Encounter timeline:**
  - List:
    - Date  
    - Reason / diagnosis  
    - Short note summary

- **Prescription history:**
  - List:
    - Date  
    - Drugs summary, e.g., “Metformin 500 mg BD; Atorvastatin 10 mg OD”  
    - Risk band badge: LOW / MOD / HIGH / CRITICAL  
    - Override flag icon if any override was done

**Action:**

- Button: **“Write new prescription”** → `DoctorPrescriptionEditorScreen(sessionId, patientId)`.

---

## 7. Structured Prescription Editor + Auto AI

### 7.1 DoctorPrescriptionEditorScreen

**Purpose:** Allow doctor to write a new prescription in a **structured way** so AI can analyze it automatically.

**Suggested file:**  
`lib/features/doctor/screens/prescription/doctor_prescription_editor_screen.dart`

**Header (auto‑filled, read‑only):**

- **Patient:**
  - Name  
  - Age  
  - Gender  
  - Allergies  
  - Chronic conditions  

- **Doctor:**
  - Name  
  - Specialty  
  - License number  
  - Hospital / clinic  

These come from the QR session + doctor profile.

---

### 7.2 Encounter / Problem fields

Editable fields:

- **Chief complaint / Problem**  
  - Multi‑line text  
  - Label: “Chief complaint / Problem *”  
  - Example: “Fever and cough for 3 days, no breathlessness.”

- **Provisional diagnosis**  
  - Single line text  
  - Label: “Provisional diagnosis *”

- **Clinical notes (optional)**  
  - Multi‑line text  
  - Label: “Clinical notes”

These map to encounter records for this session.

---

### 7.3 Structured medication rows

Each prescription item row includes:

- **Drug name** (Text / autocomplete)  
- **Strength** (Text; e.g., “500 mg”)  
- **Route** (Dropdown: Oral / IV / IM / Topical / Inhalation)  
- **Frequency** (Dropdown or Text: “Twice daily”, “Once at night”)  
- **Duration value** (Number; e.g., 7)  
- **Duration unit** (Dropdown: days / weeks / months)  
- **Special instructions** (Optional Text area; e.g., “After food”)

UI:

- Button: **“Add medicine”** to append new rows.  
- Ability to remove rows.

---

### 7.4 Automatic AI safety audit

**Behavior:**  
The AI safety check runs **automatically**; doctor does not need to manually “give access” or click a big “Run AI” button.

**When to trigger:**

- When any of these change:
  - Chief complaint / Problem  
  - Provisional diagnosis  
  - Any medication row field (name, dose, route, frequency, duration, instructions)

**Implementation idea:**

- Debounce changes (e.g., 500–800 ms after last keystroke).  
- Build an `AuditRequest` object with:
  - Patient context: allergies, conditions, current medications (from history).  
  - Encounter: problem, provisional diagnosis, clinical notes.  
  - Draft prescription: all medication rows. [web:256][web:257][web:277]  
- Call `/api/audit` (or a mock function) in the background.  
- Update AI panel with the response.

There may still be a small **“Re‑run AI”** button for manual refresh, but AI should normally keep itself up‑to‑date.

---

## 8. AI Safety Panel / Screen

### 8.1 AI Safety & Suggestions Panel

**Purpose:** Display AI analysis separately from the doctor’s text fields.

**Implementation options:**

- **Desktop / tablet:** Right‑side panel next to editor.  
- **Mobile:** Collapsible bottom sheet or modal.

**Fields in panel (from audit response):**

- **Risk band:** LOW / MODERATE / HIGH / CRITICAL  
- **Risk score:** 0–100  
- **Key risk reasons:** bullet list, e.g.:
  - “Interaction with Warfarin – increased bleeding risk.”  
  - “Dose exceeds recommended limit for age.”  

- **Safe alternatives list:**
  - “Paracetamol instead of Ibuprofen for this patient.”  
  - “Reduce dose to 250 mg twice daily.”

- **Override policy note:**
  - “Override allowed only with clinical rationale for HIGH/CRITICAL risks.”

**Actions:**

- **Button: “Apply safe alternative”**
  - Let doctor choose one suggestion.  
  - Update the corresponding medication row(s) in the editor.

- **Button: “Proceed with override”**
  - Enabled only if `override_allowed = true`.  
  - Navigates to `DoctorOverrideAndSignScreen(draftPrescriptionId, auditId)`.

You can also keep a dedicated `DoctorAiAuditResultScreen` route that shows the same information if you prefer a full page instead of a panel.

---

## 9. Override & Sign

### 9.1 DoctorOverrideAndSignScreen

**Purpose:** Allow doctor to consciously override AI warnings and sign the prescription with rationale; then commit to chain/vault. [web:276][web:279]

**Suggested file:**  
`lib/features/doctor/screens/prescription/doctor_override_and_sign_screen.dart`

**Display (read‑only):**

- Patient summary (name, age, key conditions).  
- Problem / diagnosis.  
- Final prescription summary:
  - List of medicines with all fields.  
- AI risk band + key reasons.

**Inputs (required when risk band ≥ HIGH):**

- **Override rationale** (multi‑line text area):  
  - “Why are you proceeding despite the risk?”

- **Override category** (dropdown):  
  - Emergency  
  - Clinical judgment  
  - Other

- **Acknowledgement checkbox:**  
  - “I acknowledge the risks and take responsibility as the treating physician.”

**Actions:**

- **Button: “Sign & Commit”**

  - Validation:
    - If risk band ≥ HIGH:
      - Rationale not empty  
      - Category selected  
      - Checkbox checked  

  - Behavior (mock for now):
    - Mark prescription as **SIGNED** in local/mock store.  
    - Record override event with rationale and category.  
    - Simulate a blockchain/IPFS commit by generating a fake transaction/hash.

  - Navigation:
    - Show success message.  
    - Navigate back to `DoctorDashboardScreen`.

- **Button: “Back to editor”**
  - Returns to `DoctorPrescriptionEditorScreen` without signing.

---

## 10. Doctor Screen List (Checklist)

To mirror the completeness of the patient flow, you should have the following Flutter screens (even if some include only mock data initially):

1. `DoctorOnboardingRequestScreen` (optional but recommended)  
2. `DoctorVerificationStatusScreen`  
3. `DoctorLoginScreen`  
4. `DoctorDashboardScreen`  
5. `DoctorPatientSearchScreen`  
6. `DoctorPatientHistoryScreen`  
7. `DoctorPrescriptionEditorScreen`  
8. AI safety panel or `DoctorAiAuditResultScreen`  
9. `DoctorOverrideAndSignScreen`

All should:

- Use the **same theme** as the main app. [web:266][web:269]  
- Use **mock data only** at this stage (no real APIs required).  
- Follow the QR → history → structured editor → auto AI → override & sign sequence described above.