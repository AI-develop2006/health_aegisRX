import pytest
import os
import sys

# Force tests to find the app module relative to the workspace root
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

# Configure test environment variables before importing app components
os.environ["ENV"] = "test"
os.environ["LLM_PROVIDER"] = "gpt"
os.environ["OPENAI_API_KEY"] = "mock_key_for_testing"

from fastapi.testclient import TestClient
from app.main import app

@pytest.fixture
def client():
    """Provides a synchronous TestClient wrapper around the FastAPI application."""
    with TestClient(app) as test_client:
        yield test_client

@pytest.fixture
def patient_warfarin_ibuprofen():
    """Geriatric patient taking Warfarin, prescribed Ibuprofen (high drug interaction and renal risk)."""
    return {
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

@pytest.fixture
def patient_penicillin_amoxicillin():
    """Patient with Penicillin allergy prescribed Amoxicillin (extreme cross-reactive allergy risk)."""
    return {
        "patient_id": "PT456",
        "age": 30,
        "gender": "Female",
        "weight": 60.0,
        "allergies": ["Penicillin"],
        "diseases": ["Hypertension"],
        "current_medications": ["Lisinopril"],
        "previous_prescriptions": [],
        "new_prescription": ["Amoxicillin"]
    }

@pytest.fixture
def patient_pregnant_warfarin():
    """Pregnant patient prescribed Warfarin (extreme pregnancy category X risk)."""
    return {
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

@pytest.fixture
def patient_safe_aspirin():
    """Younger adult patient with no contraindications, prescribed Aspirin (should be safe)."""
    return {
        "patient_id": "PT999",
        "age": 40,
        "gender": "Male",
        "weight": 80.0,
        "allergies": [],
        "diseases": ["Hypertension"],
        "current_medications": ["Lisinopril"],
        "previous_prescriptions": [],
        "new_prescription": ["Aspirin"]
    }
