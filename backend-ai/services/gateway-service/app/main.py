"""
AegisRx API Gateway — Port 4000
Routes all incoming /api/* requests to the appropriate downstream microservice.
"""
import os
import uuid
from datetime import datetime
from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
import httpx
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("Gateway")

app = FastAPI(
    title="AegisRx API Gateway",
    description="Unified entry point routing to AegisRx microservices",
    version="1.0.0",
)

# ── CORS ────────────────────────────────────────────────────────────────────
CORS_ORIGINS = os.getenv("CORS_ORIGINS", "*").split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS if CORS_ORIGINS != ["*"] else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Downstream service registry ─────────────────────────────────────────────
SERVICES = {
    "auth":         os.getenv("AUTH_SERVICE_URL",         "http://127.0.0.1:4001"),
    "patient":      os.getenv("PATIENT_SERVICE_URL",      "http://127.0.0.1:4002"),
    "consultation": os.getenv("CONSULTATION_SERVICE_URL", "http://127.0.0.1:4003"),
    "prescription": os.getenv("PRESCRIPTION_SERVICE_URL", "http://127.0.0.1:4004"),
    "audit":        os.getenv("AUDIT_SERVICE_URL",        "http://127.0.0.1:4005"),
    "pharmacy":     os.getenv("PHARMACY_SERVICE_URL",     "http://127.0.0.1:4006"),
    "ledger":       os.getenv("LEDGER_SERVICE_URL",       "http://127.0.0.1:4007"),
}


# ── Forward helper ───────────────────────────────────────────────────────────
async def forward(service_name: str, downstream_path: str, request: Request) -> Response:
    base = SERVICES.get(service_name)
    if not base:
        return Response(content=f"Gateway: unknown service '{service_name}'", status_code=502)

    url = f"{base}{downstream_path}"
    if request.url.query:
        url = f"{url}?{request.url.query}"

    # Forward all headers except host/content-length; add request-id
    headers = {
        k: v for k, v in request.headers.items()
        if k.lower() not in ("host", "content-length")
    }
    headers["X-Request-ID"] = request.headers.get("X-Request-ID", str(uuid.uuid4()))

    body = await request.body()
    logger.info(f"[GW] {request.method} {request.url.path} → {url}")

    async with httpx.AsyncClient(timeout=30.0) as client:
        try:
            resp = await client.request(
                method=request.method,
                url=url,
                headers=headers,
                content=body,
            )
            return Response(
                content=resp.content,
                status_code=resp.status_code,
                headers=dict(resp.headers),
            )
        except (httpx.ConnectError, httpx.ConnectTimeout):
            # Dynamic fallback to localhost when docker network is unreachable (local hosting)
            fallback_ports = {
                "auth": 4001,
                "patient": 4002,
                "consultation": 4003,
                "prescription": 4004,
                "audit": 4005,
                "pharmacy": 4006,
                "ledger": 4007
            }
            port = fallback_ports.get(service_name)
            if port:
                fallback_url = f"http://127.0.0.1:{port}{downstream_path}"
                if request.url.query:
                    fallback_url = f"{fallback_url}?{request.url.query}"
                logger.info(f"[GW-FALLBACK] Connecting to local port {port} → {fallback_url}")
                try:
                    resp = await client.request(
                        method=request.method,
                        url=fallback_url,
                        headers=headers,
                        content=body,
                    )
                    return Response(
                        content=resp.content,
                        status_code=resp.status_code,
                        headers=dict(resp.headers),
                    )
                except Exception as local_exc:
                    logger.error(f"[GW-FALLBACK] Local fallback failed for {service_name}: {local_exc}")

            return Response(
                content=f'{{"success":false,"error":{{"code":"SERVICE_UNAVAILABLE","message":"Downstream service {service_name} unreachable"}}}}',
                status_code=503,
                media_type="application/json",
            )
        except httpx.TimeoutException:
            logger.error(f"[GW] Timeout → {url}")
            return Response(
                content=f'{{"success":false,"error":{{"code":"TIMEOUT","message":"Downstream service timed out"}}}}',
                status_code=504,
                media_type="application/json",
            )
        except Exception as exc:
            logger.error(f"[GW] Unexpected error → {url}: {exc}")
            return Response(
                content=f'{{"success":false,"error":{{"code":"GATEWAY_ERROR","message":"{str(exc)}"}}}}',
                status_code=502,
                media_type="application/json",
            )


