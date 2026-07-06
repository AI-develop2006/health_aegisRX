# 🛡️ AegisRx / HealthLock - Codebase Structure & Testing Map

This document outlines the final directory structure, service layout, and interactive end-to-end testing flows for the AegisRx patient-sovereign health ecosystem.

---

## 📁 Codebase Directory Tree

```
health_lock/
├── lib/                                     # FLUTTER MOBILE APP CORE
│   ├── main.dart                            # Entry, App theme injection & Provider initialization
│   ├── firebase_options.dart                # Firebase authentication credentials
│   │
│   ├── core/                                # System Core Modules
│   │   ├── crypto/
│   │   │   └── crypto_helper.dart           # SHA-256 and proof/token signature verification
│   │   ├── network/
│   │   │   └── api_client.dart              # API client adding Cognito authentication headers
│   │   ├── routing/
│   │   │   └── app_router.dart              # Listen-based dynamic AppRouterDelegate routing
│   │   ├── state/
│   │   │   └── app_state.dart               # ChangeNotifier holding UserRole & login sessions
│   │   └── theme/
│   │       └── app_theme.dart               # Theme configs (CardThemeData, deep sovereign blue)
│   │
│   ├── features/                            # Screen Features Modules
│   │   ├── patient/
│   │   │   ├── screens/
│   │   │   │   ├── patient_login_screen.dart     # Patient auth portal
│   │   │   │   ├── patient_dashboard_screen.dart # Vault panel showing active logs & risk indicators
│   │   │   │   ├── patient_history_screen.dart   # Old prescription records logs list
│   │   │   │   ├── patient_qr_share_screen.dart  # Presents scanning attendance QRs
│   │   │   │   └── patient_settings_screen.dart  # Settings management & session locks
│   │   │   └── widgets/
│   │   │       ├── risk_gauge.dart               # Safety Index circle rating gauge
│   │   │       ├── danger_banner.dart            # Allergy alert indicators
│   │   │       ├── dose_timeline.dart            # Daily intake schedule tracker
│   │   │       ├── inventory_tracker.dart        # Remaining pill stock bar indicator
│   │   │       └── consultation_status_chip.dart # Active consultation status pill
│   │   │
│   │   ├── doctor/
│   │   │   ├── screens/
│   │   │   │   ├── doctor_login_screen.dart      # Doctor identity checker
│   │   │   │   ├── doctor_dashboard_screen.dart  # Dashboard showing active sessions
│   │   │   │   ├── doctor_patient_search_screen.dart  # Patient directory database queries
│   │   │   │   ├── doctor_patient_history_screen.dart # Vault logs lookup
│   │   │   │   ├── doctor_prescription_editor_screen.dart # Prescription compiler UI
│   │   │   │   ├── doctor_ai_audit_result_screen.dart    # Cerebras safety highlights
│   │   │   │   └── doctor_override_and_sign_screen.dart   # Sign checks overriding rationales
│   │   │   └── widgets/
│   │   │       ├── interaction_warning_card.dart # Highlight warnings in composer
│   │   │       ├── override_reason_sheet.dart    # Rationales bottom form prompt
│   │   │       └── audit_badge.dart              # High/Medium/Low rating indicator badge
│   │   │
│   │   └── pharmacy/
│   │       ├── screens/
│   │       │   ├── pharmacy_login_screen.dart        # Pharmacist license verification
│   │       │   ├── pharmacy_scan_screen.dart         # Checkout QR target camera scanner
│   │       │   ├── pharmacy_verification_screen.dart # Re-hash checking console
│   │       │   └── pharmacy_dispense_screen.dart     # Dispense & burn triggers
│   │       └── widgets/
│   │           ├── token_status_chip.dart        # Active/Burned indicator
│   │           ├── dispense_confirm_button.dart # Rationale double checking trigger
│   │           └── ledger_status_banner.dart     # Ledger commit status indicator
│   │
│   └── shared/                              # Shared layout items
│       ├── models/
│       │   ├── user_profile.dart            # User profile data model
│       │   ├── prescription.dart            # Prescription item serialization model
│       │   ├── encounter.dart               # Consultation encounter session details
│       │   ├── risk_snapshot.dart           # Safety indices status details
│       │   └── token_state.dart             # Status updates logs details
│       └── widgets/
│           ├── neon_card.dart               # Glassmorphic containers
│           ├── glassmorphic_button.dart     # Tap elements with back-drop filters
│           └── loading_overlay.dart         # Dim progress overlays
│
├── backend-ai/                              # FASTAPI BACKEND SERVER CODE
│   ├── app.py                               # Routing engines & local storage fallbacks
│   ├── ai_core.py                           # MongoDB connectors + Cerebras LLM + IsolationForest
│   ├── config.py                            # Settings configuration loader and logging setup
│   ├── requirements.txt                     # Dependencies log
│   ├── insert_sample_data.py                # Database seeder file
│   └── public/                              # Portal HTML, CSS & Web utilities
│       ├── doctor-login.html
│       ├── doctor-prescription.html
│       ├── pharmacy-portal.html
│       └── css/style.css
```

