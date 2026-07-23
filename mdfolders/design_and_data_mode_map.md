# Phase X – Fix Deterministic Clinical Action Flow

During verification we observed the following output:

```
Risk Level : CRITICAL
Risk Score : 95
Action : None
```

This is NOT acceptable according to the AegisRx architecture.

The project was intentionally redesigned so that:

- Audit Service is the deterministic Clinical Decision Support System (CDSS).
- AI Service is responsible ONLY for narrative generation.
- The LLM must NEVER determine clinical decisions.

Therefore the Audit Service must always return the complete deterministic decision.

---

## Required Architecture

Rule Engine

↓

Risk Score

↓

Risk Level

↓

Required Action

↓

Block Submission?

↓

Override Required?

↓

Warnings

↓

AI Service (Explanation Only)

The AI Service must receive the already-computed decision.

It must never compute

- risk score
- risk level
- required action
- override requirement
- block decision

---

## Required Changes

Search the entire backend.

Find where the AuditResult (or equivalent response model) is created.

Determine why `action` is currently returning `None`.

Do NOT hardcode the value.

Instead implement deterministic action generation inside the Audit Service.

---

## Clinical Decision Matrix

Implement deterministic mapping.

### LOW Risk

Risk Score:
0–29

Action:
ALLOW

Block Submission:
false

Override Required:
false

---

### MEDIUM Risk

Risk Score:
30–69

Action:
REVIEW

Block Submission:
false

Override Required:
false

Warnings:
Present

---

### HIGH Risk

Risk Score:
70–89

Action:
REQUIRE_OVERRIDE

Block Submission:
false

Override Required:
true

Warnings:
Present

---

### CRITICAL Risk

Risk Score:
90–100

Action:
BLOCK_UNLESS_OVERRIDE

Block Submission:
true

Override Required:
true

Warnings:
Present

---

## Response Schema

Update the Audit Service response so it always returns

```json
{
    "risk_score":95,
    "risk_level":"CRITICAL",

    "action":"BLOCK_UNLESS_OVERRIDE",

    "block_submission":true,

    "override_required":true,

    "warnings":[
        "Penicillin allergy detected"
    ],

    "clinical_explanation":"...",        // returned by AI Service

    "alternative_medicines":[]
}
```

The AI Service must append only

- clinical_explanation
- suggested_alternatives
- patient_friendly_summary

It must never overwrite

- risk score
- risk level
- action
- override flags

---

## Prescription Service

Update Prescription Service to use

block_submission

instead of checking risk level directly.

Example

if

block_submission == true

AND

override_reason is empty

↓

Return HTTP 403

Otherwise

↓

Allow save

---

## Frontend

Doctor Portal must use

action

instead of guessing behaviour.

Examples

ALLOW

→ Green banner

REVIEW

→ Yellow warning

REQUIRE_OVERRIDE

→ Orange dialog requesting clinical justification

BLOCK_UNLESS_OVERRIDE

→ Red dialog

Require signed override before enabling Submit.

---

## Verification

Run all existing tests again.

Expected output

```
Risk Level : CRITICAL
Risk Score : 95

Action : BLOCK_UNLESS_OVERRIDE

Block Submission : TRUE

Override Required : TRUE

Warnings :
- Penicillin allergy detected

AI Explanation :
Patient has documented allergy...

Alternative Medicines :
- Azithromycin
- Doxycycline
```

There must never be a case where

```
Action : None
```

for any completed audit.

---

## Constraints

- Preserve the existing architecture.
- Do not move business logic into the AI Service.
- Keep the AI Service responsible only for explanations and recommendations.
- Ensure backward compatibility with existing APIs where possible.
- Explain every modified file and why it was changed before implementing.
