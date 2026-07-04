# Pharmacy Flow Lifecycle – Version 1

This document describes the initial **pharmacy user flow lifecycle** implemented in AegisRx. The pharmacy portal consumes signed e‑prescriptions from the secure ledger/vault, performs clinical and technical verification, dispenses medication, and updates the patient vault.

All screens use the global **60‑30‑10 color rule** from `app_theme.dart` (same as Patient and Doctor portals). [web:266][web:269]

---

## 1. Flow Diagram

```mermaid
flowchart TD

A0[Pharmacy Portal Login] --> A1[Pharmacy Dashboard]

A1 --> A2[Select Prescription Source]
A2 -->|Scan Patient/Prescription QR| B1[Scan QR & Validate Token]
A2 -->|Search by Patient or Rx ID| B2[Search Prescription Ledger]
A2 -->|Refill Queue| B3[Refill / Pending Queue]

B1 -->|Token valid, consent OK| C1[Fetch e‑Prescription from Ledger/Vault]
B1 -->|Invalid/Expired token| B1E[Show error & stop]

B2 -->|Prescription found| C1
B2 -->|Not found| B2E[Show 'No matching prescription']

B3 --> C2[Load Existing Prescription & Refill Rules]

C1 --> D1[Clinical Screening & Verification]
C2 --> D1

subgraph D[Verification Stage]
  D1[Clinical Check\n-  Right patient\n-  Right drug, dose, route, frequency, duration\n-  Interactions & contraindications] --> D2[Technical Check\n-  Stock, expiry, batch\n-  Label details\n-  Billing/coverage]
end

D1 -->|Issues found| D1A[Flag clinical issues\n(contact prescriber)]
D2 -->|Issues found| D2A[Fix or hold Rx]

D2 -->|Pass| E1[Prepare & Package Medication]
E1 --> E2[Final Pharmacist Check]
E2 -->|OK| E3[Mark as Dispensed on Ledger/Vault]
E2 -->|Error| E2A[Correct & Re‑verify]

E3 --> F1[Select Delivery Mode]
F1 -->|In‑store pickup| F2[Pickup Confirmation & Signature]
F1 -->|Home delivery| F3[Delivery & Tracking]

F2 --> G1[Update Patient Vault\nDispense event + instructions]
F3 --> G1

G1 --> H1[Pharmacy Activity Log & History]

D1A --> S1[Send Clarification Request\nback to Doctor Portal]
S1 --> S2[Doctor Updates / Re‑signs Rx]
S2 --> C1

B1E --> H1
B2E --> H1
D2A --> H1
```

---

## 2. Global Design System (60‑30‑10 Rule)

All pharmacy screens resolve their colors from the shared `ThemeData`:

- **60% Dominant Color**  
  Scaffold backgrounds use the main background color (e.g., `0xFF0B0F19` in dark mode).

- **30% Secondary Card & Surface Color**  
  Cards, text fields, tables, and panels use the card/surface color (e.g., `0xFF141C2F`).

- **10% Accent Color**  
  Primary actions, status pills, and indicators resolve to `colorScheme.primary` (e.g., `0xFF818CF8`), with additional success/warning/error accents where needed. [web:266][web:269]

---

## 3. Page‑by‑Page Specifications

### Step 1: Pharmacy Portal Login

- **Screen**: `PharmacyLoginScreen`
- **Description**: Authenticates pharmacy staff into the AegisRx pharmacy console. [web:288]
- **Fields**:
  - Username or official email (TextField)
  - Password (PasswordField)
- **Actions**:
  - Primary button: **“Sign in”**
    - On success (mock): navigate to `PharmacyDashboardScreen`.
  - Secondary text/link: “Forgot password?” → shows recovery info (mock or stub).

---

### Step 2: Pharmacy Dashboard Hub

- **Screen**: `PharmacyDashboardScreen`
- **Description**: Main landing page after successful login; provides a snapshot of current workload. [web:281][web:288]
- **Primary Sections**:
  - **Today’s Queue**:
    - Cards/lists for:
      - New e‑prescriptions
      - Refills due today
      - On‑hold / clarification cases
  - **Quick Actions**:
    - Card/button: “Scan Rx / Patient QR” → `PharmacyScanQRScreen`
    - Card/button: “Search Prescription / Patient” → `PharmacySearchPrescriptionScreen`
    - Card/button: “Open Refill Queue” → `PharmacyRefillQueueScreen`
- **Design/Theme**:
  - Dominant background for entire shell.
  - Cards using secondary surface color with accent borders for important counts.

---

### Step 3: QR Scan – Token Validation

- **Screen**: `PharmacyScanQRScreen`
- **Description**: Used when a patient presents a QR code (from patient app) or when scanning a printed Rx token. [web:285][web:286]
- **UI Elements**:
  - Camera preview window centered on screen.
  - Instruction text: “Align the patient or prescription QR within the frame.”
  - Status label:
    - “Scanning…”
    - “QR recognized, validating…”
    - “Invalid or expired token.”
