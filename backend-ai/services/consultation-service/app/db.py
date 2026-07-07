"""Consultation Service — MongoDB connection"""
import logging
from pymongo import MongoClient
from app.config import MONGODB_URI, MONGODB_DATABASE, FORCE_MOCK_DB

logger = logging.getLogger("consultation-service")
_db = None


def get_db():
    global _db
    if _db is None:
        if FORCE_MOCK_DB:
            logger.info("Consultation Service — FORCE_MOCK_DB is active. Connecting directly to local Mock DB.")
            from app.mock_db import MockMongoClient
            client = MockMongoClient(MONGODB_URI)
            _db = client[MONGODB_DATABASE]
            return _db
        try:
            client = MongoClient(MONGODB_URI, serverSelectionTimeoutMS=2000, timeoutMS=10000)
            client.server_info()
            _db = client[MONGODB_DATABASE]
            logger.info(f"Consultation Service — MongoDB connected: {MONGODB_DATABASE}")
        except Exception as e:
            logger.warning(f"Consultation Service — MongoDB Atlas unreachable ({e}). Falling back to Mock DB.")
            from app.mock_db import MockMongoClient
            client = MockMongoClient(MONGODB_URI)
            _db = client[MONGODB_DATABASE]
    return _db


def consultations_col():
    return get_db()["consultation_requests"]


def blockchain_col():
    return get_db()["blockchain"]


def activity_logs_col():
    return get_db()["activity_logs"]
