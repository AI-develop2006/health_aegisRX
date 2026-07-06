from fastapi import FastAPI
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("pharmacy-service")

app = FastAPI(
    title="AegisRx Pharmacy Service",
    description="Microservice handling Pharmacy Service logic",
    version="1.0.0"
)

@app.get("/health", tags=["General"])
async def health():
    return {"status": "online", "service": "pharmacy-service"}

@app.get("/", tags=["General"])
async def root():
    return {"status": "online", "service": "pharmacy-service"}
