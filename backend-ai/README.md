# AegisRx / HealthLock — Backend API

A modular FastAPI backend for the AegisRx / HealthLock healthcare platform.

## Features

- **Clinical AI Audit** — Duplicate detection, drug interaction check, allergy conflict screening, and alternative recommendations powered by the Cerebras LLM API (with built-in mock mode)
- **Prescription Management** — Create, sign (SHA-256 + hex-shift), and retrieve prescriptions
- **Consultation Consent Flow** — Doctor requests access → Patient accepts/rejects → Blockchain ACCESS_GRANT recorded
- **Pharmacy Verification** — Zero-trust scan verification with hash integrity and blockchain cross-check; double-dispense prevention
- **Hash-Linked Blockchain Ledger** — All key events (prescriptions, access grants/revokes, dispensing) are immutably recorded in MongoDB
- **Patient Auth** — Argon2 password hashing, UUID session tokens
- **Doctor Auth** — Mobile number-based registration and login
- **Pattern Analysis** — Z-score based prescribing anomaly detection per doctor

---

## Project Structure

```
backend-ai/
├── app/
│   ├── main.py                    # FastAPI app entry point
│   ├── config.py                  # Environment variables & logging
│   ├── db/
│   │   └── mongodb.py             # MongoDBConnector + singleton
│   ├── models/                    # Pydantic schemas (7 domain files)
│   │   ├── patient.py
│   │   ├── doctor.py
│   │   ├── pharmacy.py
│   │   ├── prescription.py
│   │   ├── consultation.py
│   │   ├── audit.py
│   │   └── auth.py
│   ├── routes/                    # FastAPI routers
│   │   ├── auth.py
│   │   ├── patient.py
│   │   ├── consultation.py
│   │   ├── doctor.py
│   │   └── pharmacy.py
│   ├── services/                  # Business logic layer
│   │   ├── auth_service.py
│   │   ├── patient_service.py
│   │   ├── consultation_service.py
│   │   ├── doctor_service.py
│   │   ├── pharmacy_service.py
│   │   ├── prescription_service.py
│   │   ├── ledger_service.py      # BlockchainManager + activity logs
│   │   └── ai_service.py          # Wraps AIAgent from ai_core.py
│   ├── integrations/
│   │   └── cerebras_client.py     # CerebrasAPIClient
│   └── utils/
│       └── signature.py           # SHA-256 hashing + hex-shift signing
├── scripts/
│   └── update_db.py               # DB seed utility
├── ai_core.py                     # Legacy AI agent (preserved, used by ai_service)
├── app.py                         # Legacy monolith (preserved for reference)
├── config.py                      # Legacy config (preserved for ai_core.py)
├── prescriptions_db.json          # Local mock prescription data
├── .env.example                   # Environment variable template
├── requirements.txt
└── README.md
```

---

## Setup

### 1. Clone and navigate
```bash
cd e:\health_aegisRX\backend-ai
```

### 2. Create and activate virtual environment
```bash
python -m venv venv
# Windows
.\venv\Scripts\activate
# macOS / Linux
source venv/bin/activate
```

### 3. Install dependencies
```bash
pip install -r requirements.txt
```

### 4. Configure environment
```bash
copy .env.example .env
# Edit .env and fill in your values
```

### 5. Run the server
```bash
# Using the venv python (recommended on Windows)
.\venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 4000 --reload

# Or if venv is activated
uvicorn app.main:app --host 0.0.0.0 --port 4000 --reload
```

---

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `MONGODB_URI` | `mongodb://localhost:27017/` | MongoDB connection string |
| `MONGODB_DATABASE` | `healthcare_db` | Database name |
| `COLLECTION_PRESCRIPTIONS` | `prescriptions` | Prescriptions collection |
| `COLLECTION_ALLERGIES` | `allergies` | Patient allergies collection |
| `CEREBRAS_API_KEY` | `your_api_key_here` | Cerebras API key (leave as-is to use mock mode) |
| `CEREBRAS_MODEL` | `llama3.1-8b` | Cerebras model name |
| `MOCK_CEREBRAS` | `True` | Set `False` to use real Cerebras API |
| `DUPLICATE_TOLERANCE_DAYS` | `30` | Days window for duplicate prescription check |
| `PRESCRIPTION_HISTORY_DAYS` | `90` | Days of prescription history for interaction checks |

