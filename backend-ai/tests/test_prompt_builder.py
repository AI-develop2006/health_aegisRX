from app.ai.llm.prompt_builder import PromptBuilder
from app.schemas.patient import PatientContext

def test_build_system_prompt():
    """Verify that the system prompt specifies the clinical role and JSON instructions."""
    system_prompt = PromptBuilder.build_system_prompt()
    assert isinstance(system_prompt, str)
    assert "Board-Certified Clinical Pharmacist" in system_prompt
    assert "risk_level" in system_prompt
    assert "recommended_action" in system_prompt

def test_build_user_prompt(patient_warfarin_ibuprofen):
    """Verify that the user prompt incorporates patient demographics, rule alerts, and knowledge facts."""
    patient = PatientContext(**patient_warfarin_ibuprofen)
    agent_assertions = {
        "drug_interactions": [
            {
                "severity": "MAJOR",
                "drugs": ["Warfarin", "Ibuprofen"],
                "description": "Major interaction warning."
            }
        ]
    }
    knowledge_facts = [
        "DailyMed Ibuprofen pregnancy category: C.",
        "DrugBank Interaction between Warfarin and Ibuprofen: Major."
    ]

    user_prompt = PromptBuilder.build_user_prompt(patient, agent_assertions, knowledge_facts)
    
    assert isinstance(user_prompt, str)
    assert patient.patient_id in user_prompt
    assert "Warfarin" in user_prompt
    assert "Ibuprofen" in user_prompt
    assert "DailyMed Ibuprofen pregnancy category: C." in user_prompt
    assert "Major interaction warning." in user_prompt
