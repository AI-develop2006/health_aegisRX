import json
import os
import hashlib
from pymongo import MongoClient

db_file = 'prescriptions_db.json'
if os.path.exists(db_file):
    with open(db_file, 'r') as f:
        data = json.load(f)
    for rx in data:
        if rx.get('patientName') == 'Elena Vance':
            rx['patientName'] = 'Elenavan'
            # Re-sign
            HEX_CHARS = '0123456789abcdef'
            def get_shift(doctor_id):
                total_sum = sum(int(c) for c in str(doctor_id) if c.isdigit())
                return (total_sum % 14) + 1
            def shift_hex(hex_str, shift):
                return ''.join(HEX_CHARS[(HEX_CHARS.index(c) + shift) % 16] if c in HEX_CHARS else c for c in hex_str.lower())
            meds_list = []
            for med in rx.get('medicines', []):
                meds_list.append(f'{{"name":"{med.get("name","")}","interval":"{med.get("interval","")}"}}')
            meds_str = "[" + ",".join(meds_list) + "]"
            payload = (
                f'{{"id":"{rx.get("id","")}",'
                f'"doctorName":"{rx.get("doctorName","")}",'
                f'"hospitalName":"{rx.get("hospitalName","")}",'
                f'"patientName":"Elenavan",'
                f'"disease":"{rx.get("disease","")}",'
                f'"date":"{rx.get("date","")}",'
                f'"time":"{rx.get("time","")}",'
                f'"medicines":{meds_str}}}'
            )
            rx_hash = hashlib.sha256(payload.encode('utf-8')).hexdigest()
            rx['signature'] = shift_hex(rx_hash, get_shift(rx['doctorSignId']))
    with open(db_file, 'w') as f:
        json.dump(data, f, indent=2)
    print('Updated local JSON DB successfully.')

mongo_uri = os.environ.get('MONGODB_URI') or 'mongodb+srv://user:pass@cluster.mongodb.net/healthcare_db'
if os.path.exists('.env'):
    with open('.env', 'r') as f:
        for line in f:
            if line.startswith('MONGODB_URI='):
                mongo_uri = line.strip().split('=', 1)[1].strip('\"\'')
try:
    client = MongoClient(mongo_uri)
    db = client['healthcare_db']
    res = db['prescriptions'].delete_many({'patientName': 'Elena Vance'})
    print(f'Deleted {res.deleted_count} stale Elena Vance records from MongoDB.')
    res2 = db['prescriptions'].delete_many({'patientName': 'Elenavan'})
    print(f'Deleted {res2.deleted_count} Elenavan records from MongoDB.')
except Exception as e:
    print('MongoDB update skipped or failed:', e)
