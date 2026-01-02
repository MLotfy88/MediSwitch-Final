import sqlite3
import os
import subprocess
import time
import json

# --- Configuration ---
DB_NAME = "mediswitch.db"
D1_DB_NAME = "mediswitsh-db"  # As defined in your Wrangler config
TEMP_SQL_DIR = "d1_sync_temp"
BATCH_SIZE = 1000
API_TOKEN = "yy-vk8KC4yth3Cn2lpva1AgrP2kGMJrQQrGIUM1-"

# TABLES in order of deployment
TABLES = [
    {"name": "drugs", "alias": "d1_import"},
    {"name": "drug_interactions", "alias": "d1_rules"},
    {"name": "med_ingredients", "alias": "d1_ingredients"},
    {"name": "food_interactions", "alias": "d1_food"},
    {"name": "disease_interactions", "alias": "d1_disease"},
    {"name": "dosage_guidelines", "alias": "d1_dosages"},
]

def run_wrangler(file_path):
    """Executes a SQL file against D1 with retry logic."""
    env = os.environ.copy()
    env["CLOUDFLARE_API_TOKEN"] = API_TOKEN
    
    cmd = [
        "npx", "wrangler", "d1", "execute", D1_DB_NAME,
        "--remote", "--yes", f"--file={file_path}"
    ]
    
    for attempt in range(1, 4):
        try:
            result = subprocess.run(cmd, env=env, capture_output=True, text=True, check=True)
            return True
        except subprocess.CalledProcessError as e:
            print(f"   ⚠️ Attempt {attempt} failed: {e.stderr}")
            if attempt < 3:
                time.sleep(5)
            else:
                return False

def sync_table(table_name, alias):
    print(f"\n📦 Starting Sync for table: {table_name}...")
    
    conn = sqlite3.connect(DB_NAME)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    # Get total count
    cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
    total_records = cursor.fetchone()[0]
    print(f"   Total records to sync: {total_records:,}")

    if total_records == 0:
        print("   ⏭ Skipping empty table.")
        return

    cursor.execute(f"SELECT * FROM {table_name}")
    
    chunk_idx = 0
    while True:
        rows = cursor.fetchmany(BATCH_SIZE)
        if not rows:
            break

        # Generate SQL for this batch
        cols = rows[0].keys()
        sql_lines = []
        for row in rows:
            vals = []
            for col in cols:
                v = row[col]
                if v is None: vals.append("NULL")
                elif isinstance(v, (int, float)): vals.append(str(v))
                else: 
                    # Escape single quotes
                    safe_v = str(v).replace("'", "''")
                    vals.append(f"'{safe_v}'")
            
            sql_lines.append(f"INSERT OR REPLACE INTO {table_name} ({', '.join(cols)}) VALUES ({', '.join(vals)});")
        
        # Write temporary file
        temp_file = os.path.join(TEMP_SQL_DIR, f"{alias}_temp_{chunk_idx:03d}.sql")
        with open(temp_file, "w", encoding="utf-8") as f:
            f.write("\n".join(sql_lines))
        
        # Execute to D1
        print(f"   🚀 Uploading chunk {chunk_idx:03d} ({len(rows)} records)...")
        if run_wrangler(temp_file):
            # Cleanup immediately on success
            os.remove(temp_file)
            print(f"   ✅ Chunk {chunk_idx:03d} Done.")
        else:
            print(f"   ❌ CRITICAL ERROR: Failed to upload chunk {chunk_idx:03d}. Stopping.")
            conn.close()
            exit(1)
        
        chunk_idx += 1
        time.sleep(0.5) # Avoid rate limits

    conn.close()

def main():
    if not os.path.exists(TEMP_SQL_DIR):
        os.makedirs(TEMP_SQL_DIR)
    
    print("🚀 MediSwitch Master D1 Sync (High-Performance & Clean)")
    print("-----------------------------------------------------")
    
    start_time = time.time()
    
    # Optional: Apply schema first? (Usually yes for full sync)
    print("📄 Applying Latest Schema...")
    schema_file = "d1_migration_sql/01_schema.sql"
    if os.path.exists(schema_file):
        if run_wrangler(schema_file):
            print("   ✅ Schema Applied Successfully.")
        else:
            print("   ❌ Failed to apply schema. Aborting.")
            exit(1)

    for table_info in TABLES:
        sync_table(table_info["name"], table_info["alias"])
        
    duration = (time.time() - start_time) / 60
    print(f"\n✨ ALL TABLES SYNCED SUCCESSFULLY in {duration:.2f} minutes!")
    print("Cleanup complete. Workspace is clean. 🧹")

if __name__ == "__main__":
    main()
