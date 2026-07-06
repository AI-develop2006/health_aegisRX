from fastapi import FastAPI
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("prescription-service")

app = FastAPI(
    title="AegisRx Prescription Service",
    description="Microservice handling Prescription Service logic",
    version="1.0.0"
)

@app.get("/health", tags=["General"])
async def health():
    return {"status": "online", "service": "prescription-service"}

@app.get("/", tags=["General"])
async def root():
    return {"status": "online", "service": "prescription-service"}
