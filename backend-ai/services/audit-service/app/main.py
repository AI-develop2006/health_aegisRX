from fastapi import FastAPI
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("audit-service")

app = FastAPI(
    title="AegisRx Audit Service",
    description="Microservice handling Audit Service logic",
    version="1.0.0"
)

@app.get("/health", tags=["General"])
async def health():
    return {"status": "online", "service": "audit-service"}

@app.get("/", tags=["General"])
async def root():
    return {"status": "online", "service": "audit-service"}
