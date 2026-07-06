from web3 import Web3
from app.config import POLYGON_RPC_URL, POLYGON_CONTRACT_ADDRESS, logger
import os

# Initialize Web3
w3 = Web3(Web3.HTTPProvider(POLYGON_RPC_URL))

# Minimal ABI for the PrescriptionLedger contract
CONTRACT_ABI = [
    {
        "inputs": [
            {"internalType": "string", "name": "id", "type": "string"},
            {"internalType": "bytes32", "name": "hash", "type": "bytes32"}
        ],
        "name": "createPrescription",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [{"internalType": "string", "name": "id", "type": "string"}],
        "name": "markDispensed",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [{"internalType": "string", "name": "id", "type": "string"}],
        "name": "getPrescription",
        "outputs": [
            {"internalType": "bytes32", "name": "rxHash", "type": "bytes32"},
            {"internalType": "address", "name": "doctor", "type": "address"},
            {"internalType": "bool", "name": "exists", "type": "bool"},
            {"internalType": "bool", "name": "dispensed", "type": "bool"}
        ],
        "stateMutability": "view",
        "type": "function"
    }
]

def get_contract():
    if not POLYGON_CONTRACT_ADDRESS:
        logger.warning("POLYGON_CONTRACT_ADDRESS not configured. Blockchain transactions will fail.")
        return None
    try:
        return w3.eth.contract(address=w3.to_checksum_address(POLYGON_CONTRACT_ADDRESS), abi=CONTRACT_ABI)
    except Exception as e:
        logger.error(f"Error parsing POLYGON_CONTRACT_ADDRESS '{POLYGON_CONTRACT_ADDRESS}': {e}")
        return None

def create_prescription(rx_id: str, hash_hex: str, doctor_private_key: str) -> str:
    """Send transaction to register a prescription on Polygon."""
    contract = get_contract()
    if not contract:
        raise ValueError("Contract is not initialized")
        
    account = w3.eth.account.from_key(doctor_private_key)
    sender = account.address
    
    # Format SHA-256 hex string to bytes32 format (must start with 0x and be 32 bytes)
    clean_hex = hash_hex.strip()
    if not clean_hex.startswith("0x"):
        clean_hex = "0x" + clean_hex
        
    hash_bytes = w3.to_bytes(hexstr=clean_hex)
    
    nonce = w3.eth.get_transaction_count(sender)
    
    # Build transaction
    tx = contract.functions.createPrescription(rx_id, hash_bytes).build_transaction({
        "from": sender,
        "nonce": nonce,
        "gasPrice": w3.eth.gas_price,
    })
    
    signed_tx = w3.eth.account.sign_transaction(tx, doctor_private_key)
    tx_hash = w3.eth.send_raw_transaction(signed_tx.rawTransaction)
    
    logger.info(f"On-chain createPrescription transaction sent for {rx_id}. Hash: {tx_hash.hex()}")
    return tx_hash.hex()

def mark_dispensed(rx_id: str, pharmacy_private_key: str) -> str:
    """Send transaction to mark prescription as dispensed on Polygon."""
    contract = get_contract()
    if not contract:
        raise ValueError("Contract is not initialized")
        
    account = w3.eth.account.from_key(pharmacy_private_key)
    sender = account.address
    
    nonce = w3.eth.get_transaction_count(sender)
    
    tx = contract.functions.markDispensed(rx_id).build_transaction({
        "from": sender,
        "nonce": nonce,
        "gasPrice": w3.eth.gas_price,
    })
    
    signed_tx = w3.eth.account.sign_transaction(tx, pharmacy_private_key)
    tx_hash = w3.eth.send_raw_transaction(signed_tx.rawTransaction)
    
    logger.info(f"On-chain markDispensed transaction sent for {rx_id}. Hash: {tx_hash.hex()}")
    return tx_hash.hex()

def get_prescription(rx_id: str) -> dict:
    """Query prescription status from smart contract."""
    contract = get_contract()
    if not contract:
        return {"exists": False, "dispensed": False, "hash": "0x" + "0"*64, "doctor": "0x" + "0"*40}
        
    try:
        rx_hash, doctor, exists, dispensed = contract.functions.getPrescription(rx_id).call()
        return {
            "hash": rx_hash.hex(),
            "doctor": doctor,
            "exists": exists,
            "dispensed": dispensed
        }
    except Exception as e:
        logger.error(f"Error querying on-chain prescription {rx_id}: {e}")
        return {"exists": False, "dispensed": False, "hash": "0x" + "0"*64, "doctor": "0x" + "0"*40}
