"""
Ledger Service — Self-Contained Blockchain Manager + Activity Logs
"""
import re
import json
import time
import hashlib
import logging
from datetime import datetime
from app.config import MONGODB_URI, MONGODB_DATABASE, FORCE_MOCK_DB
from shared_core.database import get_shared_db

logger = logging.getLogger("ledger-service")


def get_db():
    return get_shared_db("ledger", MONGODB_URI, MONGODB_DATABASE, FORCE_MOCK_DB)


# ─────────────────────────────────────────────────────────────────────────────
# SERIALIZATION
# ─────────────────────────────────────────────────────────────────────────────
def _serialize(doc):
    if doc is None:
        return None
    d = dict(doc)
    if "_id" in d:
        d["_id"] = str(d["_id"])
    for k, v in d.items():
        if isinstance(v, datetime):
            d[k] = v.strftime("%Y-%m-%d") if (v.hour == 0 and v.minute == 0) else v.isoformat() + "Z"
        elif isinstance(v, list):
            d[k] = [_serialize(i) if isinstance(i, dict) else i for i in v]
    return d


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


# ─────────────────────────────────────────────────────────────────────────────
# BLOCKCHAIN MANAGER
# ─────────────────────────────────────────────────────────────────────────────
class BlockchainManager:
    def __init__(self):
        self.col = get_db()["blockchain"]
        self._ensure_genesis()

    def _ensure_genesis(self):
        genesis = self.col.find_one({"index": 0})
        if genesis and not isinstance(genesis.get("timestamp"), int):
            logger.info("Ledger: legacy timestamps detected — resetting chain.")
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

    def add_block(self, block_type: str, data: dict,
                  onchain_tx_hash: str = None, onchain_block_number: int = None) -> dict:
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
        logger.info(f"[BLOCKCHAIN] Block #{index} ({block_type}) hash: {block['hash'][:16]}…")
        return block

    def get_chain(self) -> list:
        return [_serialize(b) for b in self.col.find(sort=[("index", 1)])]

    def verify_chain(self) -> dict:
        blocks = list(self.col.find(sort=[("index", 1)]))
        if not blocks:
            return {"valid": True, "length": 0}
        for i in range(1, len(blocks)):
            cur, prev = blocks[i], blocks[i - 1]
            if cur["previous_hash"] != prev["hash"]:
                return {"valid": False, "error": f"Broken link at #{cur['index']}", "block_index": cur["index"]}
            if cur["hash"] != _compute_block_hash(cur):
                return {"valid": False, "error": f"Tampered hash at #{cur['index']}", "block_index": cur["index"]}
        return {"valid": True, "length": len(blocks)}

    def heal_chain_integrity(self) -> dict:
        blocks = list(self.col.find(sort=[("index", 1)]))
        repaired = 0
        for i in range(1, len(blocks)):
            cur, prev = blocks[i], blocks[i - 1]
            changed = False
            if cur["previous_hash"] != prev["hash"]:
                cur["previous_hash"] = prev["hash"]
                changed = True
            rh = _compute_block_hash(cur)
            if cur["hash"] != rh:
                cur["hash"] = rh
                changed = True
            if changed:
                self.col.update_one({"_id": cur["_id"]},
                                    {"$set": {"previous_hash": cur["previous_hash"], "hash": cur["hash"]}})
                repaired += 1
        return {"status": "HEALED" if repaired else "SUCCESS", "repaired_blocks": repaired}

    def get_blocks_by_type(self, block_type: str) -> list:
        return [_serialize(b) for b in self.col.find({"block_type": block_type}, sort=[("index", 1)])]

    def has_doctor_access(self, doctor_id: str, patient_name: str) -> bool:
        safe = re.escape(patient_name)
        safe_space = re.escape(patient_name.replace("_", " "))
        safe_underscore = re.escape(patient_name.replace(" ", "_"))
        pattern = f"^({safe}|{safe_space}|{safe_underscore})$"
        latest = self.col.find_one(
            {"block_type": {"$in": ["ACCESS_GRANT", "ACCESS_REVOKE"]},
             "data.doctor_id": doctor_id,
             "$or": [
                 {"data.patient_name": {"$regex": pattern, "$options": "i"}},
                 {"data.patient_id": {"$regex": pattern, "$options": "i"}}
             ]},
            sort=[("index", -1)]
        )
        return latest is not None and latest["block_type"] == "ACCESS_GRANT"

    def get_visit_history(self, patient_name: str) -> list:
        safe = re.escape(patient_name)
        safe_space = re.escape(patient_name.replace("_", " "))
        safe_underscore = re.escape(patient_name.replace(" ", "_"))
        pattern = f"^({safe}|{safe_space}|{safe_underscore})$"
        return [_serialize(b) for b in self.col.find(
            {"block_type": "VISIT_HISTORY",
             "$or": [
                 {"data.patient_name": {"$regex": pattern, "$options": "i"}},
                 {"data.patient_id": {"$regex": pattern, "$options": "i"}}
             ]},
            sort=[("index", 1)]
        )]


# ─────────────────────────────────────────────────────────────────────────────
# SINGLETON
# ─────────────────────────────────────────────────────────────────────────────
_bm: BlockchainManager | None = None


def get_blockchain_manager() -> BlockchainManager | None:
    return _bm


def init_blockchain_manager():
    global _bm
    _bm = BlockchainManager()
    logger.info("Ledger Service — BlockchainManager initialized.")
    return _bm


# ─────────────────────────────────────────────────────────────────────────────
# ACTIVITY LOGS
# ─────────────────────────────────────────────────────────────────────────────
def log_activity(event_type: str, patient_name: str, actor_id: str, details: str,
                 onchain_tx_hash: str = None):
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
    if onchain_tx_hash:
        entry["onchain_tx_hash"] = onchain_tx_hash
    try:
        get_db()["activity_logs"].insert_one(entry.copy())
    except Exception as e:
        logger.error(f"Activity log write failed: {e}")
    logger.info(f"[ACTIVITY] [{event_type}] {actor_id} / {patient_name}: {details}")


def get_activity_logs() -> list:
    try:
        return [_serialize(d) for d in get_db()["activity_logs"].find().sort("timestamp", -1)]
    except Exception:
        return []
