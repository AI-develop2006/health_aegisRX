"""Auth Service — MongoDB connection (self-contained, no shared app/)"""
import logging
from pymongo import MongoClient
from app.config import MONGODB_URI, MONGODB_DATABASE, FORCE_MOCK_DB

logger = logging.getLogger("auth-service")

_client: MongoClient | None = None
_db = None


def get_db():
    global _client, _db
    if _db is None:
        if FORCE_MOCK_DB:
            logger.info("Auth Service — FORCE_MOCK_DB is active. Connecting directly to local Mock DB.")
            from app.mock_db import MockMongoClient
            client = MockMongoClient(MONGODB_URI)
            _db = client[MONGODB_DATABASE]
            _client = client
            return _db
        try:
            client = MongoClient(MONGODB_URI, serverSelectionTimeoutMS=2000, timeoutMS=10000)
            client.server_info()
            _db = client[MONGODB_DATABASE]
            _client = client
            logger.info(f"Auth Service — MongoDB connected: {MONGODB_DATABASE}")
        except Exception as e:
            logger.warning(f"Auth Service — MongoDB Atlas unreachable ({e}). Falling back to Mock DB.")
            from app.mock_db import MockMongoClient
            client = MockMongoClient(MONGODB_URI)
            _db = client[MONGODB_DATABASE]
            _client = client
    return _db


def patients_col():
    return get_db()["patients"]


def doctors_col():
    return get_db()["doctor"]


def activity_logs_col():
    return get_db()["activity_logs"]
