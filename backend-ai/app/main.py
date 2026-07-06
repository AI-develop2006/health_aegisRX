"""
AegisRx / HealthLock — Modular FastAPI Application
====================================================
Entry point: uvicorn app.main:app --reload
"""
import os
import re
from contextlib import asynccontextmanager
from datetime import datetime
from typing import Optional

import uvicorn
from fastapi import FastAPI, HTTPException, Query, Header, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse

from app.config import logger, COLLECTION_PRESCRIPTIONS
from app.db.mongodb import MongoDBConnector, set_connector, get_connector
from app.services import ledger_service, ai_service
from app.services.ledger_service import BlockchainManager, set_blockchain_manager, get_blockchain_manager
from app.services.auth_service import require_patient_session

# ============================================
# LIFESPAN (startup / shutdown)
# ============================================
@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Handles startup and shutdown lifespan events.
    Initialises MongoDB, AIAgent, and BlockchainManager on boot.
    """
    logger.info("AegisRx backend — startup lifespan beginning…")
    try:
        # 1. Connect to MongoDB
        db = MongoDBConnector()
        set_connector(db)
        logger.info("MongoDB connected.")

        # 2. Init BlockchainManager
        bm = BlockchainManager(db.db)
        set_blockchain_manager(bm)
        logger.info("BlockchainManager initialized.")
        # 3. Note: Legacy AIAgent initialization removed in favor of the new Multi-Agent AI system


        # 4. Seed prescriptions collection if empty
        prescriptions_col = db.get_prescriptions_collection()
        if prescriptions_col.count_documents({}) == 0:
            logger.info("Prescriptions collection empty — seeding mock data…")
            _seed_prescriptions(db)

    except Exception as e:
        logger.error(f"Startup failure: {e}. Running in degraded mode.")

    yield  # app is running

    # Shutdown
    try:
        connector = get_connector()
        if connector:
            connector.close()
    except Exception:
        pass
    logger.info("AegisRx backend — shutdown complete.")



def _seed_prescriptions(db: MongoDBConnector):
    """Seed the prescriptions collection with demo data from prescriptions_db.json."""
    import json, pathlib
    db_file = pathlib.Path(__file__).parent.parent / "prescriptions_db.json"
    if not db_file.exists():
        logger.warning("prescriptions_db.json not found — skipping seed.")
        return
    try:
        with open(db_file) as f:
            mock_list = json.load(f)
        col = db.get_prescriptions_collection()
        for rx in mock_list:
            rx_mongo = rx.copy()
            if "date" in rx_mongo and isinstance(rx_mongo["date"], str):
                try:
                    rx_mongo["date"] = datetime.fromisoformat(rx_mongo["date"])
                except Exception:
                    pass
            col.insert_one(rx_mongo)
        logger.info(f"Seeded {len(mock_list)} prescriptions.")
    except Exception as e:
        logger.error(f"Seeding failed: {e}")


# ============================================
# FASTAPI APP
# ============================================
app = FastAPI(
    title="AegisRx / HealthLock — Healthcare AI Backend",
    description=(
        "Modular FastAPI backend for AegisRx / HealthLock. "
        "Exposes clinical AI audit, prescription management, consultation consent flow, "
        "pharmacy verification, and a hash-linked blockchain ledger."
    ),
    version="2.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

# ---- CORS ----
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================================
# REGISTER ROUTERS
# ============================================
from app.routes import auth, patient, consultation, doctor, pharmacy

app.include_router(auth.router)
app.include_router(patient.router)
app.include_router(consultation.router)
app.include_router(doctor.router)       # prescriptions + audit + doctor reads
app.include_router(pharmacy.router)     # verify-scan + dispense


# ============================================
# HEALTH CHECK
# ============================================
@app.get("/health", tags=["General"])
async def health_check():
    """Health check endpoint — confirms API is running."""
    return {
        "status": "healthy",
        "api_name": "AegisRx Healthcare AI Backend",
        "version": "2.0.0",
        "docs_url": "/docs",
    }


@app.get("/", tags=["General"])
async def root():
    """API root — returns metadata."""
    return {
        "status": "online",
        "api_name": "AegisRx Healthcare AI Backend",
        "version": "2.0.0",
        "docs_url": "/docs",
        "redoc_url": "/redoc",
    }


# ============================================
# BLOCKCHAIN ENDPOINTS (kept in main for global bm access)
# ============================================
async def _get_patient_caller(x_session_token: str = Header(..., alias="X-Session-Token")) -> dict:
    db = get_connector()
    return await require_patient_session(db, x_session_token)


@app.get("/api/blockchain/chain", tags=["Blockchain"])
async def get_blockchain(caller: dict = Depends(_get_patient_caller)):
    """Return blockchain blocks scoped to the authenticated patient."""
    bm = get_blockchain_manager()
    if not bm:
        raise HTTPException(status_code=503, detail="Blockchain not available")
    patient_name = caller["name"].lower()
    all_blocks = bm.get_chain()
    visible = [b for b in all_blocks if
               b.get("block_type") == "GENESIS" or
               b.get("data", {}).get("patient_name", "").lower() == patient_name]
    return {"chain": visible, "length": len(visible)}


@app.get("/api/blockchain/verify", tags=["Blockchain"])
async def verify_blockchain():
    """Verify full chain integrity — no PHI exposed."""
    bm = get_blockchain_manager()
    if not bm:
        raise HTTPException(status_code=503, detail="Blockchain not available")
    return bm.verify_chain()


@app.post("/api/blockchain/heal", tags=["Blockchain"])
async def heal_blockchain():
    """Repair broken links/hashes in the blockchain ledger."""
    bm = get_blockchain_manager()
    if not bm:
        raise HTTPException(status_code=503, detail="Blockchain not available")
    return bm.heal_chain_integrity()


@app.get("/api/blockchain/blocks", tags=["Blockchain"])
async def get_blocks_by_type(
    block_type: str = Query(..., description="GENESIS | ACCESS_GRANT | ACCESS_REVOKE | PRESCRIPTION | VISIT_HISTORY"),
    caller: dict = Depends(_get_patient_caller),
):
    """Filter chain blocks by type, scoped to the authenticated patient."""
    bm = get_blockchain_manager()
    if not bm:
        raise HTTPException(status_code=503, detail="Blockchain not available")
    patient_name = caller["name"].lower()
    all_blocks = bm.get_blocks_by_type(block_type)
    visible = all_blocks if block_type == "GENESIS" else [
        b for b in all_blocks if b.get("data", {}).get("patient_name", "").lower() == patient_name
    ]
    return {"blocks": visible}


@app.get("/api/access/status", tags=["Blockchain"])
async def check_doctor_access(doctor_id: str = Query(...), patient_name: str = Query(...)):
    """Check whether a doctor currently has an active ACCESS_GRANT for a patient."""
    bm = get_blockchain_manager()
    if not bm:
        raise HTTPException(status_code=503, detail="Blockchain not available")
    has_access = bm.has_doctor_access(doctor_id, patient_name)
    return {"doctor_id": doctor_id, "patient_name": patient_name, "access_granted": has_access}


@app.get("/api/visit-history/{patient_name}", tags=["Blockchain"])
async def get_visit_history(patient_name: str, caller: dict = Depends(_get_patient_caller)):
    """Return VISIT_HISTORY blocks for the authenticated patient."""
    if caller["name"].lower() != patient_name.lower():
        raise HTTPException(status_code=403, detail="Access denied: you can only view your own visit history")
    bm = get_blockchain_manager()
    if not bm:
        db = get_connector()
        safe = re.escape(patient_name)
        rxs = list(db.get_prescriptions_collection().find(
            {"patientName": {"$regex": f"^{safe}$", "$options": "i"}},
            sort=[("date", -1)]
        ))
        return {"visits": [_serialize_doc(r) for r in rxs], "source": "prescriptions_fallback"}
    visits = bm.get_visit_history(patient_name)
    return {"visits": visits, "source": "blockchain", "total": len(visits)}


# ============================================
# ACTIVITY LOGS
# ============================================
@app.get("/api/activity-logs", tags=["Ledger Logs"])
async def get_activity_logs():
    db = get_connector()
    return ledger_service.get_activity_logs(db)

# ============================================
# HELPERS
# ============================================
def _serialize_doc(doc: dict | None) -> dict | None:
    if doc is None:
        return None
    doc_copy = dict(doc)
    doc_copy.pop("_id", None)
    for key, value in doc_copy.items():
        if isinstance(value, datetime):
            doc_copy[key] = (
                value.strftime("%Y-%m-%d") if (value.hour == 0 and value.minute == 0)
                else (value.isoformat() + ("Z" if value.tzinfo is None else ""))
            )
        elif isinstance(value, list):
            doc_copy[key] = [_serialize_doc(i) if isinstance(i, dict) else i for i in value]
    return doc_copy


# ============================================
# LOCAL DEV ENTRY POINT
# ============================================
if __name__ == "__main__":
    logger.info("Starting AegisRx local development server on port 4000…")
    uvicorn.run("app.main:app", host="0.0.0.0", port=4000, reload=True)
