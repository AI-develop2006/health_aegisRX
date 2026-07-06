import hashlib
import time
from datetime import datetime
from app.config import logger
from app.db.mongodb import MongoDBConnector
from app.utils.signature import sha256_hash


# ============================================
# BLOCKCHAIN MANAGER (extracted from app.py)
# ============================================
import re
import json


def _compute_block_hash(block: dict) -> str:
    """Compute SHA-256 hash of a blockchain block's canonical fields."""
    payload = json.dumps({
        "index": block["index"],
        "block_type": block["block_type"],
        "data": block["data"],
        "previous_hash": block["previous_hash"],
        "timestamp": block["timestamp"],
    }, sort_keys=True)
    return sha256_hash(payload)


def _serialize_doc(doc: dict) -> dict:
    """Convert MongoDB ObjectIds and datetimes to JSON-safe types."""
    if doc is None:
        return None
    doc_copy = dict(doc)
    if "_id" in doc_copy:
        doc_copy["_id"] = str(doc_copy["_id"])
    for key, value in doc_copy.items():
        if isinstance(value, datetime):
            if value.hour == 0 and value.minute == 0 and value.second == 0:
                doc_copy[key] = value.strftime("%Y-%m-%d")
            elif value.tzinfo is None:
                doc_copy[key] = value.isoformat() + "Z"
            else:
                doc_copy[key] = value.isoformat()
        elif isinstance(value, list):
            doc_copy[key] = [_serialize_doc(i) if isinstance(i, dict) else i for i in value]
    return doc_copy


class BlockchainManager:
    """
    Hash-linked blockchain stored in MongoDB.
    Block types: GENESIS | ACCESS_GRANT | ACCESS_REVOKE | PRESCRIPTION | VISIT_HISTORY | DISPENSED
    Extracted verbatim from app.py.
    """

    def __init__(self, db):
        self.db = db
        self.col = db["blockchain"]
        self._ensure_genesis()

    def _ensure_genesis(self):
        """Create genesis block if chain is empty or has legacy timestamps."""
        genesis = self.col.find_one({"index": 0})
        if genesis and not isinstance(genesis.get("timestamp"), int):
            logger.info("Blockchain: legacy datetime timestamps detected — resetting chain.")
            self.col.drop()
            genesis = None
        if genesis is None:
            block = {
                "index": 0,
                "block_type": "GENESIS",
                "data": {"message": "HealthLock Sovereign Chain — Genesis Block"},
                "previous_hash": "0" * 64,
                "timestamp": int(datetime.utcnow().timestamp() * 1000),
            }
            block["hash"] = _compute_block_hash(block)
            self.col.insert_one(block)
            logger.info("Blockchain genesis block created.")

    def add_block(self, block_type: str, data: dict, onchain_tx_hash: str = None, onchain_block_number: int = None) -> dict:
        """Append a new block to the chain."""
        last = self.col.find_one(sort=[("index", -1)])
        index = (last["index"] + 1) if last else 1
        previous_hash = last["hash"] if last else "0" * 64
        block = {
            "index": index,
            "block_type": block_type,
            "data": data,
            "previous_hash": previous_hash,
            "timestamp": int(datetime.utcnow().timestamp() * 1000),
        }
        if onchain_tx_hash:
            block["onchain_tx_hash"] = onchain_tx_hash
        if onchain_block_number:
            block["onchain_block_number"] = onchain_block_number
        block["hash"] = _compute_block_hash(block)
        self.col.insert_one(block.copy())
        logger.info(f"[BLOCKCHAIN] Block #{index} ({block_type}) added. Hash: {block['hash'][:16]}... (OnChain Tx: {onchain_tx_hash})")
        return block

    def get_chain(self) -> list:
        return [_serialize_doc(b) for b in self.col.find(sort=[("index", 1)])]

    def verify_chain(self) -> dict:
        blocks = list(self.col.find(sort=[("index", 1)]))
        if not blocks:
            return {"valid": True, "length": 0}
        for i in range(1, len(blocks)):
            cur, prev = blocks[i], blocks[i - 1]
            if cur["previous_hash"] != prev["hash"]:
                return {"valid": False, "error": f"Broken link at block #{cur['index']}", "block_index": cur["index"]}
            if cur["hash"] != _compute_block_hash(cur):
                return {"valid": False, "error": f"Tampered hash at block #{cur['index']}", "block_index": cur["index"]}
        return {"valid": True, "length": len(blocks)}

    def heal_chain_integrity(self) -> dict:
        blocks = list(self.col.find(sort=[("index", 1)]))
        repaired_count = 0
        if not blocks:
            return {"status": "SUCCESS", "repaired_blocks": 0}
        for i in range(1, len(blocks)):
            cur = blocks[i]
            prev = blocks[i - 1]
            needs_update = False
            if cur["previous_hash"] != prev["hash"]:
                cur["previous_hash"] = prev["hash"]
                needs_update = True
            recomputed_hash = _compute_block_hash(cur)
            if cur["hash"] != recomputed_hash:
                cur["hash"] = recomputed_hash
                needs_update = True
            if needs_update:
                self.col.update_one(
                    {"_id": cur["_id"]},
                    {"$set": {"previous_hash": cur["previous_hash"], "hash": cur["hash"]}}
                )
                repaired_count += 1
        return {"status": "HEALED" if repaired_count > 0 else "SUCCESS", "repaired_blocks": repaired_count}

    def get_blocks_by_type(self, block_type: str) -> list:
        return [_serialize_doc(b) for b in self.col.find({"block_type": block_type}, sort=[("index", 1)])]

    def has_doctor_access(self, doctor_id: str, patient_name: str) -> bool:
        safe = re.escape(patient_name)
        latest = self.col.find_one(
            {"block_type": {"$in": ["ACCESS_GRANT", "ACCESS_REVOKE"]},
             "data.doctor_id": doctor_id,
             "data.patient_name": {"$regex": f"^{safe}$", "$options": "i"}},
            sort=[("index", -1)]
        )
        return latest is not None and latest["block_type"] == "ACCESS_GRANT"

    def get_visit_history(self, patient_name: str) -> list:
        safe = re.escape(patient_name)
        blocks = self.col.find(
            {"block_type": "VISIT_HISTORY",
             "data.patient_name": {"$regex": f"^{safe}$", "$options": "i"}},
            sort=[("index", 1)]
        )
        return [_serialize_doc(b) for b in blocks]


