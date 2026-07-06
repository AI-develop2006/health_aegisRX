"""AegisRx Ledger Service — Port 4007 — SELF-CONTAINED"""
from contextlib import asynccontextmanager
from datetime import datetime
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.blockchain import init_blockchain_manager
from app.router import router
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("ledger-service")


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Ledger Service startup…")
    try:
        init_blockchain_manager()
    except Exception as e:
        logger.error(f"Ledger startup error: {e}")
    yield
    logger.info("Ledger Service shutdown.")


app = FastAPI(
    title="AegisRx Ledger Service",
    description="Hash-linked blockchain ledger — self-contained microservice",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
)

app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True,
                   allow_methods=["*"], allow_headers=["*"])
app.include_router(router)


@app.get("/health", tags=["General"])
async def health():
    return {"status": "online", "service": "ledger-service", "port": 4007,
            "timestamp": datetime.utcnow().isoformat() + "Z"}

@app.get("/", tags=["General"])
async def root():
    return {"status": "online", "service": "ledger-service"}
