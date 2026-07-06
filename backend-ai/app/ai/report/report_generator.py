from app.schemas.response import PrescriptionSafetyAnalysis

class ReportGenerator:
    @staticmethod
    def generate_report(analysis: PrescriptionSafetyAnalysis) -> PrescriptionSafetyAnalysis:
        """
        Takes the raw clinical safety analysis and formats or enriches it
        into a clean, standardized report for the physician or pharmacist.
        Appends mandatory medical decision support disclaimers.
        """
        # Append standard CDSS medical disclaimer
        disclaimer = (
            "\n\n[DISCLAIMER: AegisRx AI Sentinel is an AI-driven Clinical Decision Support System. "
            "It provides safety warnings and recommendations based on clinical databases and heuristics, "
            "but does not make final clinical decisions. The dispensing pharmacist and prescribing "
            "physician maintain sole responsibility for the patient's medical treatment.]"
        )
        
        if disclaimer not in analysis.clinical_explanation:
            analysis.clinical_explanation += disclaimer

        # Enforce uppercase standard for categorical fields
        analysis.risk_level = analysis.risk_level.upper()
        analysis.recommended_action = analysis.recommended_action.upper()
        
        # De-duplicate suggested alternatives
        analysis.suggested_alternative_medicines = list(
            set(analysis.suggested_alternative_medicines)
        )

        return analysis
