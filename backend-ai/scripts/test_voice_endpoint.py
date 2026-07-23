import asyncio
import httpx
import traceback

async def test_voice_parser():
    # Test local AI service port 4008 direct, or gateway port 4000
    url = "http://127.0.0.1:4008/api/ai/voice/parse"
    
    payload = {
        "patient_id": "P_NORMAL",
        "doctor_id": "889218",
        "transcript": "Give Priya Sharma Amoxicillin 500mg three times daily for ten days. Patient has fever."
    }
    
    print(f"Sending voice parse request to {url}...")
    async with httpx.AsyncClient() as client:
        try:
            resp = await client.post(url, json=payload, timeout=20.0)
            print(f"Status Code: {resp.status_code}")
            print("Response payload:")
            print(resp.json())
            
            # Assertions
            data = resp.json()
            assert data["status"] == "SUCCESS"
            assert "diagnosis" in data
            assert "medications" in data
            assert isinstance(data["medications"], list)
            print("\n[PASS] Voice parser endpoint behaves correctly and conforms to schema contract!")
        except Exception as e:
            print("[FAIL] Voice parser endpoint failed:")
            traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(test_voice_parser())