# ============================================
# GLOBAL BLOCKCHAIN MANAGER SINGLETON
# ============================================
_blockchain_manager: BlockchainManager | None = None


def get_blockchain_manager() -> BlockchainManager | None:
    return _blockchain_manager


def set_blockchain_manager(manager: BlockchainManager):
    global _blockchain_manager
    _blockchain_manager = manager


# ============================================
# ACTIVITY LOG (async)
# ============================================

# In-memory fallback list
_local_activity_logs = []


async def log_activity(
    db: MongoDBConnector,
    event_type: str,
    patient_name: str,
    actor_id: str,
    details: str,
    onchain_tx_hash: str = None,
    onchain_block_number: int = None
):
    """
    Write a hashed activity log entry to MongoDB activity_logs collection.
    Falls back to in-memory list if MongoDB is unavailable.
    """
    timestamp_ms = int(time.time() * 1000)
    hash_input = f"{timestamp_ms}-{event_type}-{patient_name}-{actor_id}-{details}"
    log_hash = sha256_hash(hash_input)

    log_entry = {
        "timestamp": datetime.utcnow(),
        "eventType": event_type,
        "patientName": patient_name,
        "actorId": actor_id,
        "details": details,
        "hash": log_hash
    }
    if onchain_tx_hash:
        log_entry["onchain_tx_hash"] = onchain_tx_hash
    if onchain_block_number:
        log_entry["onchain_block_number"] = onchain_block_number

    logger.info(f"[ACTIVITY LOG] [{event_type}] Actor: {actor_id}, Patient: {patient_name} - {details} (OnChain Tx: {onchain_tx_hash})")

    if db is not None:
        try:
            db.db["activity_logs"].insert_one(log_entry.copy())
        except Exception as e:
            logger.error(f"Failed to save activity log in MongoDB: {str(e)}")
            _local_activity_logs.append(log_entry)
    else:
        _local_activity_logs.append(log_entry)


def get_activity_logs(db: MongoDBConnector) -> list:
    """Return all activity logs, newest first."""
    if db is not None:
        try:
            cursor = db.db["activity_logs"].find().sort("timestamp", -1)
            return [_serialize_doc(doc) for doc in cursor]
        except Exception:
            pass
    return [_serialize_doc(e) for e in reversed(_local_activity_logs)]
