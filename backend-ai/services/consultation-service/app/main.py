from fastapi import FastAPI
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("consultation-service")

app = FastAPI(
    title="AegisRx Consultation Service",
    description="Microservice handling Consultation Service logic",
    version="1.0.0"
)

@app.get("/health", tags=["General"])
async def health():
    return {"status": "online", "service": "consultation-service"}

@app.get("/", tags=["General"])
async def root():
    return {"status": "online", "service": "consultation-service"}
