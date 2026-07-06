"""Pharmacy Service — MongoDB connection"""
import logging
from pymongo import MongoClient
from app.config import MONGODB_URI, MONGODB_DATABASE, COLLECTION_PRESCRIPTIONS

logger = logging.getLogger("pharmacy-service")
_db = None


def get_db():
    global _db
    if _db is None:
        client = MongoClient(MONGODB_URI, timeoutMS=10000)
        _db = client[MONGODB_DATABASE]
        logger.info(f"Pharmacy Service — MongoDB connected: {MONGODB_DATABASE}")
    return _db


def prescriptions_col():
    return get_db()[COLLECTION_PRESCRIPTIONS]


def activity_logs_col():
    return get_db()["activity_logs"]


def blockchain_col():
    return get_db()["blockchain"]
