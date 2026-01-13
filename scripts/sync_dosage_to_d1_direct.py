
import sqlite3
import requests
import json
import time

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

BATCH_SIZE = 5

def get_dosage_rows():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    # Sync ALL rows (WikEM + Hybrid + NCBI)
    cursor.execute("SELECT * FROM dosage_guidelines")
    rows = cursor.fetchall()
    conn.close()
    return rows

# ... (formatting functions)
def format_value(val):
    if val is None:
        return "NULL"
    if isinstance(val, (int, float)):
        return str(val)
    if isinstance(val, bytes):
        # Format as Hex Literal X'...'
        return f"X'{val.hex()}'"
    # Scape single quotes for SQL string
    clean_val = str(val).replace("'", "''")
    return f"'{clean_val}'"

def sync_batch(batch):
    if not batch: return
    
    # Inner function to send a specific list of rows
    def send_sql(rows):
        if not rows: return True
        
        # EXCLUDE 'id' column: D1 generates its own PK. 
        all_keys = rows[0].keys()
        keys = [k for k in all_keys if k != 'id']
        
        columns = ", ".join(keys)
        values_list = []
        for r in rows:
            row_vals = []
            for k in keys:
                val = r[k]
                # B blobs become double size in Hex SQL literal.
                # Cap at 10KB (binary) -> 20KB (SQL) to stay ultra-safe.
                limit = 10000 
                if isinstance(val, (str, bytes)) and len(val) > limit:
                    print(f"   ⚠️ Truncating massive field '{k}' MedID {r['med_id']} ({len(val)} bytes)")
                    if isinstance(val, bytes):
                        val = val[:limit]
                    else:
                        val = val[:limit] + "... [TRUNCATED]"
                row_vals.append(format_value(val))
            values_list.append(f"({', '.join(row_vals)})")
        
        sql = f"INSERT INTO dosage_guidelines ({columns}) VALUES {', '.join(values_list)};"
        
        try:
            response = requests.post(API_URL, headers=HEADERS, json={"sql": sql})
            if response.status_code == 200:
                res_json = response.json()
                if res_json.get("success"):
                    return True
                else:
                    err = str(res_json.get('errors'))
                    if "SQLITE_TOOBIG" in err:
                        return False # Trigger retry
                    print(f"   ❌ D1 Error: {err}")
                    return False
            return False
        except Exception as e:
            print(f"   ❌ Request Exception: {e}")
            return False

    # Try sending the whole batch
    if send_sql(batch):
        print(f"✅ Batch of {len(batch)} synced.")
    else:
        # If failed, retry one by one
        print(f"⚠️ Batch failed or too big. Retrying individually...")
        for row in batch:
            if send_sql([row]):
                print(f"   ✅ Item synced: MedID {row['med_id']}")
            else:
                print(f"   ❌ Item FAILED even individually: MedID {row['med_id']}")

def run_sync():
    print("🚀 Starting Direct D1 Sync for Dosage Guidelines (FULL SYNC)...")
    
    print("🧹 Clearing ALL old data in D1...")
    clear_sql = "DELETE FROM dosage_guidelines;"
    try:
        requests.post(API_URL, headers=HEADERS, json={"sql": clear_sql})
    except:
        pass

    rows = get_dosage_rows()
    print(f"📦 Found {len(rows)} rows to sync.")
    
    batch = []
    for row in rows:
        batch.append(row)
        if len(batch) >= BATCH_SIZE:
            sync_batch(batch)
            batch = []
            time.sleep(0.5) # Rate limit kindness
            
    if batch:
        sync_batch(batch)
        
    print("✨ Sync Complete!")

if __name__ == "__main__":
    run_sync()
