from typing import List, Dict, Any, Optional
from pydantic import BaseModel, Field
from uuid import UUID

class DrugInteractionDetail(BaseModel):
    severity: str = Field(..., description="Interaction severity: MAJOR, MODERATE, or MINOR")
    drugs: List[str] = Field(..., description="List of drugs involved in the interaction")
    description: str = Field(..., description="Clinical description of the interaction")
    reason: Optional[str] = Field(None, description="Explaining why interaction flagged")

class AllergyRiskDetail(BaseModel):
    allergy: str = Field(..., description="The patient's allergen")
    drug: str = Field(..., description="The prescribed drug causing conflict")
    description: str = Field(..., description="Allergy conflict details")
    reason: Optional[str] = Field(None, description="Explaining why allergy triggered")

class DiseaseContraindicationDetail(BaseModel):
    disease: str = Field(..., description="Patient disease contraindicated with the drug")
    drug: str = Field(..., description="The contraindicated drug")
    description: str = Field(..., description="Contraindication reasoning")
    reason: Optional[str] = Field(None, description="Explaining why disease flag raised")

class PrescriptionSafetyAnalysis(BaseModel):
    analysis_id: UUID = Field(..., description="Unique ID for this analysis run")
    risk_level: str = Field(..., description="Risk level: SAFE, WARNING, or HIGH_RISK")
    confidence_score: float = Field(..., description="Confidence score from 0.0 to 1.0")
    reasons: List[str] = Field(..., description="High-level reasons for safety rating")
    detected_drug_interactions: List[DrugInteractionDetail] = Field(default_factory=list)
    detected_allergy_risks: List[AllergyRiskDetail] = Field(default_factory=list)
    disease_contraindications: List[DiseaseContraindicationDetail] = Field(default_factory=list)
    suggested_alternative_medicines: List[str] = Field(default_factory=list)
    clinical_explanation: str = Field(..., description="Detailed clinical reasoning summary")
    recommended_action: str = Field(..., description="Action recommendation: SAFE_TO_DISPENSE, DOCTOR_REVIEW, DO_NOT_DISPENSE, or CONTACT_DOCTOR_IMMEDIATELY")
    metadata: Dict[str, Any] = Field(default_factory=dict, description="Metadata like token usage and latency")
    
    # Standardized RiskSnapshot contract fields
    risk_band: str = Field("LOW", description="LOW, MEDIUM, HIGH, CRITICAL")
    risk_score: int = Field(0, description="Risk score from 0 to 100")
    recommendation: str = Field("", description="Short summary recommendation text")
    flagged_medicines: List[str] = Field(default_factory=list, description="Medicines flagged during audit")
    backend_mode: str = Field("mock", description="'real' or 'mock'")
    backend_reason: Optional[str] = Field(None, description="Detailed explanation of fallback reasons if any")

class AuditLogEntry(BaseModel):
    analysis_id: UUID
    timestamp: str
    patient_context: Dict[str, Any]
    analysis_result: PrescriptionSafetyAnalysis
    raw_prompt_system: str
    raw_prompt_user: str
    raw_llm_response: str
    latency_ms: float
    token_usage: Dict[str, Any]

class AuditRequest(BaseModel):
    analysis_id: Optional[UUID] = None

class AuditResponse(BaseModel):
    risk_band: str
    risk_score: int
    override_required: bool
    flagged_medicines: List[Dict[str, Any]]
    explanation: str
    alternatives: List[str]
    action: Optional[str] = "ALLOW"
    block_submission: Optional[bool] = False
    warnings: List[str] = Field(default_factory=list)
    alternative_medicines: List[str] = Field(default_factory=list)
    recommended_action: Optional[str] = "ALLOW"

    # Backward compatibility fields for legacy clients / Flutter app
    risk_level: Optional[str] = "SAFE"
    confidence_score: Optional[float] = 0.90
    clinical_explanation: Optional[str] = ""
    allergy_check: Optional[Dict[str, Any]] = None
    interaction_check: Optional[Dict[str, Any]] = None
    duplicate_check: Optional[Dict[str, Any]] = None

