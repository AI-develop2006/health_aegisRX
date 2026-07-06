import pytest
from app.schemas.patient import PatientContext
from app.ai.knowledge import RxNormMock, DrugBankMock, DailyMedMock, OpenFDAMock, SNOMEDMock
from app.ai.agents import (
    InteractionAgent, 
    AllergyAgent, 
    DiseaseAgent, 
    DosageAgent, 
    RecommendationAgent
)

@pytest.fixture
def mock_knowledge_services():
    """Returns initialized mock knowledge services."""
    return (
        RxNormMock(),
        DrugBankMock(),
        DailyMedMock(),
        OpenFDAMock(),
        SNOMEDMock()
    )

@pytest.mark.asyncio
async def test_interaction_agent_major(patient_warfarin_ibuprofen, mock_knowledge_services):
    """Verify that InteractionAgent catches duplicate classes and major interactions."""
    rxnorm, drugbank, dailymed, openfda, snomed = mock_knowledge_services
    agent = InteractionAgent(rxnorm, drugbank, dailymed, openfda, snomed)
    patient = PatientContext(**patient_warfarin_ibuprofen)
    
    results = await agent.analyze(patient)
    
    assert results["has_issues"] is True
    assert len(results["drug_interactions"]) > 0
    # Ibuprofen and Warfarin
    assert any("warfarin" in i["drugs"][0].lower() or "warfarin" in i["drugs"][1].lower() for i in results["drug_interactions"])
    assert any("ibuprofen" in i["drugs"][0].lower() or "ibuprofen" in i["drugs"][1].lower() for i in results["drug_interactions"])

@pytest.mark.asyncio
async def test_allergy_agent_penicillin(patient_penicillin_amoxicillin, mock_knowledge_services):
    """Verify that AllergyAgent catches drug-allergy cross-reactivity."""
    rxnorm, drugbank, dailymed, openfda, snomed = mock_knowledge_services
    agent = AllergyAgent(rxnorm, drugbank, dailymed, openfda, snomed)
    patient = PatientContext(**patient_penicillin_amoxicillin)
    
    results = await agent.analyze(patient)
    
    assert results["has_issues"] is True
    assert len(results["allergy_conflicts"]) == 1
    conflict = results["allergy_conflicts"][0]
    assert conflict["allergy"] == "Penicillin"
    assert conflict["drug"] == "Amoxicillin"
    assert "class-based" in conflict["description"].lower()

@pytest.mark.asyncio
async def test_disease_agent_ckd_ibuprofen(patient_warfarin_ibuprofen, mock_knowledge_services):
    """Verify that DiseaseAgent catches kidney contraindications with NSAIDs."""
    rxnorm, drugbank, dailymed, openfda, snomed = mock_knowledge_services
    agent = DiseaseAgent(rxnorm, drugbank, dailymed, openfda, snomed)
    patient = PatientContext(**patient_warfarin_ibuprofen)
    
    results = await agent.analyze(patient)
    
    assert results["has_issues"] is True
    assert len(results["disease_contraindications"]) > 0
    contra = results["disease_contraindications"][0]
    assert contra["disease"] == "Chronic Kidney Disease"
    assert contra["drug"] == "Ibuprofen"

@pytest.mark.asyncio
async def test_dosage_agent_pregnancy_and_age(patient_pregnant_warfarin, patient_warfarin_ibuprofen, mock_knowledge_services):
    """Verify that DosageAgent catches pregnancy categories and Beers criteria."""
    rxnorm, drugbank, dailymed, openfda, snomed = mock_knowledge_services
    agent = DosageAgent(rxnorm, drugbank, dailymed, openfda, snomed)
    
    # Test Pregnancy category X (Warfarin)
    patient_preg = PatientContext(**patient_pregnant_warfarin)
    preg_results = await agent.analyze(patient_preg)
    assert preg_results["has_high_risk"] is True
    assert any(w["type"] == "PREGNANCY_RISK" and w["severity"] == "HIGH_RISK" for w in preg_results["dosage_and_demographic_warnings"])

    # Test Beers Criteria for elderly patient (65+ and Ibuprofen)
    patient_ger = PatientContext(**patient_warfarin_ibuprofen)
    ger_results = await agent.analyze(patient_ger)
    assert ger_results["has_issues"] is True
    assert any(w["type"] == "GERIATRIC_RISK" for w in ger_results["dosage_and_demographic_warnings"])

def test_recommendation_agent_compilation(mock_knowledge_services):
    """Verify that RecommendationAgent correctly compiles sub-agent analysis into overrides and suggestions."""
    rxnorm, drugbank, dailymed, openfda, snomed = mock_knowledge_services
    agent = RecommendationAgent(rxnorm, drugbank, dailymed, openfda, snomed)
    
    # Setup mock agent outputs
    interaction_res = {
        "drug_interactions": [{"severity": "MAJOR", "drugs": ["Warfarin", "Ibuprofen"], "description": "Major interaction."}],
        "duplicate_detections": [],
        "has_issues": True
    }
    allergy_res = {"allergy_conflicts": [], "has_issues": False}
    disease_res = {
        "disease_contraindications": [{"disease": "Chronic Kidney Disease", "drug": "Ibuprofen", "description": "CKD contraindication."}],
        "has_issues": True
    }
    dosage_res = {
        "dosage_and_demographic_warnings": [],
        "has_high_risk": False,
        "has_issues": False
    }

    overrides = agent.compile_clinical_overrides(interaction_res, allergy_res, disease_res, dosage_res)
    
    assert overrides["risk_level"] == "HIGH_RISK"
    assert overrides["recommended_action"] == "DO_NOT_DISPENSE"
    assert "Acetaminophen" in overrides["suggested_alternative_medicines"]
    assert len(overrides["reasons"]) == 2
