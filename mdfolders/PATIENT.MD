# Patient App Frontend Skeleton – Mock Data Prompt

You are an expert frontend engineer.  
Build a **patient mobile app UI skeleton** with **mock data only**, no real backend calls.

## Tech stack

- Use: **[REPLACE WITH YOUR STACK: e.g., Flutter / React Native / React Web]**
- Use simple **in‑memory mock data** or hard‑coded JSON.
- No authentication, no API integration yet—just screens, navigation, and dummy state.

---

## App structure

Implement the following screens and navigation:

1. SplashPage  
2. OnboardingPage1  
3. OnboardingPage2  
4. OnboardingPage3  
5. RoleSelectionPage  
6. PatientAuthChoicePage  
7. PatientSignUpPage  
8. PatientVerificationPage  
9. PatientLoginPage  
10. PatientSecureSignInPage  
11. PatientUnlockSetupPage  
12. PatientHomeShellPage (tab shell)  
13. PatientDashboardPage  
14. PatientMedicationListPage  
15. PatientHistoryPage  
16. PatientSharePage  
17. PatientSettingsPage  

Assume basic routing / navigation is available (React Navigation / Flutter Navigator / React Router or equivalent).

---

## Screen requirements

### 1. SplashPage (`/splash`)

- Fullscreen.
- Show:
  - App logo placeholder.
  - App name: **“AegisRx”**.
  - Tagline: “Your personal medication safety companion”.
- After 2 seconds, automatically navigate to `/onboarding/1`.

---

### 2. OnboardingPage1 (`/onboarding/1`)

- Illustration placeholder (simple colored box is fine).
- Title: “You control your health data.”
- Body: “AegisRx lets you see your medications and risks in one place.”
- Progress dots: **● ○ ○**
- Button “Next” → `/onboarding/2`
- Text link “Skip” → `/role-selection`

---

### 3. OnboardingPage2 (`/onboarding/2`)

- Illustration placeholder.
- Title: “Share safely with your doctors.”
- Body: “Give your doctors a complete and up‑to‑date view of your medications.”
- Progress dots: **○ ● ○**
- Button “Next” → `/onboarding/3`
- Text link “Skip” → `/role-selection`

---

### 4. OnboardingPage3 (`/onboarding/3`)

- Illustration placeholder.
- Title: “Stay on track with your medicines.”
- Body: “Get reminders and see how well you are following your prescriptions over time.”
- Progress dots: **○ ○ ●**
- Button “Get started” → `/role-selection`

---

### 5. RoleSelectionPage (`/role-selection`)

- Title: “Who are you using AegisRx as today?”
- Three cards:
  - Card 1: “Patient” (selected by default when tapped).
  - Card 2: “Doctor” (non‑functional for now).
  - Card 3: “Pharmacist” (non‑functional for now).
- Button “Continue”:
  - If “Patient” selected → `/patient/auth-choice`.
  - For other roles, just show an alert/toast “Coming soon”.

---

### 6. PatientAuthChoicePage (`/patient/auth-choice`)

- Title: “Sign in or create your patient account”.
- Two clickable cards:
  - Card A: “I am a new patient” → `/patient/signup`
  - Card B: “I already have an account” → `/patient/login`

---

### 7. PatientSignUpPage (`/patient/signup`)

Form fields:

- Full name (text input)
- Date of birth (date picker or text input)
- Gender (dropdown: `Male`, `Female`, `Other`, `Prefer not to say`)
- Country / Region (dropdown: e.g., `India`, `USA`, `UK`)
- Primary mobile number (text)
- Email (optional)
- Password (password input)
- Confirm password (password input)
- Checkbox: “I agree to the Terms and Privacy Policy”
- Inline text links (non‑functional): “Terms of Use”, “Privacy Policy”

Buttons:

- Primary: “Create account”
- Secondary text: “Already have an account? Sign in” → `/patient/login`

**Behavior (mock):**

- When “Create account” is pressed and required fields are non‑empty and passwords match, navigate to `/patient/verify-otp`.
- No real API calls.

---

### 8. PatientVerificationPage (`/patient/verify-otp`)

- Title: “Verify your contact”
- Text: “We sent a 6‑digit code to your mobile number.”
- OTP input: either 6 small boxes or one text field.
- Link: “Didn’t get a code? Resend” → show a toast “Code resent (mock)”.
- Button: “Verify”

**Behavior (mock):**

- If user enters 6 characters and taps “Verify” → navigate to `/patient/login`.

---

### 9. PatientLoginPage (`/patient/login`)

- Title: “Sign in to your health vault”
- Text input: “Mobile number or email”
- Password input: “Password”
- Link: “Forgot password?” → show alert “Coming soon”.
- Button: “Sign in”
- Text: “New to AegisRx? Create account” → `/patient/signup`.

**Behavior (mock):**

- If both fields are non‑empty on “Sign in” → navigate to `/patient/secure-signin`.

---

