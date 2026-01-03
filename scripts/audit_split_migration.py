import subprocess
import json
import sqlite3

# --- Configuration ---
DB_PATH = "mediswitch.db"
CF_INTERACTIONS_DB_NAME = "mediswitch-interactions"

def get_local_count(table):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.execute(f"SELECT COUNT(*) FROM {table}")
    count = cursor.fetchone()[0]
    conn.close()
    return count

def get_d1_count(db_name, table):
    try:
        cmd = f"export CLOUDFLARE_API_TOKEN=yy-vk8KC4yth3Cn2lpva1AgrP2kGMJrQQrGIUM1- && npx wrangler d1 execute {db_name} --command='SELECT COUNT(*) as count FROM {table}' --remote --json"
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        # Parse JSON output from wrangler
        data = json.loads(result.stdout)
        # Wrangler JSON output format varies but usually: [{ "results": [{"count": 123}] }]
        return data[0]['results'][0]['count']
    except Exception as e:
        print(f"Error fetching D1 count for {table}: {e}")
        return -1

def run_audit():
    tables = ['drug_interactions', 'food_interactions', 'disease_interactions']
    print(f"{'Table':<20} | {'Local':<10} | {'D1 (New)':<10} | {'Status'}")
    print("-" * 60)
    
    for table in tables:
        local = get_local_count(table)
        remote = get_d1_count(CF_INTERACTIONS_DB_NAME, table)
        
        status = "✅ Match" if local == remote else "❌ Mismatch"
        if remote == -1: status = "⚠️ Error"
        
        print(f"{table:<20} | {local:<10,} | {remote:<10,} | {status}")

if __name__ == "__main__":
    run_audit()
