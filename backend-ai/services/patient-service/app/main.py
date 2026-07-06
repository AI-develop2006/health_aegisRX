from fastapi import FastAPI
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("patient-service")

app = FastAPI(
    title="AegisRx Patient Service",
    description="Microservice handling Patient Service logic",
    version="1.0.0"
)

@app.get("/health", tags=["General"])
async def health():
    return {"status": "online", "service": "patient-service"}

@app.get("/", tags=["General"])
async def root():
    return {"status": "online", "service": "patient-service"}
