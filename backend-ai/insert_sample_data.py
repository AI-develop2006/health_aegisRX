import json
import os
import logging
import uuid
import hashlib
from datetime import datetime
from pymongo import MongoClient
from dotenv import load_dotenv

# Load env variables from .env file
load_dotenv(override=True)

# Configure local logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("DatabasePopulator")

# Read environment variables directly with defaults
MONGODB_URI = os.getenv("MONGODB_URI", "mongodb://localhost:27017/")
MONGODB_DATABASE = os.getenv("MONGODB_DATABASE", "healthcare_db")
COLLECTION_PRESCRIPTIONS = os.getenv("COLLECTION_PRESCRIPTIONS", "prescriptions")
COLLECTION_ALLERGIES = os.getenv("COLLECTION_ALLERGIES", "allergies")

def seed_mock_db(data):
    logger.info("Seeding local Mock DB (.mock_db)...")
    current_dir = os.path.dirname(os.path.abspath(__file__))
    db_dir = os.path.join(current_dir, ".mock_db")
    os.makedirs(db_dir, exist_ok=True)

    # 1. Seed Patients
    patients = data.get("patients", [])
    from argon2 import PasswordHasher
    ph = PasswordHasher()
    for p in patients:
        p["password_hash"] = ph.hash("AegisRx@2026")
    with open(os.path.join(db_dir, "patients.json"), "w") as f:
        json.dump(patients, f, default=str, indent=2)
    logger.info(f"Seeded mock DB: patients.json ({len(patients)} records)")

    # 2. Seed Doctors
    doctors = data.get("doctors", [])
    doctor_ids = {d.get("doctor_id") for d in doctors}
    if "Dr_Arun_456" not in doctor_ids:
        doctors.append({"doctor_id": "Dr_Arun_456", "name": "Dr. Arun Sharma"})
    if "Dr_Kumar_456" not in doctor_ids:
        doctors.append({"doctor_id": "Dr_Kumar_456", "name": "Dr. Kumar Patel"})
    if "NPI-1002288" not in doctor_ids:
        doctors.append({"doctor_id": "NPI-1002288", "name": "Alexander Vance"})
    if "9876543210" not in doctor_ids:
        doctors.append({"doctor_id": "9876543210", "name": "Default Test Doctor"})
    with open(os.path.join(db_dir, "doctor.json"), "w") as f:
        json.dump(doctors, f, default=str, indent=2)
    logger.info(f"Seeded mock DB: doctor.json ({len(doctors)} records)")

    # 3. Seed Allergies
    allergies = data.get("allergies", [])
    extra_allergies = []
    for a in allergies:
        p_id = a.get("patient_id")
        if p_id:
            if "_" in p_id:
                extra_allergies.append({**a, "patient_id": p_id.replace("_", " ")})
            else:
                extra_allergies.append({**a, "patient_id": p_id.replace(" ", "_")})
    allergies.extend(extra_allergies)
    with open(os.path.join(db_dir, "allergies.json"), "w") as f:
        json.dump(allergies, f, default=str, indent=2)
    logger.info(f"Seeded mock DB: allergies.json ({len(allergies)} records)")

    # 4. Seed Prescriptions
    prescriptions = data.get("prescriptions", [])
    extra_prescriptions = []
    for p in prescriptions:
        p_id = p.get("patient_id")
        if p_id:
            if "_" in p_id:
                p_copy = p.copy()
                p_copy["patient_id"] = p_id.replace("_", " ")
                extra_prescriptions.append(p_copy)
            else:
                p_copy = p.copy()
                p_copy["patient_id"] = p_id.replace(" ", "_")
                extra_prescriptions.append(p_copy)
    prescriptions.extend(extra_prescriptions)
    with open(os.path.join(db_dir, "prescriptions.json"), "w") as f:
        json.dump(prescriptions, f, default=str, indent=2)
    logger.info(f"Seeded mock DB: prescriptions.json ({len(prescriptions)} records)")

    # 5. Seed Blockchain Blocks (ACCESS_GRANT and VISIT_HISTORY)
    def compute_hash(b):
        payload = json.dumps({
            "index": b["index"],
            "block_type": b["block_type"],
            "data": b["data"],
            "previous_hash": b["previous_hash"],
            "timestamp": b["timestamp"],
        }, sort_keys=True)
        return hashlib.sha256(payload.encode("utf-8")).hexdigest()

    blocks = []
    index = 1
    prev_hash = "0" * 64

    # Seed ACCESS_GRANT and VISIT_HISTORY blocks for each doctor-patient pair
    for doc in doctors:
        d_id = doc["doctor_id"]
        for pat in ["Priya_123", "priya_123", "Priya Sharma", "Elena Vance", "elena_vance"]:
            pat_name = "Priya Sharma" if "priya" in pat.lower() else "Elena Vance"
            
            # Access grant block
            b_data = {
                "request_id": str(uuid.uuid4()),
                "patient_name": pat_name,
                "patient_id": pat,
                "doctor_id": d_id,
                "granted_at": datetime.utcnow().isoformat() + "Z",
            }
            block = {
                "index": index,
                "block_type": "ACCESS_GRANT",
                "data": b_data,
                "previous_hash": prev_hash,
                "timestamp": int(datetime.utcnow().timestamp() * 1000),
            }
            block["hash"] = compute_hash(block)
            blocks.append(block)
            prev_hash = block["hash"]
            index += 1

            # Visit history block
            visit_data = {
                "patient_name": pat_name,
                "patient_id": pat,
                "doctor_id": d_id,
                "doctor_name": doc["name"],
                "hospital": doc.get("hospitalName") or "Metropolitan Hospital Centre",
                "disease": "Chronic Hypertension Follow-up" if "priya" in pat.lower() else "Post-op Cardiac Checkup",
                "rx_id": "rx_" + str(uuid.uuid4())[:8],
                "date": "2026-06-25T10:00:00"
            }
            v_block = {
                "index": index,
                "block_type": "VISIT_HISTORY",
                "data": visit_data,
                "previous_hash": prev_hash,
                "timestamp": int(datetime.utcnow().timestamp() * 1000) - 86400000,
            }
            v_block["hash"] = compute_hash(v_block)
            blocks.append(v_block)
            prev_hash = v_block["hash"]
            index += 1

    with open(os.path.join(db_dir, "blockchain.json"), "w") as f:
        json.dump(blocks, f, default=str, indent=2)
    logger.info(f"Seeded mock DB: blockchain.json ({len(blocks)} blocks)")

