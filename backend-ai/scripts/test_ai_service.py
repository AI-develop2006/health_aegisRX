import asyncio
import httpx
import traceback

async def test_ai():
    url = "http://127.0.0.1:4008/api/ai/explain"
    payload = {
        "risk_score": 95,
        "risk_level": "HIGH_RISK",
        "triggered_rules": ["Penicillin Allergy"],
        "recommended_action": "DO_NOT_DISPENSE",
        "patient_age": 65,
        "patient_gender": "Male",
        "patient_allergies": ["Penicillin"],
        "patient_diseases": [],
        "current_medicines": [],
        "new_prescription_medicines": ["Amoxicillin"]
    }
    
    print("Sending test request to AI Service explain endpoint (90s timeout)...")
    async with httpx.AsyncClient() as client:
        try:
            resp = await client.post(url, json=payload, timeout=90.0)
            print(f"Status Code: {resp.status_code}")
            print("Response payload:")
            print(resp.json())
        except Exception as e:
            print("Failed to query AI service:")
            traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(test_ai())
