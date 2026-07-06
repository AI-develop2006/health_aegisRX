"""Patient Service — Business Logic"""
import re
import logging
from collections import Counter
from datetime import datetime

from app.db import prescriptions_col

logger = logging.getLogger("patient-service")


def _serialize(doc):
    if doc is None:
        return None
    d = dict(doc)
    d.pop("_id", None)
    for k, v in d.items():
        if isinstance(v, datetime):
            d[k] = v.strftime("%Y-%m-%d") if (v.hour == 0 and v.minute == 0) else v.isoformat() + "Z"
        elif isinstance(v, list):
            d[k] = [_serialize(i) if isinstance(i, dict) else i for i in v]
    return d


def get_prescriptions(patient_id: str) -> list:
    logger.info(f"Fetching prescriptions for: {patient_id}")
    safe = re.escape(patient_id)
    cur = prescriptions_col().find({
        "$or": [
            {"patientName": {"$regex": f"^{safe}$", "$options": "i"}},
            {"patient_id": {"$regex": f"^{safe}$", "$options": "i"}},
        ]
    })
    return [_serialize(doc) for doc in cur]


def get_dashboard(patient_id: str) -> dict:
    logger.info(f"Building dashboard for: {patient_id}")
    rxs = get_prescriptions(patient_id)
    total = len(rxs)
    dispensed = sum(1 for r in rxs if r.get("isDispensed", False))
    active = total - dispensed

    active_meds = []
    for rx in rxs:
        if not rx.get("isDispensed", False):
            for med in rx.get("medicines", []):
                n = med.get("name", "")
                if n:
                    active_meds.append(n)

    counts = Counter(m.split()[0].lower() for m in active_meds)
    flagged = [m for m, c in counts.items() if c > 1]
    display = rxs[0].get("patientName", patient_id) if rxs else patient_id

    return {
        "patient_id": patient_id,
        "patient_name": display,
        "total_prescriptions": total,
        "active_prescriptions": active,
        "dispensed_prescriptions": dispensed,
        "alert_level": "HIGH" if flagged else "LOW",
        "flagged_medicines": flagged,
    }
