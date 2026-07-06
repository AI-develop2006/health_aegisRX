import hashlib
from datetime import datetime

HEX_CHARS = '0123456789abcdef'


def get_shift(doctor_id: str) -> int:
    """
    Derive a deterministic shift value (1–15) from a doctor's ID string.
    Digits in the ID are summed; if none, a hash-based fallback is used.
    """
    doctor_id = str(doctor_id)
    total_sum = 0
    for char in doctor_id:
        if char.isdigit():
            total_sum += int(char)
    if total_sum == 0:
        hash_val = 0
        for char in doctor_id:
            hash_val = ord(char) + ((hash_val << 5) - hash_val)
            hash_val = (hash_val & 0xFFFFFFFF)
            if hash_val & 0x80000000:
                hash_val = hash_val - 0x100000000
        total_sum = abs(hash_val)
    return (total_sum % 14) + 1


def shift_hex(hex_str: str, shift: int) -> str:
    """Shift every hex character in `hex_str` by `shift` positions (wrapping 0-f)."""
    sb = []
    for char in hex_str.lower():
        if char in HEX_CHARS:
            idx = HEX_CHARS.index(char)
            new_idx = (idx + shift) % 16
            if new_idx < 0:
                new_idx += 16
            sb.append(HEX_CHARS[new_idx])
        else:
            sb.append(char)
    return "".join(sb)


def sha256_hash(input_str: str) -> str:
    """Compute the SHA-256 hex digest of a UTF-8 string."""
    return hashlib.sha256(input_str.encode('utf-8')).hexdigest()


def sign(hash_str: str, doctor_id: str) -> str:
    """Apply doctorSignId-based hex-shift to a hash to produce a signature."""
    shift = get_shift(doctor_id)
    return shift_hex(hash_str, shift)


def decrypt(signature: str, doctor_id: str) -> str:
    """Reverse the hex-shift to recover the original hash from a signature."""
    shift = get_shift(doctor_id)
    return shift_hex(signature, -shift)


def json_stringify_rx(rx: dict) -> str:
    """
    Produce the canonical JSON string of a prescription used for signing.
    Only deterministic fields are included; ordering is fixed.
    """
    meds_list = []
    for med in rx.get("medicines", []):
        meds_list.append(
            f'{{"name":"{med.get("name", "")}","interval":"{med.get("interval", "")}"}}'
        )
    meds_str = "[" + ",".join(meds_list) + "]"

    date_val = rx.get("date", "")
    if isinstance(date_val, datetime):
        date_val = date_val.strftime("%Y-%m-%d")
    elif not isinstance(date_val, str):
        date_val = str(date_val)

    return (
        f'{{"id":"{rx.get("id", "")}","'
        f'doctorName":"{rx.get("doctorName", "")}","'
        f'hospitalName":"{rx.get("hospitalName", "")}","'
        f'patientName":"{rx.get("patientName", "")}","'
        f'disease":"{rx.get("disease", "")}","'
        f'date":"{date_val}","'
        f'time":"{rx.get("time", "")}","'
        f'medicines":{meds_str}}}'
    )
