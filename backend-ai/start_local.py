#!/usr/bin/env python3
"""
AegisRx Local Development Launcher
====================================
Starts all 8 microservices as standalone subprocesses on their designated ports.
Runs each service inside its own directory to prevent import conflicts.

Usage:  python start_local.py
        python start_local.py --service auth   (only start auth-service)
"""
import os
import sys
import time
import signal
import subprocess
import argparse
from pathlib import Path

BASE_DIR = Path(__file__).parent
ENV_FILE = BASE_DIR / ".env"

SERVICES = {
    "gateway":      ("services/gateway-service",      4000),
    "auth":         ("services/auth-service",         4001),
    "patient":      ("services/patient-service",      4002),
    "consultation": ("services/consultation-service", 4003),
    "prescription": ("services/prescription-service", 4004),
    "audit":        ("services/audit-service",        4005),
    "pharmacy":     ("services/pharmacy-service",     4006),
    "ledger":       ("services/ledger-service",       4007),
}


def start_service(name: str, folder: str, port: int) -> subprocess.Popen:
    """Start a single microservice with its folder as root."""
    cmd = [
        sys.executable, "-m", "uvicorn",
        "app.main:app",
        "--host", "0.0.0.0",
        "--port", str(port),
        "--reload",
    ]
    # Set CWD and PYTHONPATH to the service folder to isolate imports
    svc_path = BASE_DIR / folder
    env = {**os.environ, "PYTHONPATH": str(svc_path)}
    print(f"  [START] Starting {name}-service on port {port} (Cwd: {folder})")
    return subprocess.Popen(cmd, cwd=str(svc_path), env=env)


def main():
    parser = argparse.ArgumentParser(description="AegisRx Local Dev Launcher")
    parser.add_argument("--service", help="Run only one service by name")
    args = parser.parse_args()

    print("\n" + "=" * 60)
    print("  AegisRx / HealthLock — Local Dev Launcher (Isolated Mode)")
    print("=" * 60)

    if not ENV_FILE.exists():
        print(f"\n⚠️  No .env file found. Copy .env.example → .env and fill secrets.\n")

    # Load environment variables from base .env file
    if ENV_FILE.exists():
        with open(ENV_FILE, "r") as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    k, v = line.split("=", 1)
                    os.environ[k.strip()] = v.strip()

    # Run database seeding if enabled
    if os.getenv("RUN_DB_SEED_ON_STARTUP", "false").lower() == "true":
        print("\n[SEED] RUN_DB_SEED_ON_STARTUP is true. Automatically seeding database...")
        seed_script = BASE_DIR / "insert_sample_data.py"
        if seed_script.exists():
            try:
                subprocess.run([sys.executable, str(seed_script)], check=True)
                print("[SEED] Database seeding complete!\n")
            except Exception as e:
                print(f"[SEED] ERROR: Database seeding failed: {e}\n")
        else:
            print("[SEED] WARNING: insert_sample_data.py not found.\n")

    procs = []

    if args.service:
        svc = SERVICES.get(args.service)
        if not svc:
            print(f"Unknown service '{args.service}'. Valid: {', '.join(SERVICES.keys())}")
            sys.exit(1)
        procs.append(start_service(args.service, svc[0], svc[1]))
    else:
        for name, (folder, port) in SERVICES.items():
            procs.append(start_service(name, folder, port))
            time.sleep(0.4)

    print(f"\n[OK] {len(procs)} process(es) started. Press Ctrl+C to stop all.\n")

    def shutdown(sig, frame):
        print("\n[STOP] Shutting down all services...")
        for p in procs:
            try:
                if os.name == 'nt':
                    # Cleanly terminate process tree on Windows
                    subprocess.run(["taskkill", "/F", "/T", "/PID", str(p.pid)], 
                                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                else:
                    p.terminate()
            except Exception:
                pass
        sys.exit(0)

    signal.signal(signal.SIGINT, shutdown)
    signal.signal(signal.SIGTERM, shutdown)

    for p in procs:
        p.wait()


if __name__ == "__main__":
    main()
