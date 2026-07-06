# 🛡️ AegisRx / HealthLock - Backend Architecture & Integration Map

This document outlines the final directory structure, service layout, and operational flows of the modular FastAPI backend for AegisRx / HealthLock. 

The backend has been restructured to combine the modular service layer (from the `giri` branch), a multi-provider AI Multi-Agent system (from the `ai-agent` branch), and a secure Polygon smart contract integration.

---

## 📂 Project Directory Structure

All backend code resides in the `backend-ai/` directory:

```
backend-ai/
├── app/
│   ├── main.py                     # FastAPI entry point, lifespans, router registration
│   ├── config.py                   # Configuration schemas, logging, env variables (loads .env)
│   │
│   ├── core/
│   │   └── config.py               # Settings bridge connecting app/ai to config.py
│   │
│   ├── db/
│   │   └── mongodb.py              # MongoDB connection client & singleton pattern
│   │
│   ├── integrations/
│   │   └── polygon_client.py       # Polygon Web3 python client (write/read smart contracts)
│   │
│   ├── schemas/                    # Pydantic schemas for Multi-Agent AI
│   │   ├── patient.py              # PatientContext structures
│   │   └── response.py             # PrescriptionSafetyAnalysis schemas
│   │
│   ├── models/                     # Pydantic data schemas (Standard Requests/Responses)
│   │   ├── audit.py                # Audit payload schemas
│   │   ├── auth.py                 # Argon2 passwords & session schemas
│   │   ├── consultation.py         # Encounter status & consent validation models
│   │   ├── doctor.py               # Doctor register & profile models
│   │   ├── patient.py              # Patient registration schemas
│   │   ├── pharmacy.py             # Pharmacy verification & scan models
│   │   └── prescription.py         # Prescription validation & issuance models
│   │
│   ├── routes/                     # FastAPI Route Handlers (HTTP mappings)
│   │   ├── auth.py                 # Patient password auth & token session routes
│   │   ├── patient.py              # Patient profile & history fetch routes
│   │   ├── consultation.py         # Doctor consent request & accept/reject routes
│   │   ├── doctor.py               # Prescription CRUD, audits & clinical checks
│   │   └── pharmacy.py             # Verification scans & dispensing triggers
│   │
│   ├── services/                   # Business Logic Layer (Separation of concerns)
│   │   ├── auth_service.py         # Argon2 hashing & patient token session tracking
│   │   ├── patient_service.py      # Patient metadata management
│   │   ├── consultation_service.py # Encounter lifecycle & consent ledger tracking
│   │   ├── doctor_service.py       # Patient history queries & prescribing pattern analytics
│   │   ├── pharmacy_service.py     # Dispense tokens, verify scan signatures & burn
│   │   ├── prescription_service.py # Canonical JSON signing, DB insertion & blockchain
│   │   ├── ledger_service.py       # BlockchainManager (Immutable ledger checks/heals)
│   │   └── ai_service.py           # Unified wrapper for Multi-Agent audits & local checks
│   │
│   ├── ai/                         # Multi-Agent AI module
│   │   ├── agents/                 # Safety agents (allergy, interaction, disease, dosage)
│   │   ├── knowledge/              # Knowledge bases (FDA, DailyMed, SNOMED, DrugBank)
│   │   ├── llm/                    # Providers (Gemini, MedGemma, GPT, PromptBuilder)
│   │   ├── report/                 # Clinical audit report generator
│   │   └── services/               # Internal AI service orchestration
│   │
│   └── utils/
│       └── signature.py            # SHA-256 hashing & custom shift-cipher signature utility
│
├── contracts/
│   └── PrescriptionLedger.sol      # Solidity smart contract for Polygon ledger
│
├── scripts/
│   ├── update_db.py                # Database seeding tool for local environment testing
│   └── test_polygon_flow.py        # Automated local end-to-end integration tester
│
├── docker-compose.yml              # Multi-container orchestration (FastAPI, MongoDB, Services)
├── requirements.txt                # Python package dependency definitions (including web3)
└── vercel.json                     # Serverless deployment configuration
```

---

## ⚙️ Core Architectural Operations

### 1. Zero-Trust Access Consent Flow
Doctors do not have default access to a patient's historical medical records. Access must be explicitly granted by the patient:
1. **Access Request**: The doctor submits a request via the practitioner console.
2. **Access Grant**: The patient reviews and accepts the request. The backend appends an `ACCESS_GRANT` block to the hash-linked MongoDB blockchain ledger.
3. **Audit and Write**: The doctor views the patient's records, passes the AI pre-flight safety audit, and writes/signs the prescription.
4. **Auto-Revocation**: Once the prescription is committed, the backend automatically appends an `ACCESS_REVOKE` block, immediately terminating the doctor's access window.

