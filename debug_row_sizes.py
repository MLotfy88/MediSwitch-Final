import sqlite3
import binascii
import os

DB_PATH = "assets/database/mediswitch.db"

def clean_sql_val(val):
    if val is None: return "NULL"
    if isinstance(val, (int, float)): return str(val)
    if isinstance(val, bytes):
        hex_str = binascii.hexlify(val).decode('utf-8')
        return f"X'{hex_str}'"
    txt = str(val)
    safe_v = txt.replace("'", "''")
    return f"'{safe_v}'"

def check_sizes():
    if not os.path.exists(DB_PATH):
        print("DB not found")
        return

    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    table = "dosage_guidelines"
    
    print(f"Checking {table}...")
    
    # Get columns
    c = conn.execute(f"SELECT * FROM {table} LIMIT 1")
    cols = [description[0] for description in c.description]
    
    cur = conn.execute(f"SELECT * FROM {table}")
    
    max_len = 0
    max_id = -1
    count_over_1mb = 0
    count_over_100kb = 0
    
    for row in cur:
        vals = [clean_sql_val(row[col]) for col in cols]
        sql = f"INSERT OR REPLACE INTO {table} ({', '.join(cols)}) VALUES ({', '.join(vals)});"
        length = len(sql)
        
        if length > max_len:
            max_len = length
            max_id = row['id']
            
        if length > 1_000_000: # 1MB
            count_over_1mb += 1
            print(f"🚨 ID {row['id']} is HUGE: {length/1024/1024:.2f} MB")
        elif length > 100_000: # 100KB
            count_over_100kb += 1
            
    print(f"\nStats for {table}:")
    print(f"Max Statement Length: {max_len} bytes ({max_len/1024:.2f} KB)")
    print(f"Max ID: {max_id}")
    print(f"Rows > 1MB: {count_over_1mb}")
    print(f"Rows > 100KB: {count_over_100kb}")

if __name__ == "__main__":
    check_sizes()
