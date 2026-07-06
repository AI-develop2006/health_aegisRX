"""
scripts/update_db.py
====================
Utility script to seed or update the MongoDB prescriptions collection
from the local prescriptions_db.json file.

Usage:
    cd e:\health_aegisRX\backend-ai
    python scripts/update_db.py
"""
import sys
import os
import json
import logging
from datetime import datetime
from pymongo import MongoClient

# Configure local logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("DBUpdater")

# Read environment variables directly with defaults
MONGODB_URI = os.getenv("MONGODB_URI", "mongodb://localhost:27017/")
MONGODB_DATABASE = os.getenv("MONGODB_DATABASE", "healthcare_db")
COLLECTION_PRESCRIPTIONS = os.getenv("COLLECTION_PRESCRIPTIONS", "prescriptions")

DB_FILE = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "prescriptions_db.json")


def main():
    if not os.path.exists(DB_FILE):
        print(f"ERROR: {DB_FILE} not found.")
        sys.exit(1)

    with open(DB_FILE) as f:
        data = json.load(f)

    print(f"Connecting to MongoDB: {MONGODB_DATABASE} ...")
    try:
        client = MongoClient(MONGODB_URI, timeoutMS=5000)
        db = client[MONGODB_DATABASE]
        col = db[COLLECTION_PRESCRIPTIONS]

        inserted = 0
        skipped = 0
        for rx in data:
            existing = col.find_one({"id": rx.get("id")})
            if existing:
                skipped += 1
                continue
            rx_mongo = rx.copy()
            if "date" in rx_mongo and isinstance(rx_mongo["date"], str):
                try:
                    rx_mongo["date"] = datetime.fromisoformat(rx_mongo["date"])
                except Exception:
                    pass
            col.insert_one(rx_mongo)
            inserted += 1

        print(f"Done. Inserted: {inserted}, Skipped (already exist): {skipped}")
    except Exception as e:
        print(f"ERROR: Failed to run DB update: {e}")
    finally:
        if 'client' in locals():
            client.close()


if __name__ == "__main__":
    main()
