import asyncio
import httpx

async def test_scenarios():
    audit_url = "http://127.0.0.1:4005/api/audit"
    prescription_url = "http://127.0.0.1:4004/api/prescriptions"
    
    print("======================================================================")
    print("  AegisRx — CDSS Clinical Audit and Decoupled AI Verification Tests")
    print("======================================================================")
    
    # ── Test Scenario 1: Deterministic Safety Check & Decoupled AI Explanation ──
    print("\n[TEST 1] Querying Audit Service for Penicillin Allergy check...")
    audit_payload = {
        "patient_id": "elena_vance",
        "doctor_id": "889218",
        "new_medicine": "Amoxicillin",
        "new_dosage": "500mg",
        "disease": "Streptococcal Pharyngitis"
    }
    
    async with httpx.AsyncClient() as client:
        try:
            res = await client.post(audit_url, json=audit_payload, timeout=15.0)
            print(f"Audit Status: {res.status_code}")
            if res.status_code == 200:
                data = res.json()
                print(f"  - Risk Level: {data.get('risk_level')}")
                print(f"  - Risk Score: {data.get('risk_score')}")
                print(f"  - Action: {data.get('recommended_action')}")
                print(f"  - AI Explanation: {data.get('clinical_explanation')}")
                assert data.get("risk_level") in ("CRITICAL", "HIGH_RISK")
                print("[PASS] Test 1: Safety engine correctly identified risk deterministically!")
            else:
                print(f"[FAIL] Test 1 returned status {res.status_code}: {res.text}")
        except Exception as e:
            print(f"[FAIL] Connection to Audit Service failed: {e}")

        # ── Test Scenario 2: Save Interceptor blocks creation without Doctor Override ──
        print("\n[TEST 2] Submitting high-risk prescription WITHOUT doctor override reason...")
        rx_payload_no_override = {
            "id": "test-rx-blocked-101",
            "patientName": "elena_vance",
            "patient_id": "elena_vance",
            "doctorName": "Dr. Gordon Freeman",
            "doctorSignId": "889218",
            "disease": "Streptococcal Pharyngitis",
            "date": "2026-07-18",
            "time": "12:00",
            "hospitalName": "Black Mesa Clinical Center",
            "medicines": [
                {
                    "name": "Amoxicillin",
                    "interval": "Three times daily",
                    "duration": "10 days",
                    "strength": "500mg"
                }
            ],
            "overrideReason": ""
        }
        
        try:
            res = await client.post(prescription_url, json=rx_payload_no_override, timeout=15.0)
            print(f"Prescription Status: {res.status_code}")
            print(f"Response Payload: {res.text}")
            if res.status_code == 403:
                print("[PASS] Test 2: Prescription Service successfully blocked unsafe write without override!")
            else:
                print("[FAIL] Test 2 did not return 403 Forbidden status!")
        except Exception as e:
            print(f"[FAIL] Connection to Prescription Service failed: {e}")

        # ── Test Scenario 3: Save Interceptor allows creation WITH Doctor Override ──
        print("\n[TEST 3] Submitting high-risk prescription WITH doctor override reason...")
        rx_payload_with_override = rx_payload_no_override.copy()
        rx_payload_with_override["id"] = "test-rx-allowed-102"
        rx_payload_with_override["overrideReason"] = "Patient tolerated beta-lactam therapy previously under clinical observation"
        
        try:
            res = await client.post(prescription_url, json=rx_payload_with_override, timeout=15.0)
            print(f"Prescription Status: {res.status_code}")
            if res.status_code in (200, 201):
                print("[PASS] Test 3: Prescription successfully saved with signed doctor override justification!")
            else:
                print(f"[FAIL] Test 3 returned status {res.status_code}: {res.text}")
        except Exception as e:
            print(f"[FAIL] Connection to Prescription Service failed: {e}")

if __name__ == "__main__":
    asyncio.run(test_scenarios())
