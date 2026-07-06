"""Auth Service — MongoDB connection (self-contained, no shared app/)"""
import logging
from pymongo import MongoClient
from app.config import MONGODB_URI, MONGODB_DATABASE

logger = logging.getLogger("auth-service")

_client: MongoClient | None = None
_db = None


def get_db():
    global _client, _db
    if _db is None:
        _client = MongoClient(MONGODB_URI, timeoutMS=10000)
        _db = _client[MONGODB_DATABASE]
        logger.info(f"Auth Service — MongoDB connected: {MONGODB_DATABASE}")
    return _db


def patients_col():
    return get_db()["patients"]


def doctors_col():
    return get_db()["doctor"]


def activity_logs_col():
    return get_db()["activity_logs"]
