"""
AegisRx Auth Service — Port 4001
SELF-CONTAINED: does NOT import from the shared monolith app/ package.
"""
from datetime import datetime
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.router import router

app = FastAPI(
    title="AegisRx Auth Service",
    description="Patient and doctor authentication — self-contained microservice",
    version="1.0.0",
    docs_url="/docs",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router)


@app.get("/health", tags=["General"])
async def health():
    return {
        "status": "online",
        "service": "auth-service",
        "port": 4001,
        "timestamp": datetime.utcnow().isoformat() + "Z",
    }

@app.get("/", tags=["General"])
async def root():
    return {"status": "online", "service": "auth-service"}
