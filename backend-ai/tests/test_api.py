import pytest
from uuid import UUID

def test_get_health(client):
    """Verify that the health check endpoint returns service status."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "llm_provider" in data

def test_post_analyze_high_risk(client, patient_warfarin_ibuprofen):
    """Verify prescription analysis flags high risk and returns clinical detail."""
    response = client.post("/analyze", json=patient_warfarin_ibuprofen)
    assert response.status_code == 200
    
    data = response.json()
    assert "analysis_id" in data
    assert data["risk_level"] == "HIGH_RISK"
    assert data["recommended_action"] == "DO_NOT_DISPENSE"
    assert len(data["detected_drug_interactions"]) > 0
    assert len(data["disease_contraindications"]) > 0
    assert "Acetaminophen" in data["suggested_alternative_medicines"]
    assert "AegisRx AI Sentinel" in data["clinical_explanation"]  # Disclaimer appended

def test_post_analyze_safe_aspirin(client, patient_safe_aspirin):
    """Verify prescription analysis for a safe profile."""
    response = client.post("/analyze", json=patient_safe_aspirin)
    assert response.status_code == 200
    
    data = response.json()
    assert data["risk_level"] in ["SAFE", "WARNING"]  # Safe profile

def test_post_analyze_validation_error(client):
    """Verify that malformed patient inputs return 422 unprocessable content or 400."""
    # Invalid age (negative)
    payload = {
        "patient_id": "PT999",
        "age": -10,
        "gender": "Male",
        "new_prescription": ["Aspirin"]
    }
    response = client.post("/analyze", json=payload)
    assert response.status_code == 422  # Pydantic validation error

    # Empty new prescription list
    payload = {
        "patient_id": "PT999",
        "age": 20,
        "gender": "Male",
        "new_prescription": []
    }
    response = client.post("/analyze", json=payload)
    assert response.status_code == 422

def test_audit_logs_retrieval(client, patient_warfarin_ibuprofen):
    """Verify that audit logs are populated upon analysis and accessible via POST /audit."""
    # First, run an analysis to populate the audit store
    analyze_resp = client.post("/analyze", json=patient_warfarin_ibuprofen)
    assert analyze_resp.status_code == 200
    analysis_id = analyze_resp.json()["analysis_id"]

    # 1. Fetch all audit logs (no analysis_id specified)
    audit_resp = client.post("/audit", json={})
    assert audit_resp.status_code == 200
    all_logs = audit_resp.json()
    assert isinstance(all_logs, list)
    assert len(all_logs) > 0
    
    # 2. Fetch specific audit log by analysis_id
    audit_spec_resp = client.post("/audit", json={"analysis_id": analysis_id})
    assert audit_spec_resp.status_code == 200
    specific_log = audit_spec_resp.json()
    assert specific_log["analysis_id"] == analysis_id
    assert "raw_prompt_system" in specific_log
    assert "raw_prompt_user" in specific_log
    assert "raw_llm_response" in specific_log
    assert specific_log["analysis_result"]["risk_level"] == "HIGH_RISK"

    # 3. Request invalid analysis_id should return 404
    non_existent_uuid = "99999999-9999-9999-9999-999999999999"
    audit_err_resp = client.post("/audit", json={"analysis_id": non_existent_uuid})
    assert audit_err_resp.status_code == 404