- **Behavior**:
  - On QR read:
    - Validate token and consent (mock or via backend).
    - If valid → navigate to `PharmacyPrescriptionDetailScreen` with that Rx context.
    - If invalid/expired → show error, allow retry or return to dashboard.

---

### Step 4: Search Prescription / Patient

- **Screen**: `PharmacySearchPrescriptionScreen`
- **Description**: Search and open prescriptions without QR. [web:288]
- **Fields**:
  - Search box: “Patient name / Rx ID / Phone number”
- **UI Elements**:
  - Search button or debounced search.
  - Results list:
    - Patient name / initials
    - Rx ID
    - Date issued
    - Status (New / In progress / Dispensed / On hold)
- **Behavior**:
  - On selecting a result → navigate to `PharmacyPrescriptionDetailScreen`.
  - If no match → show “No matching prescription found.”

---

### Step 5: Refill Queue

- **Screen**: `PharmacyRefillQueueScreen`
- **Description**: Dedicated view for upcoming and due refills. [web:283][web:288]
- **Sections**:
  - Filters/tabs:
    - “Refills due today”
    - “Upcoming refills”
    - “On hold / problem”
  - List row elements:
    - Patient name
    - Rx ID
    - Next refill date
    - Remaining refills
    - Status chip
- **Behavior**:
  - Tap on any refill entry → `PharmacyPrescriptionDetailScreen` with refill context.

---

### Step 6: Prescription Detail (Read‑only View)

- **Screen**: `PharmacyPrescriptionDetailScreen`
- **Description**: Central screen that displays a single e‑prescription fetched from ledger/vault. [web:285][web:286]
- **Header**:
  - Patient:
    - Name
    - Age
    - Gender
    - Key allergies (chips)
  - Prescriber:
    - Doctor name
    - Specialty
    - Registration/licence ID
  - Prescription meta:
    - Rx ID
    - Date issued
    - Current status (New, In verification, Dispensed, On hold)
- **Prescription Body**:
  - Diagnosis / Indication (read‑only)
  - List of medications:
    - Drug name
    - Strength
    - Route
    - Frequency
    - Duration
    - Instructions
- **Actions**:
  - Primary button: **“Start verification”** → `PharmacyVerificationScreen`
  - Secondary button: **“Return / Clarify with prescriber”** → `PharmacyClarificationScreen`
  - Back button → Dashboard or previous list.

---

### Step 7: Verification – Clinical & Technical

- **Screen**: `PharmacyVerificationScreen`
- **Description**: Structured step where pharmacist verifies both clinical appropriateness and technical details. [web:282][web:287][web:284]
- **Sections**:

  1. **Clinical Check Panel**:
     - Checklist controls:
       - “Correct patient matched to Rx”
       - “No known allergy to prescribed drugs”
       - “Dose appropriate for age/weight/renal function (if data available)”
       - “No obvious drug–drug interactions with current meds” (may reuse AI from doctor flow, read‑only)
     - Optional AI risk banner:
       - Risk band (LOW / MODERATE / HIGH / CRITICAL)
       - Short message: “AI found potential interaction with … (doctor already signed/overrode).”

  2. **Technical Check Panel**:
     - Fields:
       - Stock availability (quantity in stock, warnings if low)
       - Batch/lot selection (dropdown)
       - Expiry date selection or display
       - Label details preview (patient name, drug, strength, directions)
       - Basic billing/coverage status (Approved / Not covered / Pre‑auth required)

- **Actions**:
  - Primary: **“Mark verified & proceed to preparation”** → `PharmacyPreparationScreen`
  - Secondary: **“Flag clinical issue and contact prescriber”** → `PharmacyClarificationScreen`
  - Tertiary: **“Hold prescription”** → status = On hold, back to queue/dashboard.

---

### Step 8: Clarification with Prescriber

- **Screen**: `PharmacyClarificationScreen`
- **Description**: Capture pharmacist’s concerns and send them back to the doctor portal/prescriber. [web:281][web:285]
- **UI Elements**:
  - Read‑only header:
    - Patient + Rx summary
  - Text area:
    - Label: “Describe the issue / question for the prescriber.”
  - Quick issue tags (chips, optional):
    - “Dose too high”
    - “Potential interaction”
    - “Duplicate therapy”
    - “Formulation unavailable”
- **Actions**:
  - Primary button: **“Send clarification request”**
    - Mock: store message and mark Rx as `Awaiting prescriber response`.
    - Eventually, this surfaces in doctor portal.
  - Secondary: “Cancel” → return to `PharmacyPrescriptionDetailScreen`.

---

### Step 9: Preparation & Packaging

