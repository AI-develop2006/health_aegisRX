import logging
logger = logging.getLogger("patient_context")
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

import re
from app.db import patients_col, prescriptions_col, allergies_col

def parse_duration_days(duration_str: str) -> int:
    if not duration_str:
        return 30
    try:
        # Extract digits from duration string
        digits = "".join([c for c in str(duration_str) if c.isdigit()])
        if digits:
            val = int(digits)
            if "week" in duration_str.lower():
                return val * 7
            elif "month" in duration_str.lower():
                return val * 30
            return val
    except Exception:
        pass
    return 30

async def build_patient_context(request) -> PatientContext:
    patient_id = request.patient_id
    disease = request.disease
    new_medicine = request.new_medicine

    allergies = []
    current_meds = []

    try:
        logger.info(f"[DEBUG CDSS] build_patient_context called for patient_id: '{patient_id}', DB collections count: patients={patients_col().count_documents({})}, allergies={allergies_col().count_documents({})}")
        import re
        clean_id = patient_id.replace("_", " ").strip()
        escaped_id = re.escape(clean_id).replace(r"\ ", r"[\ _]")
        regex_pattern = f"^{escaped_id}$"
        
        patient_doc = patients_col().find_one({"patient_id": {"$regex": regex_pattern, "$options": "i"}})
        if not patient_doc:
            patient_doc = patients_col().find_one({"name": {"$regex": regex_pattern, "$options": "i"}})
        if not patient_doc:
            patient_doc = patients_col().find_one({"email": {"$regex": f"^{re.escape(patient_id)}$", "$options": "i"}})

        logger.info(f"[DEBUG CDSS] patient_doc found: {patient_doc}")

        if patient_doc:
            p_id = patient_doc.get("patient_id")
            p_name = patient_doc.get("name")
            
            # Fetch from allergies collection
            search_terms = []
            if p_id:
                search_terms.append(p_id)
                search_terms.append(p_id.replace("_", " "))
                search_terms.append(p_id.replace(" ", "_"))
            if p_name:
                search_terms.append(p_name)
                search_terms.append(p_name.replace("_", " "))
                search_terms.append(p_name.replace(" ", "_"))
            
            logger.info(f"[DEBUG CDSS] allergy search_terms: {search_terms}")
            allergy_filters = []
            for term in list(set(search_terms)):
                safe_term = re.escape(term)
                allergy_filters.append({"patient_id": {"$regex": f"^({safe_term})$", "$options": "i"}})
                allergy_filters.append({"patient_name": {"$regex": f"^({safe_term})$", "$options": "i"}})
                
            if allergy_filters:
                cursor = allergies_col().find({"$or": allergy_filters})
                allergies = [doc.get("allergy_name") for doc in cursor if doc.get("allergy_name")]
                logger.info(f"[DEBUG CDSS] fetched allergies from DB: {allergies}")
                
            # Also fallback to doc fields
            patient_allergies_field = patient_doc.get("allergies", [])
            if patient_allergies_field:
                allergies.extend(patient_allergies_field)
                
            allergies = list(set(allergies))
            logger.info(f"[DEBUG CDSS] final allergies list: {allergies}")

        # Fetch active prescriptions to extract current meds (within dynamic duration window)
        from datetime import datetime
        now = datetime.now()
        
        rx_query_terms = [patient_id]
        rx_query_terms.append(patient_id.replace("_", " "))
        rx_query_terms.append(patient_id.replace(" ", "_"))
        if patient_doc:
            p_id = patient_doc.get("patient_id")
            p_name = patient_doc.get("name")
            if p_id:
                rx_query_terms.append(p_id)
                rx_query_terms.append(p_id.replace("_", " "))
                rx_query_terms.append(p_id.replace(" ", "_"))
            if p_name:
                rx_query_terms.append(p_name)
                rx_query_terms.append(p_name.replace("_", " "))
                rx_query_terms.append(p_name.replace(" ", "_"))

        rx_query_terms = list(set(rx_query_terms))
        
        rx_filters = []
        for q_term in rx_query_terms:
            safe_term = re.escape(q_term)
            rx_filters.append({"patient_id": {"$regex": f"^({safe_term})$", "$options": "i"}})
            rx_filters.append({"patientName": {"$regex": f"^({safe_term})$", "$options": "i"}})
            rx_filters.append({"patient_name": {"$regex": f"^({safe_term})$", "$options": "i"}})
            
        active_rxs = prescriptions_col().find({"$and": [
            {"$or": rx_filters},
            {"isDispensed": False}
        ]})
        for rx in active_rxs:
            rx_date = rx.get("date")
            if rx_date:
                if isinstance(rx_date, str):
                    try:
                        date_clean = rx_date.split("+")[0]
                        rx_date = datetime.fromisoformat(date_clean)
                    except Exception:
                        pass
            
            for med in rx.get("medicines", []):
                name = med.get("name")
                if name:
                    is_active = True
                    if rx_date and isinstance(rx_date, datetime):
                        diff_days = abs((now - rx_date).days)
                        dur_str = med.get("duration", "30 days")
                        dur_days = parse_duration_days(dur_str)
                        if diff_days > dur_days:
                            is_active = False
                    
                    if is_active:
                        current_meds.append(name)

        # Fetch ALL prescriptions written by doctors for this patient (database history)
        from datetime import datetime
        all_rxs_cursor = prescriptions_col().find({"patientName": patient_id})
        all_prescriptions = []
        for rx in all_rxs_cursor:
            rx_clean = rx.copy()
            if "_id" in rx_clean:
                rx_clean["_id"] = str(rx_clean["_id"])
            if "date" in rx_clean:
                if isinstance(rx_clean["date"], datetime):
                    rx_clean["date"] = rx_clean["date"].isoformat()
                else:
                    rx_clean["date"] = str(rx_clean["date"])
            all_prescriptions.append(rx_clean)
    except Exception as e:
        all_prescriptions = []

    # Parse multiple new medicines separated by commas or semicolons
    new_meds = []
    if new_medicine:
        new_meds = [m.strip() for m in re.split(r'[,;]', new_medicine) if m.strip()]
    if not new_meds and new_medicine:
        new_meds = [new_medicine.strip()]
    elif not new_meds:
        new_meds = ["Unknown"]

    # Build patient context
    context = PatientContext(
        patient_id=patient_id,
        age=35,  # Fallback age
        gender="Male",  # Fallback gender
        allergies=allergies,
        diseases=[disease] if disease else [],
        current_medications=list(set(current_meds)),
        new_prescription=new_meds,
        all_prescriptions=all_prescriptions,
        doctor_id=getattr(request, "doctor_id", None)
    )
    return PatientContextService.preprocess_context(context)

