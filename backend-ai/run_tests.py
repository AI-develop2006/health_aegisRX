import subprocess
import time
import httpx
import json
import sys
import os

def run():
    print("=== STARTING SELF-CONTAINED API TEST RUNNER ===")
    
    # Start uvicorn server in a background subprocess
    print("1. Launching FastAPI server in the background...")
    proc = subprocess.Popen(
        [sys.executable, "-m", "uvicorn", "app.main:app", "--host", "127.0.0.1", "--port", "8000"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )
    
    # Give the server a few seconds to bind to the port
    print("2. Waiting 3 seconds for uvicorn to initialize...")
    time.sleep(3.0)
    
    BASE_URL = "http://127.0.0.1:8000"
    
    # Double check connection
    try:
        response = httpx.get(f"{BASE_URL}/health")
        if response.status_code == 200:
            print("3. Connection established. Server is ONLINE.\n")
        else:
            print(f"3. Connection failed. Server returned code {response.status_code}.")
            proc.terminate()
            return
    except Exception as e:
        print(f"3. Connection failed. Could not reach server at {BASE_URL}: {e}")
        print("Cleaning up background process...")
        proc.terminate()
        return

    # Run client tests
    try:
        from test_client import test_endpoints
        test_endpoints()
    except Exception as e:
        print(f"Error during test execution: {e}")
    finally:
        # Shut down background server process
        print("\n4. Shutting down background FastAPI server...")
        proc.terminate()
        proc.wait()
        print("Server stopped. Clean up complete.")

if __name__ == "__main__":
    run()
