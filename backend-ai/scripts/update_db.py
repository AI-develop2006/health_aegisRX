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
from datetime import datetime

# Ensure backend-ai root is on the path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.config import MONGODB_URI, MONGODB_DATABASE, COLLECTION_PRESCRIPTIONS, logger
from app.db.mongodb import MongoDBConnector

DB_FILE = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "prescriptions_db.json")


def main():
    if not os.path.exists(DB_FILE):
        print(f"ERROR: {DB_FILE} not found.")
        sys.exit(1)

    with open(DB_FILE) as f:
        data = json.load(f)

    print(f"Connecting to MongoDB: {MONGODB_DATABASE} ...")
    connector = MongoDBConnector()
    col = connector.get_prescriptions_collection()

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
    connector.close()


if __name__ == "__main__":
    main()
