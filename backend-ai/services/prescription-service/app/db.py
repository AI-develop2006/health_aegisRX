"""Prescription Service — MongoDB connection"""
import logging
from pymongo import MongoClient
from app.config import MONGODB_URI, MONGODB_DATABASE, COLLECTION_PRESCRIPTIONS, FORCE_MOCK_DB

logger = logging.getLogger("prescription-service")
_db = None


def get_db():
    global _db
    if _db is None:
        if FORCE_MOCK_DB:
            logger.info("Prescription Service — FORCE_MOCK_DB is active. Connecting directly to local Mock DB.")
            from app.mock_db import MockMongoClient
            client = MockMongoClient(MONGODB_URI)
            _db = client[MONGODB_DATABASE]
            return _db
        try:
            client = MongoClient(MONGODB_URI, serverSelectionTimeoutMS=2000, timeoutMS=10000)
            client.server_info()
            _db = client[MONGODB_DATABASE]
            logger.info(f"Prescription Service — MongoDB connected: {MONGODB_DATABASE}")
        except Exception as e:
            logger.warning(f"Prescription Service — MongoDB Atlas unreachable ({e}). Falling back to Mock DB.")
            from app.mock_db import MockMongoClient
            client = MockMongoClient(MONGODB_URI)
            _db = client[MONGODB_DATABASE]
    return _db


def prescriptions_col():
    return get_db()[COLLECTION_PRESCRIPTIONS]


def activity_logs_col():
    return get_db()["activity_logs"]


def blockchain_col():
    return get_db()["blockchain"]