### 10. PatientSecureSignInPage (`/patient/secure-signin`)

- Icon placeholder (shield/lock).
- Title: “Confirm it’s really you”
- Text: “Use your device to sign in securely.”
- Button: “Sign in securely”

**Behavior (mock):**

- On tap → navigate to `/patient/unlock-setup`.

---

### 11. PatientUnlockSetupPage (`/patient/unlock-setup`)

- Title: “Secure this device”
- Text: “Create a PIN so you can quickly unlock AegisRx on this device.”
- PIN input: “Enter PIN” (4–6 digits)
- PIN confirm: “Confirm PIN”
- Optional toggle: “Use Face ID / Fingerprint” (no real logic)
- Button: “Save and continue”

**Behavior (mock):**

- If PIN and Confirm PIN match and length ≥ 4 → navigate to `/patient/home`.

---

### 12. PatientHomeShellPage (`/patient/home`)

- Contains a **bottom tab bar with 4 tabs**:
  - Dashboard
  - History
  - Share
  - Settings

- Default selected tab: Dashboard.
- Each tab loads a separate inner screen:

  - Tab 1: Dashboard → `PatientDashboardPage`
  - Tab 2: History → `PatientHistoryPage`
  - Tab 3: Share → `PatientSharePage`
  - Tab 4: Settings → `PatientSettingsPage`

Implement tab navigation using your framework’s standard tab/navigation components.

---

### 13. PatientDashboardPage (`/patient/dashboard` inside home)

Use mock data:

```json
{
  "patientName": "Alex",
  "todayDate": "Today, 03 July 2026",
  "todayMeds": [
    { "name": "Metformin 500 mg", "schedule": "Morning and evening", "status": "Due" },
    { "name": "Atorvastatin 10 mg", "schedule": "Night", "status": "Due" }
  ]
}
```

**UI:**

- Header:
  - “Good morning, Alex”
  - “Today, 03 July 2026” (static or based on current date)

- Card: “Today’s medications”
  - For each item in `todayMeds`, show:
    - Name
    - Schedule
    - A small chip or label for `status`.

- Button/link: “See all medications” → `/patient/medications`.

---

### 14. PatientMedicationListPage (`/patient/medications`)

Mock data:

```json
{
  "activeMeds": [
    { "name": "Metformin 500 mg", "details": "Twice daily", "id": "med1" },
    { "name": "Atorvastatin 10 mg", "details": "Once at night", "id": "med2" }
  ],
  "pastMeds": [
    { "name": "Amoxicillin 500 mg", "details": "Stopped - completed 7 day course", "id": "med3" }
  ]
}
```

**UI:**

- App bar:
  - Back button → navigates back to Dashboard.
  - Title: “All medications”.

- Search bar: “Search medications” (no logic required yet).

- Section **“Active medications”**:
  - Render `activeMeds` list:
    - Title: `name`
    - Subtitle: `details`.

- Section **“Past medications”**:
  - Render `pastMeds` list similarly, optionally mark as “Past”.

**Behavior:**

- Tap on any medication → show alert/toast “Medication detail coming soon”.

---

### 15. PatientHistoryPage (`/patient/history`)

Mock data:

```json
[
  {
    "date": "20 June 2026",
    "text": "Started Metformin 500 mg twice daily."
  },
  {
    "date": "25 June 2026",
    "text": "Doctor updated Atorvastatin from 5 mg to 10 mg."
  },
  {
    "date": "28 June 2026",
    "text": "You reported a mild headache."
  }
]
```

**UI:**

- Title: “History”
- Vertical list:
  - Each card shows:
    - Date (smaller text)
    - Main text.

No tap actions required for now.

---

### 16. PatientSharePage (`/patient/share`)

**UI:**

- Title: “Share your information”
- Body text:
  - “Soon you’ll be able to share your medication list and safety report with your doctor and pharmacy from here.”
- Button: “Share with my doctor”
  - Disabled or shows toast “Coming soon”.

---

### 17. PatientSettingsPage (`/patient/settings`)

**UI:**

- Section “Profile”
  - Row: “Personal details” → show alert “Coming soon”.

- Section “Security”
  - Row: “Change PIN” → alert “Coming soon”.
  - Row: “Biometric unlock” with dummy toggle (no logic).

- Section “About”
  - Row: “Terms of Use” → alert “Coming soon”.
  - Row: “Privacy Policy” → alert “Coming soon”.

- Bottom button: “Sign out”
  - Behavior (mock): navigate to `/patient/login`.

---

## Implementation requirements

- Use simple routing for navigation between these screens.
- Use lightweight theming; no complex design system needed.
- Put all mock data as local constants or simple in‑memory stores.
- No external state management library required; basic local state/hooks are enough.
- Ensure it looks reasonable on a typical mobile portrait resolution.

**Output expected:**

- Screen components/widgets for each route.
- Navigation setup that wires all routes/tabs together.
- Mock data wired into UI as described.C