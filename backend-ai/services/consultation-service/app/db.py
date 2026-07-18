"""Consultation Service — MongoDB connection using shared_core"""
import logging
from app.config import MONGODB_URI, MONGODB_DATABASE, FORCE_MOCK_DB
from shared_core.database import get_shared_db

logger = logging.getLogger("consultation-service")


def get_db():
    return get_shared_db("consultation", MONGODB_URI, MONGODB_DATABASE, FORCE_MOCK_DB)


def consultations_col():
    return get_db()["consultation_requests"]


def blockchain_col():
    return get_db()["blockchain"]


def activity_logs_col():
    return get_db()["activity_logs"]
