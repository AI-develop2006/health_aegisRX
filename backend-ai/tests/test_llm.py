import pytest
from app.ai.llm import GPTClient, MedGemmaClient, BaseLLM
from app.core.config import settings

def test_llm_client_inheritance():
    """Verify that both clients implement the BaseLLM abstract interface."""
    gpt = GPTClient()
    medgemma = MedGemmaClient()
    
    assert isinstance(gpt, BaseLLM)
    assert isinstance(medgemma, BaseLLM)

@pytest.mark.asyncio
async def test_gpt_client_mock_fallback():
    """Verify that GPTClient enters fallback mode when the API key is mock and generates valid JSON."""
    gpt = GPTClient()
    # Confirm it's using the mock client since conftest sets mock API key
    assert gpt.client is None
    
    user_prompt = "Patient has chronic kidney disease and was prescribed Ibuprofen"
    response = await gpt.generate_response("System prompt", user_prompt)
    
    assert isinstance(response, str)
    # Check that it returns structured JSON representing high risk
    assert "risk_level" in response
    assert "HIGH_RISK" in response
    assert "disease_contraindications" in response

@pytest.mark.asyncio
async def test_medgemma_client_mock_fallback():
    """Verify that MedGemmaClient behaves correctly in fallback/testing mode."""
    medgemma = MedGemmaClient()
    user_prompt = "Patient has penicillin allergy and is prescribed Amoxicillin"
    
    response = await medgemma.generate_response("System prompt", user_prompt)
    
    assert isinstance(response, str)
    assert "risk_level" in response
    assert "Amoxicillin" in response
    assert "[MedGemma Clinical Inference]" in response
