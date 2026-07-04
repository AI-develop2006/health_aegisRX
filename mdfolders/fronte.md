# AegisRx — UI Prompt & Design Specification
**Version:** 2.0 (Finalized & Unified System Spec)  
**Theme Profile:** Sovereign Teal-Indigo Fusion (Balanced Dual-Mode)

Use this document directly as a prompt in design generation engines (Figma AI, v0, Uizard) or as a developer specification sheet to build the AegisRx frontend interface.

---

## 1. Design Philosophy

AegisRx uses a **dual-surface visual language** to convey trust, clarity, and security:
*   **Balance over Monochrome:** The app shell (onboarding, login flows, forms, and everyday navigation) uses a light, warm-neutral canvas to provide breathing room and build user trust.
*   **Contextual Dark Panels:** High-security or specialized clinical screens (such as AI audits, hardware authentication checks, and prescription dispensing desks) use dark, elevated obsidian surfaces to demand attention and signal clinical security.
*   **Elevation over Borders:** Uses soft shadows and subtle surface-color variations instead of hard, technical outline borders.
*   **Humanist Geometry:** Cards feature rounded corners ($12\text{px}$–$16\text{px}$), buttons and input fields utilize ($8\text{px}$), and status chips or avatars are fully rounded pill shapes.
*   **Motion as a Security Signal:** State transitions (MFA code checks, clinical check evaluations, signature verification success) utilize smooth ease-out animations to feel organic and responsive.

---

## 2. Color Palette & Typography

### Unique Custom Palette: Sovereign Teal-Indigo Fusion
This palette uses warm off-whites for the light surface elements and deep navy-obsidian tones for high-focus panels, tied together with clinical neon teal and electric indigo accents.

| Token | Light Surface (Everyday Shell) | Dark Elevated (Security Context) | Description |
| :--- | :--- | :--- | :--- |
| **Background** | `#F5F6FA` (warm porcelain) | `#0B0F19` (abyssal obsidian) | Main screen backdrop |
| **Surface / Card** | `#FFFFFF` (clean white) | `#141C2F` (elevated slate-navy) | Card panels, dashboard widgets, modal dialogs |
| **Primary** | `#4F46E5` (Sovereign Indigo) | `#818CF8` (Electric Indigo) | Core action buttons, active navigation, state indicators |
| **Secondary / Accent** | `#0D9488` (Clinical Teal) | `#2DD4BF` (Electric Neon Teal) | Branding highlights, primary scan buttons, check highlights |
| **Text Primary** | `#0F172A` (Obsidian Dark) | `#F8FAFC` (Pure Light slate) | Headings, labels, primary readable content |
| **Text Muted** | `#64748B` (Slate Gray) | `#94A3B8` (Cool Slate) | Helper hints, subtitles, disabled icons, placeholder text |
| **Border / Divider** | `#E2E8F0` (Porcelain border) | `#1E293B` (Dark border lines) | Thin separator lines, static layouts |

### Semantic Status Colors
These status colors remain identical across both light and dark backgrounds to maintain consistent clinical mapping.

| Meaning | Color Hex | Color Name | UI Usage |
| :--- | :--- | :--- | :--- |
| **Low Risk / Verified / Active** | `#10B981` | Emerald Green | Low safety risk levels, verified credentials, active token tags |
| **Moderate Risk / Pending** | `#F59E0B` | Amber Yellow | Mid-level warnings, pending credentials |
| **High Risk / Override** | `#F97316` | Orange | High-risk clinical flags, override input alerts |
| **Critical / Blocked / Expired** | `#EF4444` | Crimson Red | Critical allergy blocks, expired session tokens |
| **Info / Neutral System** | `#3B82F6` | Royal Blue | Hardware key states, system info alerts |

### Typography Specifications
*   **Display & Headlines:** **Sora** (Geometric, friendly but modern, used for titles and heavy scores)
*   **UI & Body Text:** **Inter** (Excellent readability, used for forms, navigation labels, and descriptions)
*   **Data & Monospace:** **JetBrains Mono** (Used for token IDs, signature hashes, OTP inputs, and ledger items)

---

## 3. Splash Screen & Transition Specification

To create a premium user experience, the entry flow utilizes a structured, multi-phase entry sequence:
1.  **Phase 1 (0.0s - 0.4s) — Logo Reveal:** The AegisRx shield/lock vector mark draws on (opacity transitions $0\% \to 100\%$ with a scale transition $0.9 \to 1.0$, using ease-out).
2.  **Phase 2 (0.4s - 0.9s) — Pulse/Security Initializer:** A soft radial pulse ring expands outward from the lock mark and fades, indicating vault decryption is preparing.
3.  **Phase 3 (0.9s - 1.3s) — Wordmark Slide:** The wordmark "AegisRx" slides up by $8\text{px}$ and fades in.
4.  **Phase 4 (1.3s - 1.8s) — Tagline Fade:** The tagline *"Patient-sovereign health, safely shared."* fades in below.
5.  **Phase 5 (1.8s - 2.2s) — Exit Cross-fade:** The splash elements scale down slightly and cross-fade directly into the onboarding carousel.

---

## 4. Screen-by-Screen UI Layout Requirements

### 1. App Entry & Role Selection (Light Surface Theme)
*   **Splash Screen:** Features the Dark Elevated surface (`#0B0F19`) to create a secure first impression, rendering the logo reveal sequence.
*   **Onboarding Carousel:** 3-step swipable deck displaying light illustrations detailing patient-owned vaults, limited-access doctor requests, and automated AI security scans.
*   **Role Choice Screen:** Title: *"Choose how you want to use AegisRx."* Three large, clickable cards for **Patient**, **Doctor**, and **Pharmacist**. Tapping a card shows a short helper description and reveals a primary button to proceed.

