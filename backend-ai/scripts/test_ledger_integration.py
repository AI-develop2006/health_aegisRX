import httpx
import time
import asyncio

URL = "http://127.0.0.1:4007"

async def test_dlq_flow():
    print("=========================================================")
    # 1. Dispatching a normal audit event to make sure it queues and passes
    print("[TEST 1] Dispatching a Normal Audit Event...")
    normal_payload = {
        "audit_id": "test-normal-uuid-" + str(int(time.time())),
        "patient_id": "anon-patient-101",
        "doctor_id": "doc-01",
        "risk_band": "LOW",
        "decision_type": "approved",
        "audit_hash": "SHA256-abc123xyz",
        "timestamp": "2026-07-15T12:00:00Z"
    }
    
    async with httpx.AsyncClient() as client:
        res = await client.post(f"{URL}/api/ledger/audit-event", json=normal_payload)
        print(f"Status: {res.status_code}, Response: {res.json()}")
        assert res.status_code == 202
        assert res.json()["status"] == "ACCEPTED"
        print("--> Test 1 Passed! Normal event queued.")

        # 2. Dispatching a failing audit event to trigger retries and DLQ
        print("\n[TEST 2] Dispatching a failing Audit Event ('force_fail_ledger')...")
        fail_payload = {
            "audit_id": "force_fail_ledger",
            "patient_id": "anon-patient-999",
            "doctor_id": "doc-01",
            "risk_band": "HIGH",
            "decision_type": "blocked",
            "audit_hash": "SHA256-fail-hash-xyz",
            "timestamp": "2026-07-15T12:00:00Z"
        }
        
        res = await client.post(f"{URL}/api/ledger/audit-event", json=fail_payload)
        print(f"Status: {res.status_code}, Response: {res.json()}")
        assert res.status_code == 202
        assert res.json()["status"] == "ACCEPTED"
        print("--> Event queued. Waiting 10 seconds for backoff retries to fail permanently...")
        
        # Backoff retries take: 2^0 (1s) + 2^1 (2s) + 2^2 (4s) = 7 seconds
        await asyncio.sleep(10)
        
        # 3. Retrieve DLQ records
        print("\n[TEST 3] Querying DLQ Admin Endpoint...")
        dlq_res = await client.get(f"{URL}/api/ledger/admin/dlq")
        print(f"Status: {dlq_res.status_code}, Response: {dlq_res.json()}")
        assert dlq_res.status_code == 200
        dlq_list = dlq_res.json().get("dlq", [])
        
        found = None
        for record in dlq_list:
            if record.get("payload", {}).get("audit_id") == "force_fail_ledger":
                found = record
                break
                
        assert found is not None
        dlq_id = found["_id"]
        print(f"--> Test 3 Passed! Permanent failure found in DLQ with ID: {dlq_id}")
        
        # 4. Trigger manual retry
        print(f"\n[TEST 4] Triggering manual retry for record {dlq_id}...")
        retry_res = await client.post(f"{URL}/api/ledger/admin/dlq/{dlq_id}/retry")
        print(f"Status: {retry_res.status_code}, Response: {retry_res.json()}")
        assert retry_res.status_code == 200
        assert retry_res.json()["status"] == "SUCCESS"
        print("--> Test 4 Passed! Manual retry initiated.")
        
        # 5. Resolve DLQ record
        print(f"\n[TEST 5] Resolving DLQ record {dlq_id}...")
        resolve_res = await client.post(f"{URL}/api/ledger/admin/dlq/{dlq_id}/resolve")
        print(f"Status: {resolve_res.status_code}, Response: {resolve_res.json()}")
        assert resolve_res.status_code == 200
        assert resolve_res.json()["status"] == "SUCCESS"
        print("--> Test 5 Passed! Record resolved.")
        
        # 6. Delete DLQ record
        print(f"\n[TEST 6] Deleting DLQ record {dlq_id}...")
        delete_res = await client.delete(f"{URL}/api/ledger/admin/dlq/{dlq_id}")
        print(f"Status: {delete_res.status_code}, Response: {delete_res.json()}")
        assert delete_res.status_code == 200
        assert delete_res.json()["status"] == "SUCCESS"
        print("--> Test 6 Passed! DLQ record cleaned.")
        
    print("\n=========================================================")
    print(" AegisRx: All 6 Ledger Async & DLQ Features Verified!   ")
    print("=========================================================")

if __name__ == "__main__":
    asyncio.run(test_dlq_flow())
