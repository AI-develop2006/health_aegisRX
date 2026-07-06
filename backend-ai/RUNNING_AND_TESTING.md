# AegisRx Backend — Run & Test Guide

## Prerequisites

- Python 3.10+
- MongoDB Atlas account (credentials already in `.env`)
- Cerebras API key (already in `.env`)

---

## 1. Setup (One-time)

Open a terminal in the `backend-ai` folder:

```bash
cd e:\health_aegisRX\backend-ai
```

Create and activate virtual environment:

```powershell
# Create venv (only first time)
python -m venv venv

# Activate (run every time you open a new terminal)
.\venv\Scripts\activate
```

Install dependencies:

```bash
pip install -r requirements.txt
```

---

## 2. Start the Server

```powershell
# Option A — using activated venv
uvicorn app.main:app --host 0.0.0.0 --port 4000 --reload

# Option B — without activating venv (safe on Windows)
.\venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 4000 --reload
```

**Expected startup output:**

```
INFO:     Uvicorn running on http://0.0.0.0:4000
INFO - Connected to MongoDB: healthcare_db
INFO - BlockchainManager initialized.
INFO - AIAgent initialized.
INFO:     Application startup complete.
```

### Useful URLs once running

| URL | Description |
|---|---|
| http://localhost:4000/health | Health check |
| http://localhost:4000/docs | **Swagger UI** (interactive API explorer) |
| http://localhost:4000/redoc | ReDoc API reference |
| http://localhost:4000/doctor-login | Doctor login web portal |
| http://localhost:4000/pharmacy-portal | Pharmacy web portal |

---

## 3. Quick Smoke Test

```powershell
.\venv\Scripts\python.exe -c "import urllib.request,json; r=urllib.request.urlopen('http://localhost:4000/health'); print(json.loads(r.read()))"
```
**Expected:** `{'status': 'healthy', 'version': '2.0.0', ...}`

---

## 4. Test All Endpoints — Swagger UI (Easiest)

1. Open **http://localhost:4000/docs** in your browser
2. Click any endpoint → **Try it out** → fill in values → **Execute**
3. See live response, status code, and auto-generated curl command

---

## 5. Endpoint Test Recipes

### Patient Registration & Login

**Register:**
```powershell
.\venv\Scripts\python.exe -c "import urllib.request,json; req=urllib.request.Request('http://localhost:4000/api/patient/register',data=json.dumps({'name':'Elena Vance','email':'elena@test.com','password':'secret123'}).encode(),headers={'Content-Type':'application/json'},method='POST'); print(json.loads(urllib.request.urlopen(req).read()))"
```

**Login (saves token):**
```powershell
.\venv\Scripts\python.exe -c "import urllib.request,json; req=urllib.request.Request('http://localhost:4000/api/patient/login',data=json.dumps({'email':'elena@test.com','password':'secret123'}).encode(),headers={'Content-Type':'application/json'},method='POST'); r=json.loads(urllib.request.urlopen(req).read()); print('Token:', r['token'])"
```
> Copy the `token` value — needed for blockchain endpoints (`X-Session-Token` header).

---

### Doctor Register & Login

**Register:**
```powershell
.\venv\Scripts\python.exe -c "import urllib.request,json; req=urllib.request.Request('http://localhost:4000/api/doctor/register',data=json.dumps({'name':'Dr. Arun Kumar','hospitalName':'Apollo Hospital','doctorMobile':'9876543210'}).encode(),headers={'Content-Type':'application/json'},method='POST'); print(json.loads(urllib.request.urlopen(req).read()))"
```

**Login:**
```powershell
.\venv\Scripts\python.exe -c "import urllib.request,json; req=urllib.request.Request('http://localhost:4000/api/doctor/login',data=json.dumps({'doctorMobile':'9876543210'}).encode(),headers={'Content-Type':'application/json'},method='POST'); print(json.loads(urllib.request.urlopen(req).read()))"
```

---

### Patient Dashboard & Prescriptions

```powershell
# Dashboard summary
.\venv\Scripts\python.exe -c "import urllib.request,json; print(json.dumps(json.loads(urllib.request.urlopen('http://localhost:4000/api/patient/dashboard/Elenavan').read()),indent=2))"

# All prescriptions
.\venv\Scripts\python.exe -c "import urllib.request,json; data=json.loads(urllib.request.urlopen('http://localhost:4000/api/prescriptions?patient=Elenavan').read()); [print(r['id'],'|',r['disease'],'| dispensed:',r['isDispensed']) for r in data]"
```

---

### Consultation Consent Flow (Full Cycle)

**Step 1 — Doctor requests access:**
```powershell
.\venv\Scripts\python.exe -c "import urllib.request,json; req=urllib.request.Request('http://localhost:4000/api/consultation/request',data=json.dumps({'patientName':'Elenavan','patientId':'EV-001','doctorId':'9876543210'}).encode(),headers={'Content-Type':'application/json'},method='POST'); r=json.loads(urllib.request.urlopen(req).read()); print('Request ID:',r['id'],'| Status:',r['status'])"
```
> Note the `id` value (e.g. `req_a1b2c3d4`)

**Step 2 — Patient checks pending requests:**
```powershell
.\venv\Scripts\python.exe -c "import urllib.request,json; print(json.loads(urllib.request.urlopen('http://localhost:4000/api/consultation/pending?patient=Elenavan').read()))"
```

