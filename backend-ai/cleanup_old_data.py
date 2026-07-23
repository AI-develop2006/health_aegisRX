import os
import logging
from datetime import datetime, time
from pymongo import MongoClient
from dotenv import load_dotenv

load_dotenv(override=True)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("DatabaseCleaner")

MONGODB_URI = os.getenv("MONGODB_URI", "mongodb://localhost:27017/")
MONGODB_DATABASE = os.getenv("MONGODB_DATABASE", "healthcare_db")

def cleanup_old_records():
    logger.info(f"Connecting to MongoDB: {MONGODB_URI}")
    client = MongoClient(MONGODB_URI)
    db = client[MONGODB_DATABASE]

    # Start of today (00:00:00)
    now = datetime.now()
    today_start = datetime(now.year, now.month, now.day, 0, 0, 0)
    today_iso_prefix = today_start.strftime("%Y-%m-%d")

    logger.info(f"Deleting all database records created before today ({today_iso_prefix})...")

    # 1. Delete old prescriptions
    res_rx_datetime = db["prescriptions"].delete_many({"date": {"$lt": today_start}})
    logger.info(f"Deleted {res_rx_datetime.deleted_count} prescriptions (datetime < today)")

    # Also delete any string date prescriptions prior to today
    res_rx_string = db["prescriptions"].delete_many({
        "$and": [
            {"date": {"$type": "string"}},
            {"date": {"$not": {"$regex": f"^{today_iso_prefix}"}}}
        ]
    })
    logger.info(f"Deleted {res_rx_string.deleted_count} prescriptions (date string != today)")

    # 2. Delete old blockchain entries if present
    if "blockchain" in db.list_collection_names():
        today_ts = int(today_start.timestamp() * 1000)
        res_bc = db["blockchain"].delete_many({"timestamp": {"$lt": today_ts}})
        logger.info(f"Deleted {res_bc.deleted_count} old blockchain entries")

    # 3. Delete old activity logs if present
    if "activity_logs" in db.list_collection_names():
        res_act = db["activity_logs"].delete_many({"timestamp": {"$lt": today_start}})
        logger.info(f"Deleted {res_act.deleted_count} old activity logs")

    client.close()
    logger.info("MongoDB cleanup complete. Only today's records remain in the database.")

if __name__ == "__main__":
    cleanup_old_records()
