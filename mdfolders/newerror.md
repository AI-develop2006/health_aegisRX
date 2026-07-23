You are acting as a Senior Flutter + Android + FastAPI + Network + Architecture Debugging Engineer.

Your task is to perform a complete root cause analysis of my application.

DO NOT guess.
DO NOT immediately suggest fixes.
First investigate the entire execution flow and produce a detailed debugging report based only on evidence.

## Context

The application consists of:

- Flutter frontend
- FastAPI backend
- MongoDB
- Doctor Portal
- Patient Portal

Observed behaviour:

- A patient logs in successfully.
- Backend logs show the newly logged-in patient.
- However, the Flutter frontend sends:

GET /api/doctor/patient-history/Guest

instead of the actual logged-in patient.

The Flutter logs stop after:

[DEBUG_API] Waiting for response...

Then Android prints:

Signal Catcher reacting to signal 3
Wrote stack traces to tombstoned
Lost connection to device

No HTTP response.
No TimeoutException.
No SocketException.
No status code.

--------------------------------

## Investigation Goals

Trace the complete data flow from login until the API call.

Investigate:

### 1. Login Flow

Determine:

- How the patient logs in.
- What object is returned.
- Whether the patient id, username, UUID or email is extracted correctly.
- Whether login succeeds.

Show the exact execution path.

--------------------------------

### 2. Storage

Find where the logged-in user is stored.

Check:

- SharedPreferences
- Secure Storage
- Provider
- Riverpod
- Bloc
- GetX
- Singleton
- Global Variables
- Session object

Determine whether:

- the patient information is actually saved
- it is overwritten
- it is cleared
- it is never written

--------------------------------

### 3. State Flow

Trace how the logged-in patient travels through the application.

Find:

Login
↓

Storage
↓

State Management
↓

Doctor Screen

↓

fetchPatientProfile()

↓

HTTP Request

Show every variable involved.

--------------------------------

### 4. Patient ID Investigation

Determine exactly why

Guest

is being used.

Search for:

"Guest"

default values

??

??=

ifEmpty

fallback values

hardcoded strings

constants

constructors

default parameters

Determine:

- where Guest originates
- why Guest is chosen
- why the real patient id is missing

--------------------------------

### 5. API Construction

Trace:

fetchPatientProfile()

Determine:

- where patientId comes from
- where URL is built
- whether patientId is null
- whether patientId is empty
- whether Guest is substituted

Example:

final url =
...

Trace every variable.

--------------------------------

### 6. Backend Verification

Verify whether the request:

GET /patient-history/Guest

actually reaches FastAPI.

Determine:

- Does backend receive Guest?
- Does backend receive actual patient?
- Does backend reject Guest?
- Does backend hang?
- Does backend return?
- Does backend never receive request?

--------------------------------

### 7. Android Logs

Analyse:

Signal Catcher

tombstoned

Lost connection

Determine whether:

- ANR occurred
- Debugger pause occurred
- Native crash occurred
- Process killed
- Flutter isolate paused

Explain the evidence.

--------------------------------

### 8. HTTP Investigation

Determine whether

await http.get(...)

actually executes.

Determine:

- Request sent
- DNS lookup
- TCP connection
- Waiting response
- Timeout
- Exception
- Never returned

Explain where execution stops.

--------------------------------

### 9. Timeline Reconstruction

Produce an execution timeline like:

User taps button

↓

Login state

↓

patientId value

↓

fetchPatientProfile()

↓

URL generated

↓

HTTP request

↓

Backend

↓

MongoDB

↓

Response

↓

Flutter

Show exactly where execution stops.

--------------------------------

### 10. Root Cause Ranking

Rank every possible cause.

Example:

95% Frontend passing default Guest value

90% Login state not propagated

80% SharedPreferences not updated

40% Backend waiting forever

20% Network issue

10% Android ANR

Support every percentage with evidence.

--------------------------------

### 11. Code References

For every issue found include:

- filename
- class
- method
- line number (if available)

--------------------------------

### 12. Final Report

Produce a report with:

Executive Summary

Observed Behaviour

Evidence

Execution Timeline

Root Cause

Secondary Issues

Files Involved

Recommended Fix Order

Priority

Confidence

DO NOT suggest code changes until the investigation is complete.

Think like a senior software architect performing a production incident post-mortem.