### 2. Patient Portal (Balanced Dual-Mode Theme)
*   **Sign-Up Screen (Light Surface):** Form asking for Full Name, Date of Birth, Email/Phone, and Privacy policy checkbox. Uses a clear step-indicator banner at the top.
*   **MFA/SMS Verification (Light Surface):** Verification card showing a 6-digit input slot (using `JetBrains Mono` for spacing) and resend timers.
*   **Cognito Login Screen (Light Surface):** Secure fields for credentials with standard "Forgot Password" links.
*   **App Device Unlock (Light Surface):** Displays local biometric request dialog or 4-to-6 digit custom PIN lock screens to decrypt the local cache.
*   **Patient Dashboard (Light Surface Shell, Dark Elevated Dashboard Panels):**
    *   *Header:* Patient initials avatar and current connectivity status badge.
    *   *Risk Panel:* Dark Elevated card housing a radial **Risk Gauge** (ranging green $\to$ red) and a **Danger Banner** explaining active penicillin allergies.
    *   *Medication Hub:* Timelines detailing Morning/Noon/Night doses, and progress bars indicating remaining inventory.
    *   *Actions:* Easy access shortcuts to "View History" and "Generate QR Session".
*   **QR Share Screen (Light Surface):** Generates the dynamic consent token QR code with an active countdown timer ring around it.

### 3. Doctor Portal (Balanced Dual-Mode Theme)
*   **Doctor Registration Request (Light Surface):** Professional form requiring Full Name, Medical Registration ID / NPI, Clinic/Hospital name, and Specialty.
*   **Review Status Screen (Light Surface):** Shows pending review statuses. Prevents prescription writing until credentials are confirmed.
*   **Doctor Login Screen (Light Surface):** Standard credentials screen leading to clinical dashboard access.
*   **Doctor Dashboard (Dark Elevated Theme):**
    *   Shows clinical consultation queues, emergency notification logs, and active linked sessions.
*   **Prescription Editor (Dark Elevated Theme):**
    *   Inputs for Drug name, Dosage strength, frequency, route, and clinical indication.
    *   A primary button labeled **"Run AI Safety Audit"** which fires calls to the clinical checker.
*   **AI Audit Results Modal (Dark Elevated Theme):**
    *   Displays colored alerts warning of any drug-drug conflicts or dosage overrides parsed from the LLM.
    *   Offers action buttons: *"Apply Recommended Alternative"* or *"Proceed with Clinical Override"*.
*   **Override & Cryptographic Signing Console (Dark Elevated Theme):**
    *   Form requiring text input for the override justification.
    *   Computes and displays the SHA-256 hash of the payload in a monospace container.
    *   Doctor clicks "Sign & Write" to authorize the write operation with their digital key.

### 4. Pharmacy Portal (Balanced Dual-Mode Theme)
*   **Pharmacist Login (Light Surface):** Workstation credentials screen including store numbers and NPI checks.
*   **Hardware Terminal Authentication (Dark Elevated Theme):**
    *   Prompts the staff member to connect their security token (e.g., YubiKey) or confirm trust on the registered browser terminal.
    *   Displays green active checks for verified hardware keys and red blocks for untrusted stations.
*   **Prescription Intake Scanner (Light Surface Scan Window):**
    *   Utilizes the camera viewport to scan the patient's checkout QR. Includes a manual text entry fallback at the bottom for quick lookups by ID.
*   **Intake Verification Desk (Dark Elevated Theme):**
    *   Renders decryption integrity progress (compares signature hashes).
    *   Displays patient age category, drug count details, and warning flags if overrides were signed by the doctor.
*   **Dispense & Burn Console (Dark Elevated Theme):**
    *   Displays confirmation checkboxes validating items and dosage.
    *   Contains the primary action button: **"Dispense & Invalidate Token"**. Once pressed, changes status to "Burned" to block double-dispensing.

---

## 5. Design System Tokens (For Developer Handoff)

| Token / Design Attribute | Value | Specifications |
| :--- | :--- | :--- |
| **Corner radius — card** | `16px` | Applied to content cards, dashboards, and modal overlays |
| **Corner radius — input / button** | `8px` | Enforced on forms, inputs, and button widgets |
| **Corner radius — chip / pill / avatar** | `999px` | Used for status pills, badges, and user avatar pictures |
| **Spacing Scale** | `4px / 8px / 12px / 16px / 24px / 32px / 48px` | Dynamic margin spacing system |
| **Drop Shadow (Light surface cards)** | `0 2px 8px rgba(0,0,0,0.06)` | Soft, diffused shadow for visual elevation |
| **Elevation (Dark mode cards)** | Base background color + 6% lightness | Visual depth relative to background layers |
| **Micro-Transitions** | `120ms` ease-out | Interaction feedback (hover states, click animations) |
| **State-Change Animations** | `200ms` - `250ms` ease-out | Broad status changes (verifications, login completion) |
| **Splash Sequence Time** | `1.8s` - `2.2s` total | Drawing, pulsing, and fading durations |
| **Minimum Tap Target Size** | `48px` × `48px` | Ensures high usability and touchscreen compatibility |

---

## 6. Handoff Notes

*   **Reusable Components:** Deliver all variants (such as Light Surface and Dark Elevated cards or inputs) under unified Figma component sets. Do not duplicate components into separate files.
*   **Status Variants:** Status tags (such as `ACTIVE`, `PENDING`, `EXPIRED`, `BLOCKED`) must map to their semantic colors consistently, regardless of whether they are rendered inside light or dark panels.
*   **Assets:** Provide the splash screen logo reveal as a clean Lottie JSON file to allow direct mobile implementation.