- **Screen**: `PharmacyPreparationScreen`
- **Description**: After verification, used to prepare and package each medication. [web:284]
- **UI Elements**:
  - List of Rx items:
    - Drug name, strength
    - Quantity to prepare
  - For each item:
    - Batch/lot selector
    - Expiry date display (from inventory)
    - Editable quantity if needed (with validations)
  - Label preview component:
    - Shows final printed label text: patient name, drug, dose, route, frequency, instructions.
- **Actions**:
  - Primary: **“Mark all as prepared”** → `PharmacyFinalCheckScreen`
  - Option: “Back to verification” to re‑check.

---

### Step 10: Final Pharmacist Check

- **Screen**: `PharmacyFinalCheckScreen`
- **Description**: Last safety gateway before marking the Rx as dispensed. [web:284]
- **UI Elements**:
  - Prepared items summary table:
    - Medication, strength, quantity, selected batch/expiry.
  - Optional barcode scanning area:
    - “Scan container barcode to confirm drug & strength.”
  - Checklist:
    - “Correct patient name on label.”
    - “Correct medication and strength.”
    - “Correct quantity prepared.”
    - “No visible damage or contamination.”
- **Actions**:
  - Primary: **“Confirm and mark as dispensed”**
    - Records a **dispense event** on the ledger/vault.
    - Transitions to `PharmacyDeliveryModeScreen`.
  - Secondary: “Error detected – send back to preparation”
    - → `PharmacyPreparationScreen`.

---

### Step 11: Delivery Mode Selection

- **Screen**: `PharmacyDeliveryModeScreen`
- **Description**: Choose how the medication will reach the patient. [web:283][web:284]
- **Options**:
  - **In‑store pickup**
  - **Home delivery**
- **Behavior**:
  - If **In‑store pickup** → `PharmacyPickupConfirmationScreen`
  - If **Home delivery** → `PharmacyDeliveryTrackingScreen`

---

### Step 12: Pickup Confirmation & Signature

- **Screen**: `PharmacyPickupConfirmationScreen`
- **Description**: Record that the patient (or authorized agent) collected the dispensed medication. [web:284]
- **UI Elements**:
  - Summary:
    - Patient name, Rx ID
    - List of dispensed items
  - Input:
    - Signature pad or checkbox “Collected by patient/authorized agent”
    - Optional ID type/number for pickup person
- **Actions**:
  - Primary: **“Confirm pickup”**
    - Marks the dispense event as **picked up** in the vault.
    - Updates patient vault with:
      - Dispense timestamp
      - Lot/expiry
      - Directions/instructions
    - Returns to `PharmacyDashboardScreen`.

---

### Step 13: Delivery Tracking & Status

- **Screen**: `PharmacyDeliveryTrackingScreen`
- **Description**: Used when pharmacy arranges delivery to the patient’s location. [web:283][web:284]
- **Fields**:
  - Delivery provider (dropdown or text)
  - Tracking ID (text)
  - Status indicator:
    - Pending
    - Out for delivery
    - Delivered
    - Failed / Returned
- **Actions**:
  - Button: **“Mark as delivered”**
    - Updates ledger/vault with delivered status and timestamp.
  - Button: **“Mark as failed / returned”**
    - Requires a reason (e.g., “Wrong address”, “Patient not available”).
    - Reflects in activity log and patient vault.

---

### Step 14: Pharmacy Activity Log & History

- **Screen**: `PharmacyActivityLogScreen`
- **Description**: Historical view of pharmacy actions for audit and quality control. [web:281][web:284]
- **Filters**:
  - Date range selector
  - Status filter:
    - Dispensed
    - On hold
    - Awaiting clarification
    - Returned / Failed delivery
- **Log Entries**:
  - Timestamp
  - Patient name / ID
  - Rx ID
  - Action summary:
    - “Dispensed and picked up”
    - “Clarification sent to prescriber”
    - “Delivery failed – wrong address”
  - Pharmacist / user ID
- **Use Cases**:
  - Internal QA, regulatory audits, and reconciliation with billing and inventory.

---

## 4. Screen Checklist

For implementation, the pharmacy portal should provide at least these screens:

1. `PharmacyLoginScreen`  
2. `PharmacyDashboardScreen`  
3. `PharmacyScanQRScreen`  
4. `PharmacySearchPrescriptionScreen`  
5. `PharmacyRefillQueueScreen`  
6. `PharmacyPrescriptionDetailScreen`  
7. `PharmacyVerificationScreen`  
8. `PharmacyClarificationScreen`  
9. `PharmacyPreparationScreen`  
10. `PharmacyFinalCheckScreen`  
11. `PharmacyDeliveryModeScreen`  
12. `PharmacyPickupConfirmationScreen`  
13. `PharmacyDeliveryTrackingScreen`  
14. `PharmacyActivityLogScreen`

All logic can be **mocked** initially (no real APIs), while preserving the exact flow and structure described above so it aligns with the patient and doctor portals.