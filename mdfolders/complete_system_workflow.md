# Phase X Improvement - Deterministic Clinical Decision Engine

Before implementing the current plan, review the entire backend architecture and refactor it so that the Clinical Decision Support System (CDSS) follows a strict separation of responsibilities.

## IMPORTANT ARCHITECTURE RULE

The Audit Service must be the ONLY component that makes clinical decisions.

The AI Service must NEVER determine:

- risk_score
- risk_level
- action
- block_submission
- override_required

The AI Service should ONLY generate human-readable explanations after the decision has already been made.

The final execution order must always be:

Doctor
    ↓
Prescription Service
    ↓
Audit Service
        ↓
Clinical Rule Engine
        ↓
Allergy Rules
Disease Rules
Dosage Rules
Interaction Rules
Patient History Rules
Lab Rules
        ↓
Combine Rule Results
        ↓
Calculate Final Risk Score
        ↓
Determine Risk Level
        ↓
Determine Required Action
        ↓
Call AI Service
        ↓
Generate Explanation
Alternative Medicines
Patient Friendly Summary
Doctor Clinical Rationale
        ↓
Return Complete Audit Response
        ↓
Prescription Service
        ↓
Store Prescription
        ↓
Ledger Service
        ↓
Hyperledger Fabric

--------------------------------------------------

## Refactor Required

Audit Service must expose a Clinical Decision Matrix.

Example:

if risk_score >= 90:
    risk_level = "CRITICAL"
    action = "BLOCK_UNLESS_OVERRIDE"
    block_submission = true
    override_required = true

elif risk_score >= 70:
    risk_level = "HIGH"
    action = "REQUIRE_OVERRIDE"
    block_submission = false
    override_required = true

elif risk_score >= 30:
    risk_level = "MEDIUM"
    action = "REVIEW"
    block_submission = false
    override_required = false

else:
    risk_level = "LOW"
    action = "ALLOW"
    block_submission = false
    override_required = false

This mapping must exist ONLY inside Audit Service.

No AI code should calculate these values.

--------------------------------------------------

## Audit Response

The Audit Service should always return

{
    "risk_score":95,
    "risk_level":"CRITICAL",
    "action":"BLOCK_UNLESS_OVERRIDE",
    "block_submission":true,
    "override_required":true,
    "warnings":[...],
    "triggered_rules":[...],
    "alternative_medicines":[...],
    "clinical_explanation":"...",
    "patient_summary":"..."
}

--------------------------------------------------

## AI Service Responsibilities

Move ALL generative AI into AI Service.

AI Service should ONLY provide

• Clinical Explanation

• Patient-friendly Summary

• Suggested Alternative Medicines

• Medication Explanation

• OCR Summary

• Patient History Summary

• Medical Chat

• Doctor Assistant

• Voice Prescription Parser

• Patient Education

AI Service receives

risk_score
risk_level
triggered_rules
patient history
current prescription

and returns ONLY narrative text.

It must NEVER change any risk score.

--------------------------------------------------

## Prescription Service

Prescription Service must NOT trust the frontend.

Every prescription save must execute

Prescription
↓

Audit Service

↓

Receive action

↓

if block_submission == true

AND overrideReason is empty

return HTTP 403

otherwise continue

No prescription should ever bypass Audit Service.

--------------------------------------------------

## Flutter Changes

Doctor screen must render using the returned action.

ALLOW
→ Green

REVIEW
→ Yellow

REQUIRE_OVERRIDE
→ Orange

BLOCK_UNLESS_OVERRIDE
→ Red

Never calculate colors locally from score.

Always use backend action.

--------------------------------------------------

## Verification

Verify these scenarios.

Scenario 1

Penicillin Allergy

Expected

Risk Score = 95

Risk Level = CRITICAL

Action = BLOCK_UNLESS_OVERRIDE

block_submission = true

override_required = true

Scenario 2

Unsafe prescription without override

Expected

HTTP 403

Scenario 3

Unsafe prescription with signed override

Expected

HTTP 200

Scenario 4

AI Service Offline

Expected

Risk calculation still works.

Only explanation becomes unavailable.

Prescription should still be blocked if CRITICAL.

Scenario 5

Frontend Manipulation

Attempt to directly call Prescription Service without Audit.

Expected

Rejected.

Audit is mandatory.

--------------------------------------------------

## Final Validation

Review the entire backend implementation and confirm that

✓ AI Service performs zero clinical decision making

✓ Audit Service owns all safety decisions

✓ Prescription Service cannot bypass Audit Service

✓ Frontend never computes clinical logic

✓ Risk score is deterministic

✓ AI only explains the result

✓ The architecture follows zero-trust clinical design

If any module violates this architecture, refactor it before proceeding.