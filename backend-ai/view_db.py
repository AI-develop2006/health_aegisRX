import os
import json
import pymongo
from datetime import datetime
from dotenv import load_dotenv

# Load connection URI
load_dotenv()
mongo_uri = os.getenv("MONGODB_URI", "mongodb+srv://user1:niveda01@cluster0.gfwepvj.mongodb.net/?appName=cluster0")
db_name = os.getenv("MONGODB_DATABASE", "healthcare_db")
force_mock = os.getenv("FORCE_MOCK_DB", "false").lower() == "true"

print("=============================================================")
print("          AegisRx — Live MongoDB Database Viewer              ")
print("=============================================================")

use_mock_local = force_mock
db = None

# Attempt cloud MongoDB Atlas connection first
if not use_mock_local:
    try:
        # print host info safely
        host_info = mongo_uri.split('@')[-1].split('/')[0]
        print(f"Connecting to cloud MongoDB Atlas ({host_info})...")
        client = pymongo.MongoClient(mongo_uri, serverSelectionTimeoutMS=2000, timeoutMS=4000)
        client.server_info()  # Trigger connection check
        db = client[db_name]
        print("✅ SUCCESS: Connected to live cloud MongoDB Atlas.")
    except Exception as e:
        print(f"⚠️ Cloud MongoDB Atlas unreachable: {e}")
        print("🔄 SWITCHING TO LOCAL MOCK DB (.mock_db folder) Fallback...")
        use_mock_local = True

# Helper to load local mock json files
def load_local_collection(col_name):
    path = os.path.join(".mock_db", f"{col_name}.json")
    if os.path.exists(path):
        try:
            with open(path, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception as e:
            print(f"Error loading local {col_name}.json: {e}")
    return []

if use_mock_local:
    print("📂 STATUS: Loading database collections from local mock JSON folder.")
    collections = ["activity_logs", "allergies", "doctor", "patients", "prescriptions", "blockchain"]
    print(f"📂 Found local collections: {', '.join(collections)}")

# --- Load and Print Activity Logs ---
print("\n📝 RECENT SYSTEM ACTIVITY LOGS (Immutable Audit Ledger):")
logs = []
if not use_mock_local and db is not None:
    try:
        logs = list(db["activity_logs"].find().sort("timestamp", -1).limit(5))
    except Exception as e:
        print(f"Error reading activity logs from Atlas: {e}")
else:
    local_logs = load_local_collection("activity_logs")
    # sort reverse by timestamp
    local_logs.sort(key=lambda x: str(x.get("timestamp", "")), reverse=True)
    logs = local_logs[:5]

if not logs:
    print("   (No logs registered yet)")
for log in logs:
    ts = log.get('timestamp')
    if isinstance(ts, datetime):
        ts = ts.isoformat()
    print(f"   • [{ts}] {log.get('eventType')} - {log.get('actorId')}: {log.get('details')}")
    if "hash" in log:
        print(f"     └─ Block SHA-256: {log.get('hash')}")

# --- Load and Print Prescriptions ---
print("\n💊 REGISTERED PRESCRIPTIONS:")
prescriptions = []
if not use_mock_local and db is not None:
    try:
        prescriptions = list(db["prescriptions"].find().sort("dispensedAt", -1).limit(10))
    except Exception as e:
        print(f"Error reading prescriptions from Atlas: {e}")
else:
    local_rx = load_local_collection("prescriptions")
    local_rx.sort(key=lambda x: str(x.get("dispensedAt") or x.get("date", "") + " " + x.get("time", "")), reverse=True)
    prescriptions = local_rx[:10]

if not prescriptions:
    print("   (No prescriptions registered yet)")
for rx in prescriptions:
    status = "Dispensed ✅" if rx.get("isDispensed") else "Pending/Active ⏳"
    print(f"   • [Rx ID: {rx.get('id')}] Patient: {rx.get('patientName')} - Status: {status}")
    print(f"     ├─ Diagnosis: {rx.get('disease')}")
    
    meds = rx.get('medicines', [])
    med_names = [m.get('name', 'Unknown') for m in meds] if isinstance(meds, list) else []
    print(f"     ├─ Prescribed Meds: {', '.join(med_names)}")
    
    # Override Justification
    if rx.get("overrideReason"):
        print(f"     ├─ Clinical Override justification: \"{rx.get('overrideReason')}\"")
    
    # Billing details
    if rx.get("billing_amount") is not None:
        receipt_status = "Attached" if rx.get("receipt_attached") else "Not Attached"
        try:
            val = float(rx.get("billing_amount"))
            print(f"     ├─ Total Bill: ${val:.2f} (Receipt: {receipt_status})")
        except:
            print(f"     ├─ Total Bill: ${rx.get('billing_amount')} (Receipt: {receipt_status})")
        
    # On-chain verification hash
    if rx.get("onchain_tx_hash"):
        print(f"     └─ Blockchain Tx Hash: {rx.get('onchain_tx_hash')}")
    print("     " + "-"*50)

print("\n=============================================================")
