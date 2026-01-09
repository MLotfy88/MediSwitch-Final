import sqlite3
import zlib
import gzip
import io

DB_PATH = '/home/adminlotfy/project/assets/database/mediswitch.db'

def try_decompress(data):
    if not isinstance(data, bytes):
        return "Not Bytes", data
    
    # Try Zlib
    try:
        decompressed = zlib.decompress(data)
        return "ZLIB", decompressed.decode('utf-8', errors='ignore')
    except Exception:
        pass

    # Try Gzip
    try:
        with gzip.GzipFile(fileobj=io.BytesIO(data)) as f:
            decompressed = f.read()
            return "GZIP", decompressed.decode('utf-8', errors='ignore')
    except Exception:
        pass
        
    return "UNKNOWN", data.decode('utf-8', errors='replace')

conn = sqlite3.connect(DB_PATH)
cursor = conn.cursor()

# Get specific samples that failed
print("--- Forensic Analysis of Specific Failed IDs ---")
target_ids = (1268966, 1268972, 676557, 44154, 29275)
cursor.execute(f"SELECT id, instructions FROM dosage_guidelines WHERE id IN {target_ids}")
rows = cursor.fetchall()

for row in rows:
    id, instructions = row
    print(f"\nID: {id}")
    print(f"Original Type: {type(instructions)}")
    
    status, result = try_decompress(instructions)
    print(f"Decompression Result: {status}")
    print(f"Content Start: {result[:100]}...")

conn.close()