# ── Route table ─────────────────────────────────────────────────────────────
#
# Auth Service (4001) — /api/patient/register, /api/patient/login,
#                       /api/doctor/register, /api/doctor/login
@app.api_route("/api/patient/register",   methods=["POST"], operation_id="auth_patient_register")
@app.api_route("/api/patient/login",      methods=["POST"], operation_id="auth_patient_login")
@app.api_route("/api/patient/update-name", methods=["POST"], operation_id="auth_patient_update_name")
@app.api_route("/api/doctor/register",    methods=["POST"], operation_id="auth_doctor_register")
@app.api_route("/api/doctor/login",       methods=["POST"], operation_id="auth_doctor_login")
@app.api_route("/api/pharmacy/login",     methods=["POST"], operation_id="auth_pharmacy_login")
@app.api_route("/api/media/upload",       methods=["POST"], operation_id="auth_media_upload")
async def route_auth(request: Request):
    return await forward("auth", request.url.path, request)



# Patient Service (4002) — /api/patient/dashboard/*, /api/patient/prescriptions/*
@app.api_route("/api/patient/dashboard/{path:path}", methods=["GET", "POST", "PUT", "PATCH", "DELETE"], operation_id="patient_dashboard_router")
@app.api_route("/api/patient/prescriptions/{path:path}", methods=["GET"], operation_id="patient_prescriptions_router")
async def route_patient(path: str, request: Request):
    return await forward("patient", request.url.path, request)


# Consultation Service (4003) — /api/consultation/*
@app.api_route("/api/consultation/{path:path}", methods=["GET", "POST", "PUT", "PATCH", "DELETE"], operation_id="consultation_router")
async def route_consultation(path: str, request: Request):
    return await forward("consultation", request.url.path, request)


# Pharmacy Service (4006) — Specific Prescription Endpoints
@app.api_route("/api/prescriptions/verify-scan",     methods=["POST"], operation_id="pharmacy_verify_scan_router")
@app.api_route("/api/prescriptions/dispense",        methods=["POST"], operation_id="pharmacy_dispense_router")
async def route_pharmacy_specific(request: Request):
    return await forward("pharmacy", request.url.path, request)


# Prescription Service (4004) — /api/prescriptions/*, /api/doctor/*,
#                                /api/pattern-analysis/*
@app.api_route("/api/prescriptions",               methods=["GET", "POST"], operation_id="prescription_root_router")
@app.api_route("/api/prescriptions/{path:path}",   methods=["GET", "POST", "PUT", "PATCH", "DELETE"], operation_id="prescription_path_router")
@app.api_route("/api/doctor/{path:path}",          methods=["GET", "POST", "PUT", "PATCH", "DELETE"], operation_id="doctor_path_router")
@app.api_route("/api/pattern-analysis/{path:path}", methods=["GET"], operation_id="pattern_analysis_router")
async def route_prescription(request: Request, path: str = ""):
    return await forward("prescription", request.url.path, request)


# Audit / AI Service (4005) — /api/audit, /api/duplicate-check,
#                             /api/interaction-check, /api/allergy-check,
#                             /api/recommendations
@app.api_route("/api/audit",              methods=["POST"], operation_id="audit_api_router")
@app.api_route("/api/duplicate-check",   methods=["POST"], operation_id="audit_duplicate_check_router")
@app.api_route("/api/interaction-check", methods=["POST"], operation_id="audit_interaction_check_router")
@app.api_route("/api/allergy-check",     methods=["POST"], operation_id="audit_allergy_check_router")
@app.api_route("/api/recommendations",   methods=["POST"], operation_id="audit_recommendations_router")
async def route_audit(request: Request):
    return await forward("audit", request.url.path, request)


# Pharmacy Service (4006) — /api/pharmacy/*
@app.api_route("/api/pharmacy/{path:path}",          methods=["GET", "POST", "PUT", "PATCH", "DELETE"], operation_id="pharmacy_path_router")
async def route_pharmacy(request: Request, path: str = ""):
    return await forward("pharmacy", request.url.path, request)


# Ledger Service (4007) — /api/blockchain/*, /api/ledger/*,
#                         /api/access/*, /api/visit-history/*,
#                         /api/activity-logs
@app.api_route("/api/blockchain/{path:path}",    methods=["GET", "POST"], operation_id="ledger_blockchain_router")
@app.api_route("/api/ledger/{path:path}",        methods=["GET", "POST"], operation_id="ledger_path_router")
@app.api_route("/api/access/{path:path}",        methods=["GET", "POST"], operation_id="ledger_access_router")
@app.api_route("/api/visit-history/{path:path}", methods=["GET"], operation_id="ledger_visit_history_router")
@app.api_route("/api/activity-logs",             methods=["GET"], operation_id="ledger_activity_logs_router")
async def route_ledger(request: Request, path: str = ""):
    return await forward("ledger", request.url.path, request)


# ── Health ───────────────────────────────────────────────────────────────────
@app.get("/health", tags=["General"])
async def health():
    return {
        "status": "online",
        "service": "gateway-service",
        "port": 4000,
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "services": SERVICES,
    }


@app.get("/", tags=["General"])
async def root():
    return {
        "status": "online",
        "service": "AegisRx API Gateway",
        "docs": "/docs",
    }
