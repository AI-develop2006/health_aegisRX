# AegisRx: Migration Blueprint from Mock to Real Data

This document outlines the master migration blueprint to make the **AegisRx** system fully dynamic and hackathon-ready. It details the exact locations of frontend/backend mock implementations, defines the configuration flags, provides implementation skeletons (for Flutter & FastAPI), and supplies a QA verification checklist.

---

## 1. Mock Locations & Activation Mechanics

### Gap 1.1: Patient Profile Defaults
* **File Location**: [app_state.dart](file:///c:/Users/srima/hackathon%20votexa/health_lock/lib/core/state/app_state.dart) (Getter: `patientName`, `patientEmailOrId`, and `_isOfflineGuest`)
* **How Activated**: Triggered when `_isOfflineGuest` is set to `true` or when no `_currentPatient` exists in `SharedPreferences` session data.
* **Real Backend Flow**: Read user metadata returned on successful login (`/api/patient/login`) and fetch live details from `patient-service` via `/api/patient/dashboard/{patient_id}`.

### Gap 1.2: Hardcoded JWT Tokens
* **File Locations**: [patient_unlock_setup_screen.dart](file:///c:/Users/srima/hackathon%20votexa/health_lock/lib/features/patient/screens/patient_auth_Screen/patient_unlock_setup_screen.dart) and [pharmacy_login_screen.dart](file:///c:/Users/srima/hackathon%20votexa/health_lock/lib/features/pharmacy/screens/pharmacy_login_screen.dart)
* **How Activated**: Directly hardcoded token assignments:
  * `token: 'mock-jwt-token-patient-alex'`
  * `token: 'mock-jwt-token-pharmacy-${_licenseController.text}'`
* **Real Backend Flow**: Make a POST request to `/api/patient/login` or `/api/pharmacy/login`. Parse the JWT string returned in the response body or headers and persist it.

### Gap 1.3: Mock ID Document Attachments
* **File Location**: [patient_signup_screen.dart](file:///c:/Users/srima/hackathon%20votexa/health_lock/lib/features/patient/screens/patient_auth_Screen/patient_signup_screen.dart)
* **How Activated**: The function `_pickDocument()` assigns a static string `id_proof_document_aadhaar.pdf` and skips API submission.
* **Real Backend Flow**: Read a local file using a document picker, send a multipart HTTP POST request to `/api/media/upload` (via gateway-service), and pass the returned file path inside the signup body.

### Gap 1.4: Doctor Override Signatures
* **File Location**: [doctor_override_and_sign_screen.dart](file:///c:/Users/srima/hackathon%20votexa/health_lock/lib/features/doctor/screens/doctor_override_and_sign_screen.dart)
* **How Activated**: The function `_generateMockHash()` is called whenever the backend response does not return an `onchain_tx_hash`.
* **Real Backend Flow**: If on-chain commitment fails, throw a clear exception from the gateway, capture it on the client, and display a high-contrast dialog requesting the clinician to re-sign.

### Gap 1.5: Clinical Pre-Flight Safety Checker
* **File Location**: [doctor_prescription_editor_screen.dart](file:///c:/Users/srima/hackathon%20votexa/health_lock/lib/features/doctor/screens/doctor_prescription_editor_screen.dart)
* **How Activated**: Falls back to `_runLocalMockAudit()` if the API request returns a null result.
* **Real Backend Flow**: Must query `gateway-service/api/audit` and parse the dynamic payload containing interactions risk parameters.

### Gap 1.6: MedGemma / Cerebras Fallback
* **File Location**: `audit-service/app/ai/services/ai_service.py`
* **How Activated**: Triggered when the environment variables (e.g. `CEREBRAS_API_KEY`, `GEMINI_API_KEY`) are missing, catching the API connection exception and falling back to a deterministic rule-engine.
* **Real Backend Flow**: Query Cerebras MedGemma or Gemini endpoints. If credentials are missing, throw a 500 error in production.

### Gap 1.7: Polygon RPC Credentials
* **File Location**: `prescription-service/app/service.py` and `pharmacy-service/app/service.py`
* **How Activated**: Triggered if `TEST_PHARMACY_PRIVATE_KEY` or `TEST_DOCTOR_PRIVATE_KEY` environment variables are blank.
* **Real Backend Flow**: Read valid RPC configuration. If keys are missing and mocks are disabled, block the transaction request and return an HTTP `400 Bad Request`.

---

## 2. Configuration Strategy Matrix

Define the environment variables in a shared config file (e.g., `core/config.py` on python and dynamically loaded flags on client):

```ini
ENV=hackathon # dev, hackathon, prod
USE_MOCK_FRONTEND=false
USE_MOCK_LLM=false
USE_MOCK_AUDIT=false
ALLOW_MOCK_POLYGON_TX=false
```

### Strategy Mapping:

| Mode / Environment Flag | `ENV` | `USE_MOCK_FRONTEND` | `USE_MOCK_LLM` | `USE_MOCK_AUDIT` | `ALLOW_MOCK_POLYGON_TX` |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Local Dev** | `dev` | `true` | `true` | `true` | `true` |
| **Hackathon Demo** | `hackathon` | `false` | `false` | `false` | `true` (Allows demo to continue if RPC fails) |
| **Production** | `prod` | `false` | `false` | `false` | `false` |

---

## 3. Frontend Code Skeletons (Flutter)

### 3.1 Fetching Real JWT Token
```dart
Future<String?> loginWithEmail(String email, String password) async {
  try {
    final response = await http.post(
      Uri.parse('$backendUrl/api/patient/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['token']; // Real JWT token returned from Auth service
      _role = UserRole.patient;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_token', _token!);
      await prefs.setString('saved_role', 'patient');
      return null; // success
    }
    return 'Invalid credentials';
  } catch (e) {
    return ErrorMapper.map(e);
  }
}
```

### 3.2 Real Document Upload Payload
```dart
Future<String?> uploadDocumentFile(File file) async {
  try {
    var request = http.MultipartRequest('POST', Uri.parse('$backendUrl/api/media/upload'));
    request.headers['Authorization'] = 'Bearer $_token';
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['file_path']; // returns uploaded document URL/path
    }
    return null;
  } catch (e) {
    debugPrint('File upload failed: $e');
    return null;
  }
}
```

### 3.3 Guest Mode Profile Gating
```dart
String get patientName {
  if (useMockFrontendFlag && _isOfflineGuest) {
    return 'Elena Vance (Guest)';
  }
  if (_currentPatient != null) {
    return _currentPatient!['name'] ?? 'Sovereign Patient';
  }
  throw Exception('Access Denied: Unauthenticated vault access.');
}
```

### 3.4 Validating Real Polygon Hashes or Aborting
```dart
void _signPrescription() async {
  setState(() => _isSigning = true);
  
  final res = await appState.signPrescription(widget.prescriptionId);
  
  setState(() => _isSigning = false);

  if (res['onchain_tx_hash'] != null && res['onchain_tx_hash'] != '0x') {
    // Show real hash confirmation
    _showSuccessDialog(res['onchain_tx_hash']);
  } else {
    // Abort and show error in production mode
    _showErrorDialog('On-chain signature failed: EVM node transaction reverted.');
  }
}
```

---

## 4. Backend Endpoints (FastAPI)

### 4.1 Hybrid AI Safety Checker (`audit-service`)
```python
from fastapi import APIRouter, HTTPException, Depends
from app.config import settings
from app.ai.services import ai_service

router = APIRouter()

@router.post("/api/audit")
async def run_prescription_safety_audit(payload: AuditInput):
    # Enforce real LLM audits in production
    if settings.ENV == "prod" and settings.USE_MOCK_LLM:
        raise HTTPException(status_code=400, detail="Mock audits disabled in production.")

    try:
        analysis = await ai_service.audit_prescription(
            patient_id=payload.patient_id,
            medicine=payload.new_medicine,
            dosage=payload.new_dosage,
            use_mock=settings.USE_MOCK_LLM
        )
        return {
            "risk_level": analysis.risk_level,
            "risk_score": analysis.risk_score,
            "backend_mode": "mock" if settings.USE_MOCK_LLM else "real",
            "backend_reason": analysis.mode_reason,
            "suggested_alternatives": analysis.alternatives
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Audit execution failure: {str(e)}")
```

### 4.2 On-Chain Key Verification (`prescription-service`)
```python
@router.post("/api/prescriptions/sign")
async def sign_prescription(payload: SignPayload):
    # Enforce key validations
    if not settings.TEST_DOCTOR_PRIVATE_KEY:
        if not settings.ALLOW_MOCK_POLYGON_TX:
            raise HTTPException(
                status_code=400, 
                detail="Sovereign Signature Error: Missing Polygon practitioner key."
            )
        # Fallback to local dev mock hash
        tx_hash = f"0x_mock_{uuid.uuid4().hex}"
    else:
        try:
            tx_hash = await polygon_client.commit_prescription(payload.rx_id, settings.TEST_DOCTOR_PRIVATE_KEY)
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Polygon write failed: {str(e)}")

    # Update Mongo DB and return hash
    db.prescriptions.update_one({"id": payload.rx_id}, {"$set": {"onchain_tx_hash": tx_hash}})
    return {"status": "committed", "onchain_tx_hash": tx_hash}
```

---

## 5. Hackathon Setup Verification Checklist

Follow this checklist during staging deployment:

- [ ] **Config Check**: Verify that `.env` config file specifies `ENV=hackathon`, `USE_MOCK_FRONTEND=false`, `USE_MOCK_LLM=false`, and `ALLOW_MOCK_POLYGON_TX=true`.
- [ ] **Patient Portal Registration**: Register a new patient. Confirm that the record is written to the `patients` MongoDB collection with a secure password hash.
- [ ] **Clinical Auditing**: Log in as a physician. Compose a prescription with Penicillin for a patient documented with a Penicillin allergy. Verify that `audit-service` returns a Warning/Critical risk band and displays "real" mode with Cerebras/MedGemma latency statistics.
- [ ] **On-Chain Commits**: Sign the prescription. Confirm the generated transaction hash is successfully committed to Polygon and visible in the prescription detail page.
- [ ] **Token Burn Verification**: Log in as a pharmacist, verify signature integrity, and click **Dispense**. Verify that `isDispensed` changes to `true` in MongoDB and that a duplicate dispense request is blocked.
