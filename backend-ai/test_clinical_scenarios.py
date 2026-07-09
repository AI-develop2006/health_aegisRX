import os
import sys
import json
import asyncio
from pathlib import Path
from dotenv import load_dotenv

# Setup Python module search paths
BACKEND_DIR = Path(__file__).resolve().parent
sys.path.append(str(BACKEND_DIR))
sys.path.append(str(BACKEND_DIR / "services" / "audit-service"))

# Load env configurations
ENV_PATH = BACKEND_DIR / ".env"
load_dotenv(ENV_PATH, override=True)
os.environ["FORCE_MOCK_DB"] = "true"  # Ensure local file-based database operations
os.environ["USE_MOCK_AUDIT"] = "false"  # Run actual database contexts
os.environ["USE_MOCK_LLM"] = "false"    # Connect directly to Gemini API if active

from app.db import patients_col, prescriptions_col
from app.service import run_audit

async def setup_test_records():
    # 1. Clear any old test records in local mock database to prevent contamination
    print("[SETUP] Setting up clean clinical mock patient files in local database...")
    
    # Save a temporary patient Priya Sharma with no allergies
    patients_col().find_one_and_update(
        {"name": "TestPatient_Normal"},
        {"$set": {
            "patient_id": "P_NORMAL",
            "name": "TestPatient_Normal",
            "age": 35,
            "gender": "Male",
            "allergies": []
        }},
        upsert=True
    )
    
    # Save a patient with chronic Warfarin treatment (Warfarin in current meds)
    patients_col().find_one_and_update(
        {"name": "TestPatient_Warfarin"},
        {"$set": {
            "patient_id": "P_WARFARIN",
            "name": "TestPatient_Warfarin",
            "age": 62,
            "gender": "Female",
            "allergies": []
        }},
        upsert=True
    )
    
    # Create an active prescription for TestPatient_Warfarin containing Warfarin 5mg
    prescriptions_col().find_one_and_update(
        {"id": "RX-WARFARIN-SEED"},
        {"$set": {
            "id": "RX-WARFARIN-SEED",
            "patientName": "TestPatient_Warfarin",
            "isDispensed": False,
            "disease": "Atrial Fibrillation",
            "medicines": [{
                "name": "Warfarin",
                "strength": "5mg",
                "frequency": "Once daily",
                "morning": True
            }],
            "signature": "0x",
            "doctorSignId": "889218"
        }},
        upsert=True
    )

async def cleanup_test_records():
    print("\n[CLEANUP] Cleaning up test records...")
    patients_col().delete_many({"name": {"$in": ["TestPatient_Normal", "TestPatient_Warfarin"]}})
    prescriptions_col().delete_one({"id": "RX-WARFARIN-SEED"})
    print("[CLEANUP] Complete.")

async def run_diagnostics():
    await setup_test_records()
    
    print("\n" + "="*60)
    print("  DIAGNOSTIC TEST CASE A: Normal Safe Prescription")
    print("="*60)
    print("Regimen: Paracetamol 500mg (Patient: TestPatient_Normal, healthy)")
    try:
        res_a = await run_audit(
            patient_id="TestPatient_Normal",
            doctor_id="889218",
            new_medicine="Paracetamol",
            new_dosage="500mg every 6 hours PRN",
            disease="Fever"
        )
        print(json.dumps(res_a, indent=2))
    except Exception as e:
        print(f"Test A Failed: {e}")
        
    print("\n" + "="*60)
    print("  DIAGNOSTIC TEST CASE B: Clearly Risky Prescription")
    print("="*60)
    print("Regimen: Ibuprofen 400mg (Patient: TestPatient_Warfarin, on Warfarin 5mg)")
    try:
        res_b = await run_audit(
            patient_id="TestPatient_Warfarin",
            doctor_id="889218",
            new_medicine="Ibuprofen",
            new_dosage="400mg TID",
            disease="Arthritis"
        )
        print(json.dumps(res_b, indent=2))
    except Exception as e:
        print(f"Test B Failed: {e}")

    print("\n" + "="*60)
    print("  DIAGNOSTIC TEST CASE C: Unsupported / Unknown Tablet")
    print("="*60)
    print("Regimen: XYZTablet 123mg (Patient: TestPatient_Normal, healthy)")
    try:
        res_c = await run_audit(
            patient_id="TestPatient_Normal",
            doctor_id="889218",
            new_medicine="XYZTablet",
            new_dosage="123mg daily",
            disease="Unknown Pain"
        )
        print(json.dumps(res_c, indent=2))
    except Exception as e:
        print(f"Test C Failed: {e}")

    await cleanup_test_records()

if __name__ == "__main__":
    asyncio.run(run_diagnostics())