def populate_database():
    logger.info("Starting database population with sample test data...")
    
    # Path to test data file
    json_path = os.path.join("test_data", "sample_patient.json")
    if not os.path.exists(json_path):
        logger.error(f"Sample data file not found at: {json_path}")
        return
        
    with open(json_path, "r") as f:
        data = json.load(f)
        
    # Always seed local Mock DB first
    try:
        seed_mock_db(data)
    except Exception as e:
        logger.error(f"Error seeding local mock database: {e}")

    # Connect to MongoDB
    client = None
    try:
        logger.info(f"Connecting to MongoDB Atlas at URI: {MONGODB_URI}")
        client = MongoClient(MONGODB_URI, serverSelectionTimeoutMS=2000, timeoutMS=5000)
        client.server_info() # Trigger connection check
        db = client[MONGODB_DATABASE]
        
        # Reset collections
        db[COLLECTION_PRESCRIPTIONS].drop()
        db[COLLECTION_ALLERGIES].drop()
        db["patients"].drop()
        db["doctor"].drop()
        
        logger.info("Cleared existing collections: patients, prescriptions, allergies, doctor")
        
        # Insert patients
        patients = data.get("patients", [])
        if patients:
            from argon2 import PasswordHasher
            ph = PasswordHasher()
            for p in patients:
                p["password_hash"] = ph.hash("AegisRx@2026")
            db["patients"].insert_many(patients)
            logger.info(f"Inserted {len(patients)} patients (passwords set to AegisRx@2026)")
            
        # Insert doctors
        doctors = data.get("doctors", [])
        if doctors:
            db["doctor"].insert_many(doctors)
            logger.info(f"Inserted {len(doctors)} doctor records")
            
        # Insert allergies
        allergies = data.get("allergies", [])
        if allergies:
            db[COLLECTION_ALLERGIES].insert_many(allergies)
            logger.info(f"Inserted {len(allergies)} allergy records")
            
        # Insert prescriptions (convert date strings to datetime objects)
        prescriptions = data.get("prescriptions", [])
        formatted_prescriptions = []
        for presc in prescriptions:
            presc_copy = presc.copy()
            if "date" in presc_copy:
                # Convert ISO format date string to datetime
                presc_copy["date"] = datetime.fromisoformat(presc_copy["date"])
            formatted_prescriptions.append(presc_copy)
            
        if formatted_prescriptions:
            db[COLLECTION_PRESCRIPTIONS].insert_many(formatted_prescriptions)
            logger.info(f"Inserted {len(formatted_prescriptions)} prescription records")
            
        logger.info("MongoDB Atlas population complete!")
        
    except Exception as e:
        logger.warning(f"MongoDB Atlas populate skipped: {str(e)}")
    finally:
        if client:
            client.close()

if __name__ == "__main__":
    populate_database()
