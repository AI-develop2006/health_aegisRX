"""Pharmacy Service — MongoDB connection using shared_core"""
import logging
from app.config import MONGODB_URI, MONGODB_DATABASE, COLLECTION_PRESCRIPTIONS, FORCE_MOCK_DB
from shared_core.database import get_shared_db

logger = logging.getLogger("pharmacy-service")


def get_db():
    return get_shared_db("pharmacy", MONGODB_URI, MONGODB_DATABASE, FORCE_MOCK_DB)


def prescriptions_col():
    return get_db()[COLLECTION_PRESCRIPTIONS]


def activity_logs_col():
    return get_db()["activity_logs"]


def blockchain_col():
    return get_db()["blockchain"]