---

### 2. Dual-Ledger Validation System (MongoDB + Polygon)
A prescription is committed to two separate ledgers for maximum audit security and safety:

```
[Doctor submits Prescription]
       │
       ├───► Writes to MongoDB (storing local copy for fast checks)
       │
       ├───► Appends to local Blockchain collection (hash-linked database chain)
       │
       └───► Transmits to Polygon Smart Contract (using Web3 client)
```

*   **Solidity Smart Contract (`PrescriptionLedger`)**:
    Deploys a lightweight registry mapping prescription IDs to `struct Prescription { bytes32 hash; address doctor; bool exists; bool dispensed; }`. Only authorized doctor wallets can register prescriptions, and only authorized pharmacy wallets can mark them as dispensed.
*   **Web3 Integrations Client (`polygon_client.py`)**:
    Enables the backend to compile, sign (using `TEST_DOCTOR_PRIVATE_KEY` / `TEST_PHARMACY_PRIVATE_KEY` on-chain), and broadcast transactions to Polygon nodes.
*   **Tamper-Proof Scans (`verify_scan`)**:
    During checkout, the pharmacy scans the checkout QR code. The backend compares:
    1. Local QR payload hash vs. MongoDB signature.
    2. Local QR payload hash vs. the immutable hash stored on the **Polygon Ledger** (blocking off-chain database tampering).
    3. Double-dispense check: Ensures `dispensed == false` both locally and on-chain (preventing scan reuse).

---

### 3. Multi-Agent AI safety Audit Pipeline
When a doctor prepares a prescription, the audit endpoint `/api/audit` triggers the modular AI module:
*   **Clinical Rule Checkers (Sub-Agents)**:
    `AllergyAgent`, `DiseaseAgent`, `DosageAgent`, and `InteractionAgent` parse patient records in parallel against medical rules.
*   **External Knowledge Retrievers**:
    Queries OpenFDA, DailyMed, DrugBank, and RxNorm to extract facts about contraindicated age limits, pregnancy warnings, and chemical compounds.
*   **LLM Reasoning Engine**:
    Compiles prompts containing patient history, clinical agent checks, and retrieved medical facts. Submits the request to **Google Gemini** (using `gemini-2.5-flash` via the `GEMINI_API_KEY`) or falls back to OpenAI / MedGemma to retrieve a structured safety audit report.
*   **Clinical Overrides (Safe-by-Design)**:
    Even if the LLM states the prescription is safe, if local clinical rule checks trigger a `HIGH_RISK` or `WARNING` event, the system overrides the LLM response to upgrade the risk level for patient safety.

---

## 🚀 Running & Testing the Backend

### Prerequisites
1. Ensure **MongoDB** is running locally or a MongoDB Atlas connection string is configured.
2. Ensure you have Python `3.9+` installed.

### Setup and Testing Flow

1. **Install Requirements**:
   ```bash
   cd backend-ai
   python -m venv venv
   # Windows:
   .\venv\Scripts\activate
   # Install dependencies (including web3, pydantic-settings, and openai)
   pip install -r requirements.txt
   ```

2. **Configure Environment (`.env`)**:
   Populate your MongoDB, Gemini, and Polygon keys in `backend-ai/.env`:
   ```env
   MONGODB_URI=mongodb+srv://user1:password@cluster.mongodb.net/
   MONGODB_DATABASE=healthcare_db
   
   LLM_PROVIDER=gemini
   GEMINI_API_KEY=your_gemini_api_key
   
   POLYGON_RPC_URL=https://rpc-amoy.polygon.technology
   POLYGON_CONTRACT_ADDRESS=0xYourDeployedContractAddress
   TEST_DOCTOR_PRIVATE_KEY=0xYourDoctorPrivateKey
   TEST_PHARMACY_PRIVATE_KEY=0xYourPharmacyPrivateKey
   ```

3. **Database Seeding**:
   ```bash
   python scripts/update_db.py
   ```

4. **Launch Server**:
   ```bash
   uvicorn app.main:app --port 5000 --reload
   ```

5. **Run Integration Tests**:
   To test the complete end-to-end flow (Prescription Creation $\rightarrow$ Scan Verification $\rightarrow$ On-Chain Dispense $\rightarrow$ Anaphylaxis / Double-dispense blocks):
   ```bash
   python scripts/test_polygon_flow.py
   ```