---

## API Routes

### General
| Method | Path | Description |
|---|---|---|
| `GET` | `/health` | Health check |
| `GET` | `/` | API metadata |
| `GET` | `/docs` | Swagger UI |

### Patient Auth
| Method | Path | Description |
|---|---|---|
| `POST` | `/api/patient/register` | Register new patient |
| `POST` | `/api/patient/login` | Patient login |
| `POST` | `/api/patient/update-name` | Update display name (requires `X-Session-Token` header) |

### Doctor Auth
| Method | Path | Description |
|---|---|---|
| `POST` | `/api/doctor/register` | Register / update doctor |
| `POST` | `/api/doctor/login` | Doctor login by mobile number |

### Patient Read
| Method | Path | Description |
|---|---|---|
| `GET` | `/api/patient/dashboard/{patient_id}` | Dashboard summary |
| `GET` | `/api/patient/prescriptions/{patient_id}` | All prescriptions |

### Consultation Consent
| Method | Path | Description |
|---|---|---|
| `POST` | `/api/consultation/request` | Doctor initiates consultation request |
| `POST` | `/api/consultation/accept` | Patient accepts |
| `POST` | `/api/consultation/reject` | Patient rejects |
| `GET` | `/api/consultation/status/{req_id}` | Get request status |
| `GET` | `/api/consultation/pending?patient=...` | Latest pending request for patient |
| `GET` | `/api/consultation/has-active-session?patient=...` | Check active session |

### Prescriptions
| Method | Path | Description |
|---|---|---|
| `GET` | `/api/prescriptions?patient=...` | Get prescriptions by patient name |
| `POST` | `/api/prescriptions` | Create signed prescription |
| `GET` | `/api/prescriptions/{rx_id}` | Get prescription by ID |

### Clinical AI
| Method | Path | Description |
|---|---|---|
| `POST` | `/api/audit` | Full AI audit (duplicate + interaction + allergy + pattern) |
| `POST` | `/api/duplicate-check` | Duplicate detection only |
| `POST` | `/api/interaction-check` | Drug interaction check (Cerebras) |
| `POST` | `/api/allergy-check` | Allergy conflict check |
| `POST` | `/api/recommendations` | AI medicine alternatives |
| `GET` | `/api/pattern-analysis/{doctor_id}` | Prescribing pattern anomaly analysis |

### Doctor Read
| Method | Path | Description |
|---|---|---|
| `GET` | `/api/doctor/patient-history/{patient_id}?doctor_id=...` | Patient history (requires access grant) |

### Pharmacy
| Method | Path | Description |
|---|---|---|
| `POST` | `/api/prescriptions/verify-scan` | Zero-trust prescription verification |
| `POST` | `/api/prescriptions/dispense` | Dispense prescription (marks as used) |

### Blockchain Ledger
| Method | Path | Description |
|---|---|---|
| `GET` | `/api/blockchain/chain` | View chain (patient-scoped) |
| `GET` | `/api/blockchain/verify` | Verify chain integrity |
| `POST` | `/api/blockchain/heal` | Repair broken chain links |
| `GET` | `/api/blockchain/blocks?block_type=...` | Filter blocks by type |
| `GET` | `/api/access/status?doctor_id=...&patient_name=...` | Check doctor access grant |
| `GET` | `/api/visit-history/{patient_name}` | Patient visit history |
| `GET` | `/api/activity-logs` | All activity logs |

---

## Audit Request Example

```bash
curl -X POST http://localhost:4000/api/audit \
  -H "Content-Type: application/json" \
  -d '{
    "patient_id": "Elenavan",
    "doctor_id": "NPI-88912",
    "new_medicine": "Penicillin V",
    "new_dosage": "500mg",
    "disease": "Acute Strep Throat"
  }'
```

---

## Seed Database

To manually seed the MongoDB prescriptions collection:
```bash
.\venv\Scripts\python.exe scripts/update_db.py
```

---

## Web Portal

The following HTML pages from the `public/` folder are served directly:

| Path | File |
|---|---|
| `/doctor-login` | `public/doctor-login.html` |
| `/doctor-prescription` | `public/doctor-prescription.html` |
| `/pharmacy-portal` | `public/pharmacy-portal.html` |
