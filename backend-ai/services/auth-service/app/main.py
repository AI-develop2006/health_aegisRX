from fastapi import FastAPI
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("auth-service")

app = FastAPI(
    title="AegisRx Auth Service",
    description="Microservice handling Auth Service logic",
    version="1.0.0"
)

@app.get("/health", tags=["General"])
async def health():
    return {"status": "online", "service": "auth-service"}

@app.get("/", tags=["General"])
async def root():
    return {"status": "online", "service": "auth-service"}
