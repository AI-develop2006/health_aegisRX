"""Auth Service — MongoDB connection using shared_core"""
import logging
from app.config import MONGODB_URI, MONGODB_DATABASE, FORCE_MOCK_DB
from shared_core.database import get_shared_db

logger = logging.getLogger("auth-service")


def get_db():
    return get_shared_db("auth", MONGODB_URI, MONGODB_DATABASE, FORCE_MOCK_DB)


def patients_col():
    return get_db()["patients"]


def doctors_col():
    return get_db()["doctor"]


def activity_logs_col():
    return get_db()["activity_logs"]
