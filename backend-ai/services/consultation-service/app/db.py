"""Consultation Service — MongoDB connection"""
import logging
from pymongo import MongoClient
from app.config import MONGODB_URI, MONGODB_DATABASE

logger = logging.getLogger("consultation-service")
_db = None


def get_db():
    global _db
    if _db is None:
        client = MongoClient(MONGODB_URI, timeoutMS=10000)
        _db = client[MONGODB_DATABASE]
        logger.info(f"Consultation Service — MongoDB connected: {MONGODB_DATABASE}")
    return _db


def consultations_col():
    return get_db()["consultation_requests"]


def blockchain_col():
    return get_db()["blockchain"]


def activity_logs_col():
    return get_db()["activity_logs"]
