import os
from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
import httpx
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("Gateway")

app = FastAPI(
    title="AegisRx API Gateway",
    description="Unified entry point routing downstream to microservices",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Service URLs (configured via env or Docker compose hostnames)
SERVICES = {
    "auth": os.getenv("AUTH_SERVICE_URL", "http://auth-service:4001"),
    "patient": os.getenv("PATIENT_SERVICE_URL", "http://patient-service:4002"),
    "consultation": os.getenv("CONSULTATION_SERVICE_URL", "http://consultation-service:4003"),
    "prescription": os.getenv("PRESCRIPTION_SERVICE_URL", "http://prescription-service:4004"),
    "audit": os.getenv("AUDIT_SERVICE_URL", "http://audit-service:4005"),
    "pharmacy": os.getenv("PHARMACY_SERVICE_URL", "http://pharmacy-service:4006"),
    "ledger": os.getenv("LEDGER_SERVICE_URL", "http://ledger-service:4007"),
}


async def forward_request(service_name: str, path: str, request: Request) -> Response:
    """Helper to forward HTTP requests downstream to respective service."""
    base_url = SERVICES.get(service_name)
    if not base_url:
        return Response(content="Service routing configuration missing", status_code=502)

    url = f"{base_url}/{path}"
    query_params = dict(request.query_params)
    headers = {k: v for k, v in request.headers.items() if k.lower() not in ("host", "content-length")}
    body = await request.body()

    logger.info(f"Gateway Routing: {request.method} {request.url.path} -> {url}")

    async with httpx.AsyncClient() as client:
        try:
            response = await client.request(
                method=request.method,
                url=url,
                params=query_params,
                headers=headers,
                content=body,
                timeout=10.0
            )
            return Response(
                content=response.content,
                status_code=response.status_code,
                headers=dict(response.headers)
            )
        except httpx.RequestError as exc:
            logger.error(f"Downstream connection failure: {exc}")
            return Response(content=f"Downstream service unavailable: {str(exc)}", status_code=503)


# Routing mapping paths
@app.api_route("/api/auth/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def route_auth(path: str, request: Request):
    return await forward_request("auth", f"api/{path}", request)


@app.api_route("/api/patient/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def route_patient(path: str, request: Request):
    return await forward_request("patient", f"api/patient/{path}", request)


@app.api_route("/api/consultation/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def route_consultation(path: str, request: Request):
    return await forward_request("consultation", f"api/consultation/{path}", request)


@app.api_route("/api/prescriptions/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def route_prescriptions(path: str, request: Request):
    return await forward_request("prescription", f"api/prescriptions/{path}", request)


@app.api_route("/api/audit", methods=["POST"])
@app.api_route("/api/duplicate-check", methods=["POST"])
@app.api_route("/api/interaction-check", methods=["POST"])
@app.api_route("/api/allergy-check", methods=["POST"])
@app.api_route("/api/recommendations", methods=["POST"])
async def route_clinical_ai(request: Request):
    path = request.url.path.lstrip("/")
    return await forward_request("audit", path, request)


@app.api_route("/api/doctor/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def route_doctor(path: str, request: Request):
    return await forward_request("prescription", f"api/doctor/{path}", request)


@app.api_route("/api/pharmacy/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def route_pharmacy(path: str, request: Request):
    return await forward_request("pharmacy", f"api/pharmacy/{path}", request)


@app.api_route("/api/blockchain/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def route_blockchain(path: str, request: Request):
    return await forward_request("ledger", f"api/blockchain/{path}", request)


@app.api_route("/api/access/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def route_access(path: str, request: Request):
    return await forward_request("ledger", f"api/access/{path}", request)


@app.api_route("/api/visit-history/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def route_visit_history(path: str, request: Request):
    return await forward_request("ledger", f"api/visit-history/{path}", request)


@app.api_route("/api/activity-logs", methods=["GET"])
async def route_activity_logs(request: Request):
    return await forward_request("ledger", "api/activity-logs", request)


@app.get("/health", tags=["General"])
async def health():
    return {"status": "online", "service": "gateway-service"}
