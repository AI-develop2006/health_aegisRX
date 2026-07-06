import os
import sys
import time
import requests

# Set API Base URL (assumes gateway is running locally on port 4000)
API_BASE_URL = os.getenv("API_BASE_URL", "http://127.0.0.1:4000")

def run_e2e_test():
    print("====================================================")
    print("      AegisRx / HealthLock Polygon E2E Tester       ")
    print("====================================================")
    print(f"Targeting server: {API_BASE_URL}\n")
    
    # 1. Create a unique demo prescription ID
    rx_id = f"RX-TEST-{int(time.time())}"
    
    prescription_payload = {
        "id": rx_id,
        "doctorName": "Dr. Gregory House",
        "hospitalName": "Princeton-Plainsboro",
        "patientName": "John Doe",
        "disease": "Lupus",
        "date": "2026-07-06",
        "time": "12:00",
        "doctorSignId": "889218",
        "medicines": [
            {"name": "Prednisone", "interval": "Once daily"}
        ]
    }
    
    # Step 1: Create/Sign Prescription
    print(f"--- STEP 1: Creating Prescription {rx_id} ---")
    try:
        response = requests.post(f"{API_BASE_URL}/api/prescriptions", json=prescription_payload)
    except requests.exceptions.ConnectionError:
        print(f"ERROR: Could not connect to the backend server at {API_BASE_URL}.")
        print("Please make sure your FastAPI server is running (`uvicorn app.main:app --port 5000`).")
        sys.exit(1)
        
    if response.status_code != 200:
        print(f"Failed to create prescription. Status: {response.status_code}, Body: {response.text}")
        sys.exit(1)
        
    res_data = response.json()
    print("Prescription created successfully in MongoDB.")
    
    onchain_tx = res_data.get("onchain_tx_hash")
    if onchain_tx:
        print(f"Polygon On-Chain Tx Hash: {onchain_tx}")
        print(f"View on Polygonscan: https://amoy.polygonscan.com/tx/{onchain_tx}")
    else:
        print("On-Chain transaction hash not found. Running in local/mock database mode.")
        print("(Verify POLYGON_CONTRACT_ADDRESS and TEST_DOCTOR_PRIVATE_KEY are set in your .env)")
        
    # Step 2: Verify Scan
    print(f"\n--- STEP 2: Verifying Scanned Payload ---")
    sig = res_data.get("signature")
    
    # Construct raw payload exactly as signature decrypt expects
    raw_payload = (
        f"{rx_id}|Dr. Gregory House|Princeton-Plainsboro|John Doe|Lupus|2026-07-06|12:00|"
        "Prednisone:Once daily|889218"
    )
    
    verify_payload = {
        "raw_payload": raw_payload,
        "signature": sig,
        "timestamp": str(int(time.time()))
    }
    
    response = requests.post(f"{API_BASE_URL}/api/prescriptions/verify-scan", json=verify_payload)
    if response.status_code != 200:
        print(f"Verify scan failed. Status: {response.status_code}, Body: {response.text}")
        sys.exit(1)
        
    verify_data = response.json()
    print(f"Verification Result: {verify_data.get('verdict')}")
    print(f"Blockchain Verification Status: {verify_data.get('chain_verified')}")
    
    if not verify_data.get("verified"):
        print(f"Verification error detail: {verify_data.get('reason')}")
        sys.exit(1)
        
    # Step 3: Dispense Prescription
    print(f"\n--- STEP 3: Dispensing Prescription ---")
    dispense_payload = {
        "id": rx_id
    }
    response = requests.post(f"{API_BASE_URL}/api/prescriptions/dispense", json=dispense_payload)
    if response.status_code != 200:
        print(f"Dispense failed. Status: {response.status_code}, Body: {response.text}")
        sys.exit(1)
        
    dispense_data = response.json()
    print(f"Dispensed successfully. MongoDB isDispensed: {dispense_data.get('isDispensed')}")
    
    # Step 4: Double-Dispense Block Check
    print(f"\n--- STEP 4: Double-Dispense Block Check ---")
    response = requests.post(f"{API_BASE_URL}/api/prescriptions/verify-scan", json=verify_payload)
    verify_data_retry = response.json()
    print(f"Verification Verdict (Retry): {verify_data_retry.get('verdict')}")
    print(f"Reason: {verify_data_retry.get('reason')}")
    
    if not verify_data_retry.get("verified") and "DISPENSED" in verify_data_retry.get("verdict"):
        print("\nSUCCESS: End-to-end integration flow verified successfully!")
    else:
        print("\nERROR: Double-dispense verification logic failed to block reuse.")

if __name__ == "__main__":
    run_e2e_test()
