# AegisRx - Patient History Acquisition & Verification Workflow

## Overview

To provide safe AI-assisted prescription analysis, AegisRx requires a continuous and trustworthy longitudinal medical history for every patient. Since not every hospital uses the AegisRx platform, the system adopts a hybrid patient history acquisition model.

Rather than depending on a single source, AegisRx collects patient history from three different sources while maintaining different trust levels for every record. This ensures that AI-powered Clinical Decision Support (CDSS) only relies on verified medical information.

---

# Architecture Overview

```
                    +----------------------------+
                    |     Patient Medical History |
                    +-------------+--------------+
                                  |
        ----------------------------------------------------
        |                    |                             |
        |                    |                             |
        ▼                    ▼                             ▼
 AegisRx Network      External Hospital          Patient Self Entry
     Records             Record Import
        |                    |                             |
 HIGH TRUST           MEDIUM TRUST                 LOW TRUST
        |                    |                             |
        ----------------------                             |
                     |                                    |
                     ▼                                    ▼
          Verification & Trust Engine
                     |
                     ▼
              AI Safety Engine (CDSS)
                     |
                     ▼
          Prescription Risk Analysis
```

---

# Source 1 – AegisRx Network Records

## Description

Whenever a patient receives treatment from a hospital or clinic that participates in the AegisRx network, all consultations and prescriptions are created directly inside AegisRx.

This becomes the most trusted source of patient history.

---

## Workflow

1. Doctor searches using the AegisRx Patient ID.
2. Patient grants consultation consent.
3. Doctor creates prescription.
4. Prescription is stored in MongoDB.
5. Audit SHA-256 hash is anchored in Hyperledger Fabric.
6. Medical history is automatically updated.

---

## Metadata

| Field | Value |
|--------|-------|
| Source | AegisRx Network |
| Trust Level | HIGH |
| Verification | Doctor Verified |
| Blockchain | Yes |
| AI Usage | Always |

---

# Source 2 – External Hospital Record Import

## Description

Patients may have previously visited hospitals that do not use AegisRx.

Instead of losing that historical information, AegisRx allows patients to import those records into their personal health timeline.

Supported document types include:

- Prescription PDFs
- Discharge Summaries
- Laboratory Reports
- Scan Reports
- Medical Certificates

---

# Step 1 – Upload

The patient uploads a medical document using the mobile application.

The uploaded document is **NOT** immediately added to the official medical history.

Instead, it is stored inside a temporary collection.

Collection Name:

```
pending_imports
```

---

# Step 2 – OCR Processing

The OCR engine extracts structured clinical information.

Example extracted fields:

- Medicine Name
- Strength
- Dosage
- Frequency
- Duration
- Diagnosis
- Allergies
- Laboratory Values
- Hospital Name
- Visit Date

---

# Step 3 – AI Structuring

The AI converts the OCR output into structured medical records.

Example:

```json
{
    "medicine": "Amoxicillin",
    "strength": "500 mg",
    "frequency": "Twice Daily",
    "duration": "7 Days",
    "diagnosis": "Upper Respiratory Infection",
    "allergy": "None"
}
```

The AI also calculates extraction confidence.

Example:

```
Medicine : 98%

Diagnosis : 95%

Dosage : 99%
```

---

# Step 4 – Pending Verification

The imported record receives the status:

```
Pending Clinical Verification
```

Characteristics:

- Visible to Patient
- Visible to Doctors
- Not used for AI Prescription Analysis
- Awaiting clinical review

---

# Step 5 – Doctor Review

During the patient's next consultation, the doctor reviews imported records.

The doctor may choose one of the following actions.

---

## Option A – Approve

If the uploaded document is correct:

- Move record into official Medical History
- Store verification metadata
- Optional blockchain audit event
- Available for AI analysis

Status

```
Doctor Verified

Trust Level : HIGH
```

---

## Option B – Edit

If OCR extracted incorrect information:

Example

OCR