---

## 📡 REST API Routing Reference

* **Prescriptions**:
  * `GET  /api/prescriptions?patient=<name>` — Load history logs.
  * `POST /api/prescriptions` — Sign and append a new prescription.
  * `GET  /api/prescriptions/{rx_id}` — Load details of a specific prescription.
  * `POST /api/prescriptions/dispense` — Mark prescription as dispensed.
* **Encounters & Sessions**:
  * `POST /api/consultation/request` — Doctor session requests.
  * `GET  /api/consultation/pending?patient=<name>` — Polling loop checks.
  * `POST /api/consultation/accept` — Consent approvals.
* **AI Clinical Audits**:
  * `POST /api/audit` — Returns full safety audit (Duplicate + Interaction + Allergy + Recommendation).
  * `GET  /api/pattern-analysis/{doctor_id}` — IsolationForest anomaly scoring.

---

## 🔬 Core Testing & Verification Flow

### 1. Launch Services
```bash
# Terminal 1: Spin up backend
cd backend-ai
python app.py

# Terminal 2: Run Flutter App
flutter run
```

### 2. Sandbox Scenario Test Checklist

| Stage | Checkpoint | Verification | Status |
| :--- | :--- | :--- | :---: |
| **Auth** | App startup redirects to [PatientLoginScreen](file:///c:/Users/srima/hackathon%20votexa/health_lock/lib/features/patient/screens/patient_login_screen.dart) | Enter credentials and tap "Unlock". State is injected via `Provider` and routing switches. | ✅ |
| **Consent** | Session QR code is shared via [PatientQrShareScreen](file:///c:/Users/srima/hackathon%20votexa/health_lock/lib/features/patient/screens/patient_qr_share_screen.dart) | Doctor scans QR (or manually submits request on `/doctor-login`). App intercepts request and pops up approval card. | ✅ |
| **Audit** | Write prescription on `/doctor-prescription` | Click "Run Pre-flight Clinical Audit". Server evaluates allergies (DB) & interactions (Cerebras LLM) and returns warning alerts. | ✅ |
| **Signing** | Submit & cryptographically sign prescription | Backend computes `SHA-256` of JSON string, applies hex-shift cipher based on Doctor NPI, and writes to MongoDB. | ✅ |
| **Verify** | Pharmacist scans on `/pharmacy-portal` | Verification checks compute local hash, reverse hex-shift with Doctor ID, and confirm integrity: `Computed Hash == Decrypted Hash`. | ✅ |
| **Burn** | Click "Dispense Medications" | Status flags set to `isDispensed = true` in DB. Log event written to ledger, and QR code token becomes void. | ✅ |
