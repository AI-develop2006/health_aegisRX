"""
Shared Core — Database Client and Mock DB Engine
Provides a unified MongoDB connector and reusable simulated MockMongoClient.
"""
import os
import re
import json
import logging
from datetime import datetime
from pymongo import MongoClient

logger = logging.getLogger("shared-core.database")

# ─────────────────────────────────────────────────────────────────────────────
# 1. MOCK MONGO CLIENT ENGINE (DEDUPLICATED)
# ─────────────────────────────────────────────────────────────────────────────

class MockCursor:
    def __init__(self, documents):
        self.documents = list(documents)

    def sort(self, key_or_list, direction=None):
        if not key_or_list:
            return self
        if isinstance(key_or_list, list):
            for key, dir in reversed(key_or_list):
                self.documents.sort(key=lambda x: x.get(key) or "", reverse=(dir == -1))
        else:
            self.documents.sort(key=lambda x: x.get(key_or_list) or "", reverse=(direction == -1))
        return self

    def limit(self, count):
        self.documents = self.documents[:count]
        return self

    def __iter__(self):
        return iter(self.documents)

    def __getitem__(self, index):
        return self.documents[index]

    def count(self):
        return len(self.documents)


class MockCollection:
    def __init__(self, db_name, col_name):
        self.db_name = db_name
        self.col_name = col_name
        
        # Resolve backend root to find .mock_db folder
        current_dir = os.path.dirname(os.path.abspath(__file__))
        backend_root = current_dir
        for _ in range(5):
            if os.path.exists(os.path.join(backend_root, "start_local.py")):
                break
            backend_root = os.path.dirname(backend_root)
            
        self.db_dir = os.path.join(backend_root, ".mock_db")
        os.makedirs(self.db_dir, exist_ok=True)
        self.filepath = os.path.join(self.db_dir, f"{col_name}.json")

    def _read_data(self):
        if not os.path.exists(self.filepath):
            return []
        try:
            with open(self.filepath, "r") as f:
                return json.load(f)
        except Exception:
            return []

    def _write_data(self, data):
        try:
            with open(self.filepath, "w") as f:
                json.dump(data, f, default=str, indent=2)
        except Exception as e:
            logger.error(f"MockDB write failed for {self.col_name}: {e}")

    def _get_nested(self, doc, key):
        parts = key.split(".")
        val = doc
        for part in parts:
            if isinstance(val, dict):
                val = val.get(part)
            else:
                return None
        return val

    def _match(self, doc, filter_dict):
        if not filter_dict:
            return True
        for k, v in filter_dict.items():
            if k == "$or":
                if not isinstance(v, list) or not any(self._match(doc, sub_filter) for sub_filter in v):
                    return False
                continue
            doc_val = self._get_nested(doc, k)
            
            # Handle standard _id matching
            if k == "_id" or k.endswith("._id"):
                doc_val = str(doc_val) if doc_val is not None else None
                v = str(v) if v is not None else None
                
            if isinstance(v, dict):
                for op, val in v.items():
                    if op == "$in":
                        if doc_val not in val:
                            return False
                    elif op == "$regex":
                        options = v.get("$options", "")
                        flags = 0
                        if "i" in options:
                            flags = re.IGNORECASE
                        if not re.search(val, str(doc_val or ""), flags):
                            return False
                    elif op == "$ne":
                        if doc_val == val:
                            return False
            else:
                if doc_val != v:
                    return False
        return True

    def _apply_update(self, doc, update):
        if "$set" in update:
            doc.update(update["$set"])
        if "$push" in update:
            for k, v in update["$push"].items():
                if k not in doc or not isinstance(doc[k], list):
                    doc[k] = []
                doc[k].append(v)

    def insert_one(self, document):
        import uuid
        doc = dict(document)
        if "_id" not in doc:
            doc["_id"] = str(uuid.uuid4())
        # Convert datetime objects to ISO strings
        for k, v in list(doc.items()):
            if isinstance(v, datetime):
                doc[k] = v.isoformat() + "Z"
        data = self._read_data()
        data.append(doc)
        self._write_data(data)
        
        class InsertOneResult:
            inserted_id = doc["_id"]
        return InsertOneResult()

    def find_one(self, filter=None, sort=None):
        data = self._read_data()
        matched = []
        for doc in data:
            if self._match(doc, filter):
                matched.append(doc)
        if not matched:
            return None
        cursor = MockCursor(matched)
        if sort:
            cursor.sort(sort)
        return cursor.documents[0]

    def find(self, filter=None, sort=None):
        data = self._read_data()
        matched = []
        for doc in data:
            if self._match(doc, filter):
                matched.append(doc)
        cursor = MockCursor(matched)
        if sort:
            cursor.sort(sort)
        return cursor

    def update_one(self, filter, update, upsert=False):
        data = self._read_data()
        found = False
        for idx, doc in enumerate(data):
            if self._match(doc, filter):
                self._apply_update(doc, update)
                data[idx] = doc
                found = True
                break
        if not found and upsert:
            import uuid
            new_doc = {}
            for k, v in filter.items():
                if not k.startswith("$") and not isinstance(v, dict):
                    new_doc[k] = v
            self._apply_update(new_doc, update)
            if "_id" not in new_doc:
                new_doc["_id"] = str(uuid.uuid4())
            data.append(new_doc)
        self._write_data(data)
        
        class UpdateResult:
            matched_count = 1 if found else 0
            modified_count = 1 if found else 0
        return UpdateResult()

    def delete_many(self, filter):
        data = self._read_data()
        original_len = len(data)
        data = [doc for doc in data if not self._match(doc, filter)]
        self._write_data(data)
        deleted_count = original_len - len(data)
        
        class DeleteResult:
            deleted_count = deleted_count
        return DeleteResult()

    def drop(self):
        if os.path.exists(self.filepath):
            try:
                os.remove(self.filepath)
            except Exception:
                pass


