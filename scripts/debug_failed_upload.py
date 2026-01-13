
import sqlite3
import requests
import json

# Configuration
DB_PATH = "assets/database/mediswitch.db"
ACCOUNT_ID = "9f7fd7dfef294f26d47d62df34726367"
DATABASE_ID = "77da23cd-a8cc-40bf-9c0f-f0effe7eeaa0"
API_TOKEN = "yy-vk8KC4yth3Cn2lpva1AgrP2kGMJrQQrGIUM1-"
API_URL = f"https://api.cloudflare.com/client/v4/accounts/{ACCOUNT_ID}/d1/database/{DATABASE_ID}/query"

HEADERS = {
    "Authorization": f"Bearer {API_TOKEN}",
    "Content-Type": "application/json"
}

def format_value(val):
    if val is None:
        return "NULL"
    if isinstance(val, (int, float)):
        return str(val)
    if isinstance(val, bytes):
        return f"X'{val.hex()}'"
    clean_val = str(val).replace("'", "''")
    return f"'{clean_val}'"

def debug_upload(med_id):
    print(f"\n🔍 Debugging Upload for MedID: {med_id}")
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    cursor.execute("SELECT * FROM dosage_guidelines WHERE med_id = ?", (med_id,))
    row = cursor.fetchone()
    conn.close()
    
    if not row:
        print("❌ Row not found locally.")
        return

    # EXCLUDE 'id' column
    all_keys = row.keys()
    keys = [k for k in all_keys if k != 'id']
    columns = ", ".join(keys)
    
    vals_data = []
    for k in keys:
        val = row[k]
        # D1 has a tight statement length limit (~100KB).
        # Hex conversion doubles binary size. 10KB binary -> 20KB SQL.
        limit = 10000 
        if isinstance(val, (str, bytes)) and len(val) > limit:
            print(f"   ⚠️ Truncating massive field '{k}' ({len(val)} bytes)")
            val = val[:limit] if isinstance(val, bytes) else val[:limit] + "..."
        vals_data.append(format_value(val))
    
    values_sql = f"({', '.join(vals_data)})"
    sql = f"INSERT INTO dosage_guidelines ({columns}) VALUES {values_sql};"
    
    print(f"SQL Length: {len(sql)}")
    
    payload = {"sql": sql}
    
    try:
        response = requests.post(API_URL, headers=HEADERS, json=payload)
        print(f"Status Code: {response.status_code}")
        print(f"Response Body: {response.text}")
    except Exception as e:
        print(f"Exception: {e}")

if __name__ == "__main__":
    ids = [6856, 7426, 7621, 7831, 7907, 8009, 24820]
    for i in ids:
        debug_upload(i)
