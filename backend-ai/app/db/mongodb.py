from pymongo import MongoClient
from app.config import MONGODB_URI, MONGODB_DATABASE, logger


# ============================================
# MONGODB CONNECTION CLASS
# ============================================
class MongoDBConnector:
    """
    MongoDB Connector Class — handles all database operations.
    Preserves existing interface from ai_core.MongoDBConnector.
    """

    def __init__(self):
        """Initialize MongoDB connection."""
        try:
            self.client = MongoClient(MONGODB_URI, timeoutMS=10000)
            self.db = self.client[MONGODB_DATABASE]
            logger.info(f"Connected to MongoDB: {MONGODB_DATABASE}")
        except Exception as e:
            logger.error(f"MongoDB connection failed: {str(e)}")
            raise

    # ---- Collection helpers ----

    def get_prescriptions_collection(self):
        """Return the prescriptions collection."""
        from app.config import COLLECTION_PRESCRIPTIONS
        return self.db[COLLECTION_PRESCRIPTIONS]

    def get_allergies_collection(self):
        """Return the allergies collection."""
        from app.config import COLLECTION_ALLERGIES
        return self.db[COLLECTION_ALLERGIES]

    def get_patients_collection(self):
        """Return the patients collection."""
        return self.db["patients"]

    def get_doctors_collection(self):
        """Return the doctors collection."""
        return self.db["doctor"]

    def get_consultations_collection(self):
        """Return the consultation_requests collection."""
        return self.db["consultation_requests"]

    def get_activity_logs_collection(self):
        """Return the activity_logs collection."""
        return self.db["activity_logs"]

    def get_blockchain_collection(self):
        """Return the blockchain collection."""
        return self.db["blockchain"]

    def close(self):
        """Close MongoDB connection."""
        self.client.close()
        logger.info("MongoDB connection closed")


# ============================================
# SINGLETON / DEPENDENCY INJECTION
# ============================================
_connector: MongoDBConnector | None = None


def get_connector() -> MongoDBConnector:
    """Return the global MongoDBConnector singleton (set during app startup)."""
    if _connector is None:
        raise RuntimeError("MongoDBConnector not initialised. Check app startup lifespan.")
    return _connector


def set_connector(connector: MongoDBConnector):
    """Set the global MongoDBConnector singleton (called from app lifespan)."""
    global _connector
    _connector = connector