class MockDatabase:
    def __init__(self, db_name):
        self.db_name = db_name
        self.collections = {}

    def __getitem__(self, col_name):
        if col_name not in self.collections:
            self.collections[col_name] = MockCollection(self.db_name, col_name)
        return self.collections[col_name]


class MockMongoClient:
    def __init__(self, uri=None, *args, **kwargs):
        self.uri = uri
        self.databases = {}

    def __getitem__(self, db_name):
        if db_name not in self.databases:
            self.databases[db_name] = MockDatabase(db_name)
        return self.databases[db_name]

    def server_info(self):
        return {"version": "mock-5.0.0"}

    def close(self):
        pass


# ─────────────────────────────────────────────────────────────────────────────
# 2. SINGLETON DATABASE CONNECTOR FACTORY
# ─────────────────────────────────────────────────────────────────────────────

_connectors = {}

class DatabaseConnector:
    def __init__(self, service_name: str, uri: str, db_name: str, force_mock: bool = False):
        self.service_name = service_name
        self.uri = uri
        self.db_name = db_name
        self.force_mock = force_mock
        self.client = None
        self.db = None
        self.logger = logging.getLogger(f"shared-core.db-connector.{service_name}")
        self._connect()

    def _connect(self):
        if self.force_mock:
            self.logger.info("FORCE_MOCK_DB is active. Spawning local Mock DB client.")
            self.client = MockMongoClient(self.uri)
            self.db = self.client[self.db_name]
            return

        try:
            self.client = MongoClient(self.uri, serverSelectionTimeoutMS=2000, timeoutMS=10000)
            self.client.server_info()  # triggers connection attempt
            self.db = self.client[self.db_name]
            self.logger.info(f"MongoDB connected successfully to database: '{self.db_name}'")
        except Exception as e:
            self.logger.warning(f"MongoDB Atlas unreachable ({e}). Spawning local Mock DB client fallback.")
            self.client = MockMongoClient(self.uri)
            self.db = self.client[self.db_name]

    def get_collection(self, col_name: str):
        return self.db[col_name]


def get_shared_db(service_name: str, uri: str, db_name: str, force_mock: bool = False):
    """
    Returns the singleton DatabaseConnector instance for a given service.
    Reuses connections to prevent port/connection leaks.
    """
    key = f"{service_name}:{db_name}"
    if key not in _connectors:
        _connectors[key] = DatabaseConnector(service_name, uri, db_name, force_mock)
    return _connectors[key].db
