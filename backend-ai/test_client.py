import httpx
import json
import time
import subprocess
import sys

# Define base URL for local FastAPI instance
BASE_URL = "http://127.0.0.1:8000"

# Mock Patient Contexts
PATIENT_WARFARIN_IBUPROFEN = {
    "patient_id": "PT123",
    "age": 65,
    "gender": "Male",
    "weight": 72.0,
    "allergies": ["Penicillin"],
    "diseases": ["Chronic Kidney Disease", "Hypertension"],
    "current_medications": ["Warfarin", "Metformin"],
    "previous_prescriptions": ["Aspirin", "Amoxicillin"],
    "new_prescription": ["Ibuprofen"]
}

PATIENT_PREGNANT_WARFARIN = {
    "patient_id": "PT789",
    "age": 28,
    "gender": "Female",
    "weight": 64.5,
    "allergies": [],
    "diseases": ["Pregnancy"],
    "current_medications": [],
    "previous_prescriptions": [],
    "new_prescription": ["Warfarin"]
}

def test_endpoints():
    print("=== STARTING AEGISRX AI SENTINEL LOCAL API TESTS ===\n")

    # 1. Test GET /health
    print("[1/4] Querying GET /health...")
    try:
        response = httpx.get(f"{BASE_URL}/health", timeout=30.0)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}\n")
    except Exception as e:
        print(f"Error querying /health: {e}")
        print("Make sure the FastAPI server is running on http://127.0.0.1:8000\n")
        return

    # 2. Test POST /analyze (Warfarin + Ibuprofen)
    print("[2/4] Testing POST /analyze (Geriatric Patient + Warfarin + Ibuprofen)...")
    try:
        response = httpx.post(f"{BASE_URL}/analyze", json=PATIENT_WARFARIN_IBUPROFEN, timeout=30.0)
        print(f"Status Code: {response.status_code}")
        data = response.json()
        analysis_id = data.get("analysis_id")
        print(f"Risk Level: {data.get('risk_level')}")
        print(f"Recommended Action: {data.get('recommended_action')}")
        print(f"Reasons: {data.get('reasons')}")
        print(f"Suggested Alternatives: {data.get('suggested_alternative_medicines')}")
        print(f"Clinical Explanation Summary:\n{data.get('clinical_explanation')}\n")
    except Exception as e:
        print(f"Error querying /analyze: {e}\n")
        return

    # 3. Test POST /analyze (Pregnancy + Warfarin)
    print("[3/4] Testing POST /analyze (Pregnancy + Warfarin)...")
    try:
        response = httpx.post(f"{BASE_URL}/analyze", json=PATIENT_PREGNANT_WARFARIN, timeout=30.0)
        print(f"Status Code: {response.status_code}")
        data = response.json()
        print(f"Risk Level: {data.get('risk_level')}")
        print(f"Recommended Action: {data.get('recommended_action')}")
        print(f"Reasons: {data.get('reasons')}\n")
    except Exception as e:
        print(f"Error querying /analyze (pregnancy): {e}\n")
        return

    # 4. Test POST /audit
    if analysis_id:
        print(f"[4/4] Querying POST /audit for Run ID {analysis_id}...")
        try:
            response = httpx.post(f"{BASE_URL}/audit", json={"analysis_id": analysis_id}, timeout=30.0)
            print(f"Status Code: {response.status_code}")
            audit_data = response.json()
            print("Audit Log Entry details:")
            print(f"  Timestamp: {audit_data.get('timestamp')}")
            print(f"  System Prompt Length: {len(audit_data.get('raw_prompt_system'))} characters")
            print(f"  User Prompt Length: {len(audit_data.get('raw_prompt_user'))} characters")
            print(f"  Raw LLM Output Length: {len(audit_data.get('raw_llm_response'))} characters")
            print(f"  Execution Latency: {audit_data.get('latency_ms') if audit_data.get('latency_ms') else data.get('metadata', {}).get('latency_ms', 0):.2f}ms\n")
        except Exception as e:
            print(f"Error querying /audit: {e}\n")

    print("=== END OF TESTS ===")

if __name__ == "__main__":
    test_endpoints()
