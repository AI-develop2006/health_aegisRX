"""
Consultation Service — Blockchain & Activity Logging utilities
Direct database writes to blockchain & activity_logs collections.
"""
import json
import hashlib
import time
import logging
from datetime import datetime
from app.db import blockchain_col, activity_logs_col

logger = logging.getLogger("consultation-service")


def _sha256(s: str) -> str:
    return hashlib.sha256(s.encode("utf-8")).hexdigest()


def _compute_block_hash(block: dict) -> str:
    payload = json.dumps({
        "index": block["index"],
        "block_type": block["block_type"],
        "data": block["data"],
        "previous_hash": block["previous_hash"],
        "timestamp": block["timestamp"],
    }, sort_keys=True)
    return _sha256(payload)


class BlockchainManager:
    def __init__(self):
        self.col = blockchain_col()

    def add_block(self, block_type: str, data: dict) -> dict:
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
        block["hash"] = _compute_block_hash(block)
        self.col.insert_one(block.copy())
        logger.info(f"[CONSULTATION BLOCKCHAIN] Block #{index} ({block_type}) added. Hash: {block['hash'][:16]}...")
        return block


async def log_activity(event_type: str, patient_name: str, actor_id: str, details: str):
    ts_ms = int(time.time() * 1000)
    hash_input = f"{ts_ms}-{event_type}-{patient_name}-{actor_id}-{details}"
    entry = {
        "timestamp": datetime.utcnow(),
        "eventType": event_type,
        "patientName": patient_name,
        "actorId": actor_id,
        "details": details,
        "hash": _sha256(hash_input),
    }
    try:
        activity_logs_col().insert_one(entry)
    except Exception as e:
        logger.error(f"Activity logging failed: {e}")
    logger.info(f"[ACTIVITY] [{event_type}] Actor: {actor_id}, Patient: {patient_name} - {details}")