**Step 3 — Patient accepts (replace `PASTE_ID`):**
```powershell
.\venv\Scripts\python.exe -c "import urllib.request,json; req=urllib.request.Request('http://localhost:4000/api/consultation/accept',data=json.dumps({'id':'PASTE_REQ_ID_HERE'}).encode(),headers={'Content-Type':'application/json'},method='POST'); print(json.loads(urllib.request.urlopen(req).read()))"
```

---

### AI Audit (Full Clinical Check)

```powershell
.\venv\Scripts\python.exe -c "
import urllib.request,json
req=urllib.request.Request('http://localhost:4000/api/audit',
  data=json.dumps({'patient_id':'Elenavan','doctor_id':'NPI-88912','new_medicine':'Penicillin V','new_dosage':'500mg','disease':'Acute Strep Throat'}).encode(),
  headers={'Content-Type':'application/json'},method='POST')
r=json.loads(urllib.request.urlopen(req).read())
print('Alert Level :',r['overall_alert_level'])
print('Recommendation:',r['final_recommendation'])
print('Duplicate    :',r['duplicate_check']['is_duplicate'])
print('Allergy      :',r['allergy_check']['allergy_conflict'])
print('Interaction  :',r['interaction_check']['interaction_risk'])
"
```

---

### Create a Prescription (Sign & Store)

```powershell
.\venv\Scripts\python.exe -c "
import urllib.request,json
rx={'id':'RX-TEST-001','doctorName':'Dr. Arun Kumar','hospitalName':'Apollo Hospital','patientName':'Elenavan','disease':'Type 2 Diabetes','date':'2026-07-05','time':'10:00','medicines':[{'name':'Metformin 500mg','interval':'Once daily after breakfast'}],'doctorSignId':'9876543210'}
req=urllib.request.Request('http://localhost:4000/api/prescriptions',data=json.dumps(rx).encode(),headers={'Content-Type':'application/json'},method='POST')
r=json.loads(urllib.request.urlopen(req).read())
print('id:',r['id'],'| signature:',r['signature'][:20],'... | dispensed:',r['isDispensed'])
"
```

---

### Pharmacy — Fetch, Verify & Dispense

**Fetch by RX ID:**
```powershell
.\venv\Scripts\python.exe -c "import urllib.request,json; print(json.dumps(json.loads(urllib.request.urlopen('http://localhost:4000/api/prescriptions/RX-9921').read()),indent=2))"
```

**Dispense:**
```powershell
.\venv\Scripts\python.exe -c "import urllib.request,json; req=urllib.request.Request('http://localhost:4000/api/prescriptions/dispense',data=json.dumps({'id':'RX-TEST-001'}).encode(),headers={'Content-Type':'application/json'},method='POST'); r=json.loads(urllib.request.urlopen(req).read()); print('isDispensed:',r['isDispensed'])"
```

---

### Blockchain & Ledger

```powershell
# Verify chain integrity (no auth required)
.\venv\Scripts\python.exe -c "import urllib.request,json; print(json.loads(urllib.request.urlopen('http://localhost:4000/api/blockchain/verify').read()))"

# Check doctor access grant
.\venv\Scripts\python.exe -c "import urllib.request,json; print(json.loads(urllib.request.urlopen('http://localhost:4000/api/access/status?doctor_id=9876543210&patient_name=Elenavan').read()))"

# Last 5 activity log entries
.\venv\Scripts\python.exe -c "import urllib.request,json; logs=json.loads(urllib.request.urlopen('http://localhost:4000/api/activity-logs').read()); [print(l['eventType'],'|',l['patientName'],'|',l['actorId']) for l in logs[:5]]"
```

---

### Doctor Pattern Analysis

```powershell
.\venv\Scripts\python.exe -c "import urllib.request,json; print(json.dumps(json.loads(urllib.request.urlopen('http://localhost:4000/api/pattern-analysis/9876543210').read()),indent=2))"
```

---

## 6. curl Equivalents

```bash
# Health check
curl http://localhost:4000/health

# Full AI Audit
curl -X POST http://localhost:4000/api/audit \
  -H "Content-Type: application/json" \
  -d '{"patient_id":"Elenavan","doctor_id":"NPI-88912","new_medicine":"Penicillin V","new_dosage":"500mg","disease":"Acute Strep Throat"}'

# Patient dashboard
curl http://localhost:4000/api/patient/dashboard/Elenavan

# Blockchain integrity
curl http://localhost:4000/api/blockchain/verify

# Doctor register
curl -X POST http://localhost:4000/api/doctor/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Dr. Arun Kumar","hospitalName":"Apollo Hospital","doctorMobile":"9876543210"}'
```

---

## 7. Common Errors & Fixes

| Error | Cause | Fix |
|---|---|---|
| `No module named 'argon2'` | Running system Python, not venv | Use `.\venv\Scripts\python.exe` explicitly |
| `Connection refused` | Server not started | Run the uvicorn command in Step 2 |
| `503 AI Agent unavailable` | AIAgent init failed | Check `.env` MongoDB URI and Cerebras key |
| `401 Invalid or expired session` | Missing `X-Session-Token` header | Log in first, pass `token` as `X-Session-Token` header |
| `409 Already dispensed` | Dispensing same prescription twice | Expected — single-use token is burned by design |
| `403 Access denied` | Doctor has no active consultation grant | Run consultation accept flow first |
| `404 Prescription not found` | Wrong RX ID | Check prescription ID with `GET /api/prescriptions?patient=...` |