```
250 mg
```

Doctor Corrects

```
500 mg
```

The corrected version becomes the official medical record.

Status

```
Doctor Verified

Trust Level : HIGH
```

---

## Option C – Reject

If the uploaded record is:

- Invalid
- Fake
- Poor OCR Quality
- Unreadable

The record remains stored for auditing but is excluded from AI analysis.

Status

```
Rejected

Reason :
Invalid Document
```

---

## Option D – No Review Yet

If the patient uploads records before meeting a doctor, the system does not discard them.

Instead:

Status

```
Pending Verification
```

When another doctor opens the patient profile, they see:

```
Pending Imported Records (2)

• Apollo Discharge Summary

• Blood Test Report

Review Before Consultation
```

The doctor can review them during the consultation.

Until verification:

- AI ignores these records for critical safety checks.
- Doctors may still manually review them.

---

# Source 3 – Patient Self-Entered Health Information

Patients may manually enter:

- Allergies
- Chronic Diseases
- Current Medications
- Past Surgeries
- Lifestyle Habits
- Emergency Medical Information

Initially these records receive:

```
Patient Entered

Trust Level : LOW
```

During consultation:

Doctor may verify these records.

After verification:

```
Doctor Verified

Trust Level : HIGH
```

---

# Trust Engine

Every medical record inside AegisRx contains trust metadata.

| Source | Verification | Trust Level | AI Usage |
|---------|--------------|-------------|----------|
| AegisRx Consultation | Doctor Verified | HIGH | YES |
| Imported PDF | Doctor Verified | HIGH | YES |
| Imported PDF | Pending Review | PENDING | WARNING ONLY |
| Patient Self Entry | Not Verified | LOW | LIMITED |
| Rejected Record | Rejected | NONE | NO |

---

# AI Safety Engine Rules

The AI Prescription Safety Engine follows these rules:

## HIGH Trust

Used for:

- Allergy Detection
- Drug Interaction Analysis
- Disease Contraindications
- Dosage Validation
- Risk Scoring

---

## Pending Records

Visible to doctors but excluded from automatic prescription decisions.

Doctors receive a warning.

Example:

```
Pending Imported Records Found

These records have not been clinically verified.
Please review before prescribing medication.
```

---

## LOW Trust

Patient-entered information is considered advisory.

Doctors are encouraged to confirm these details before prescribing.

---

## Rejected Records

Rejected records:

- remain archived
- never participate in AI analysis
- remain available for audit history

---

# Database Collections

```
patients

medical_history

pending_imports

prescriptions

audit_logs

consent_events

blockchain_metadata
```

---

# Benefits

This hybrid architecture provides several advantages.

### Continuity of Care

Patients carry their complete medical history across participating hospitals.

---

### Trustworthy AI

The AI only relies on verified medical information when calculating prescription risks.

---

### Interoperability

Patients can import records from hospitals that do not use AegisRx.

---

### Clinical Safety

Doctors remain the final authority.

AI assists.

Doctors decide.

---

### Blockchain Integrity

Only verified clinical events are anchored on Hyperledger Fabric, ensuring tamper-evident audit trails without exposing sensitive patient information.

---

# Future Scope

The Import Service is designed to support future healthcare interoperability standards.

Possible future integrations include:

- HL7 FHIR APIs
- National Health Records
- ABHA Health ID
- Hospital Information Systems (HIS)
- Electronic Health Records (EHR)
- Laboratory Information Systems (LIS)

No architectural redesign is required to support these integrations.

---

# Final Architecture Principle

AegisRx is **not** intended to replace existing hospital Electronic Health Record (EHR) systems.

Instead, it functions as a **patient-centric longitudinal healthcare companion platform** that:

- Maintains a continuous medical history.
- Supports AI-assisted prescription safety.
- Provides blockchain-backed audit integrity.
- Enables secure patient-controlled data sharing.
- Bridges fragmented healthcare records through verified imports and participating healthcare providers.