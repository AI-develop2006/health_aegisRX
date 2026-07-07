import asyncio
from fastapi import FastAPI, HTTPException, Request, Response
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import uvicorn
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("MockVerificationServer")

app = FastAPI(
    title="Mock Verification Server",
    description="Centralized local mock server simulating multi-step third-party verification flows.",
    version="1.0.0"
)

class InitiateRequest(BaseModel):
    payload: str

class ConfirmRequest(BaseModel):
    reference_token: str
    code: str

@app.post("/api/verify/initiate")
async def initiate_verification(data: InitiateRequest):
    logger.info(f"Received verification initiate request: {data.payload}")
    val = data.payload.strip()

    if val == "payload_a":
        # Case A: Happy path Success
        return {"reference_token": "token_a_success"}
    elif val == "payload_b":
        # Case B: Unprocessable Entity / Validation Error
        return {"reference_token": "token_b_validation_error"}
    elif val == "payload_c":
        # Case C: Gateway Timeout simulation
        return {"reference_token": "token_c_timeout"}
    else:
        # Generic fallback
        return {"reference_token": f"token_generic_{val}"}

@app.post("/api/verify/confirm")
async def confirm_verification(data: ConfirmRequest):
    logger.info(f"Received confirmation request. Token: {data.reference_token}, Code: {data.code}")
    token = data.reference_token.strip()

    if token == "token_a_success":
        if data.code == "123456":
            return {"status": "success", "message": "Verification completed successfully"}
        else:
            raise HTTPException(status_code=400, detail="Invalid OTP code. Please enter 123456.")
            
    elif token == "token_b_validation_error":
        # Returns a 422 Unprocessable Entity
        return JSONResponse(
            status_code=422,
            content={
                "detail": [
                    {
                        "loc": ["body", "payload"],
                        "msg": "Validation failed: Invalid formatting rules or constraint mismatch.",
                        "type": "value_error"
                    }
                ]
            }
        )
        
    elif token == "token_c_timeout":
        # Forces a 500 / timeout behavior (sleeps for 6.0 seconds)
        logger.info("Simulating server timeout (sleeping for 6 seconds)...")
        await asyncio.sleep(6.0)
        raise HTTPException(status_code=500, detail="Gateway timeout: Simulated backend failure.")
        
    else:
        # Default behavior
        if data.code == "123456":
            return {"status": "success", "message": "Verification completed successfully"}
        raise HTTPException(status_code=400, detail="Verification code mismatch")

@app.get("/health")
async def health():
    return {"status": "online", "service": "mock-verification-server"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=4008)
