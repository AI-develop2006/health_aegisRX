from fastapi import FastAPI
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("ledger-service")

app = FastAPI(
    title="AegisRx Ledger Service",
    description="Microservice handling Ledger Service logic",
    version="1.0.0"
)

@app.get("/health", tags=["General"])
async def health():
    return {"status": "online", "service": "ledger-service"}

@app.get("/", tags=["General"])
async def root():
    return {"status": "online", "service": "ledger-service"}
