# AegisRx Full Application - TextField Register

This document provides a registry of all input fields, TextFields, password controls, and verification inputs used across the Patient, Doctor, and Pharmacy portals of AegisRx.

---

## 1. Patient Portal Input Fields

| Screen / Feature | Field Name (Label) | Input Type | Validation / Constraints |
| :--- | :--- | :--- | :--- |
| **Sign Up** | Full Name * | Text (Capitalized) | Required, cannot be blank |
| **Sign Up** | Mobile number * | Phone | Required, digits only |
| **Sign Up** | Email address | Email Address | Optional |
| **Sign Up** | ID Number * | Text | Required, cannot be blank |
| **Sign Up** | Password * | Obscure Text | Required, matches Confirm Password |
| **Sign Up** | Confirm Password * | Obscure Text | Required, matches Password |
| **OTP Verification** | Verification Code | Monospace Text | Required, exactly 6 digits |
| **Login** | Mobile number or email * | Text / Phone | Required |
| **Login** | Password * | Obscure Text | Required |
| **PIN Setup** | Enter PIN (4-6 digits) * | Obscure / Numeric | Required, 4-6 digits, matches Confirm |
| **PIN Setup** | Confirm PIN * | Obscure / Numeric | Required, 4-6 digits, matches PIN |
| **Local Device Unlock** | Enter Passcode | Obscure / Numeric | Required, matches set PIN |
| **Medication List** | Search medications | Text | Search filter query |

---

## 2. Doctor Portal Input Fields

| Screen / Feature | Field Name (Label) | Input Type | Validation / Constraints |
| :--- | :--- | :--- | :--- |
| **Login** | NPI Number / Identifier * | Text | Required, NPI format |
| **Login** | Password * | Obscure Text | Required |
| **Onboarding Request**| Full Name * | Text | Required |
| **Onboarding Request**| Medical License / NPI * | Text | Required |
| **Onboarding Request**| Hospital / Clinic Name * | Text | Required |
| **Onboarding Request**| Specialty * | Text / Dropdown | Required |
| **Onboarding Request**| Official Email Address *| Email Address | Required |
| **Onboarding Request**| Official Phone Number | Phone | Optional |
| **Patient Search** | Search patient name / ID | Text | Search filter query |
| **Composer (Editor)** | Chief Complaint / Problem *| Multi-line Text | Required |
| **Composer (Editor)** | Provisional Diagnosis * | Text | Required |
| **Composer (Editor)** | Clinical Notes | Multi-line Text | Optional |
| **Composer Rows** | Drug Name | Text | Required on each active row |
| **Composer Rows** | Strength | Text (e.g. 500mg) | Required on each active row |
| **Composer Rows** | Duration Value | Numeric | Required on each active row |
| **Override & Sign** | Override Rationale * | Multi-line Text | Required when Risk is HIGH/CRITICAL |

---

## 3. Pharmacy Portal Input Fields

| Screen / Feature | Field Name (Label) | Input Type | Validation / Constraints |
| :--- | :--- | :--- | :--- |
| **Login** | Username or email * | Email Address | Required |
| **Login** | Password * | Obscure Text | Required |
| **Registry Search** | Search Patient / Rx ID | Text | Search filter query |
| **Verification Check** | Expiry Date Selection | Date Picker | Required for pharmacy batch logging |
| **Clarification** | Describe issue / question *| Multi-line Text | Required |
| **Preparation** | Prep Quantity | Numeric | Validated against prescribed count |
| **Pickup Confirm** | Signature Checkbox / Pad | Touch Signature | Required to close dispensation |
| **Pickup Confirm** | Authorized ID Number | Text | Optional (when collected by agent) |
| **Delivery Track** | Tracking ID | Text | Required for home delivery dispatch |
