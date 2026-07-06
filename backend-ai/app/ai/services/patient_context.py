from app.schemas.patient import PatientContext

class PatientContextService:
    @staticmethod
    def preprocess_context(patient: PatientContext) -> PatientContext:
        """
        Cleans and normalizes strings in the PatientContext object,
        stripping unnecessary whitespaces and standardizing casing.
        """
        # Normalize allergies list
        patient.allergies = [
            a.strip().title() for a in patient.allergies if a.strip()
        ]
        
        # Normalize diseases list (standardize casing, retaining capitalization for abbreviations like CKD)
        patient.diseases = [
            d.strip().title() if len(d.strip()) > 3 else d.strip().upper()
            for d in patient.diseases if d.strip()
        ]
        
        # Normalize medications lists
        patient.current_medications = [
            m.strip().title() for m in patient.current_medications if m.strip()
        ]
        patient.previous_prescriptions = [
            p.strip().title() for p in patient.previous_prescriptions if p.strip()
        ]
        patient.new_prescription = [
            n.strip().title() for n in patient.new_prescription if n.strip()
        ]
        
        return patient
