import os
import subprocess
import time
import json
import sqlite3

# User Credentials
CLOUDFLARE_API_TOKEN = "yy-vk8KC4yth3Cn2lpva1AgrP2kGMJrQQrGIUM1-"
CLOUDFLARE_EMAIL = "eedf653449abdca28e865ddf3511dd4c62ed2"
DATABASE_NAME = "mediswitsh-db"
DATABASE_ID = "77da23cd-a8cc-40bf-9c0f-f0effe7eeaa0"

# Paths
DB_PATH = "assets/database/mediswitch.db"
CHUNK_SIZE = 50  # Further reduced
MAX_RETRIES = 5

def log_error(msg):
    with open("upload_errors.log", "a") as f:
        f.write(msg + "\n" + "="*80 + "\n")

def run_command(cmd, env=None):
    """Run a shell command and return output"""
    try:
        current_env = os.environ.copy()
        if env:
            current_env.update(env)
            
        result = subprocess.run(
            cmd, 
            shell=True, 
            check=True, 
            stdout=subprocess.PIPE, 
            stderr=subprocess.PIPE,
            text=True,
            env=current_env
        )
        return True, result.stdout
    except subprocess.CalledProcessError as e:
        err_msg = f"CMD: {cmd}\nSTDOUT: {e.stdout}\nSTDERR: {e.stderr}"
        log_error(err_msg)
        return False, err_msg

def _upload_batch(table, columns, values_list, env):
    sql = f"INSERT INTO {table} ({','.join(columns)}) VALUES {','.join(values_list)};"
    with open("temp_batch.sql", "w", encoding="utf-8") as f:
        f.write(sql)
    
    # Retry logic
    for attempt in range(5):
        cmd = f"npx wrangler d1 execute {DATABASE_NAME} --file=temp_batch.sql --remote"
        success, output = run_command(cmd, env)
        if success:
           return
        else:
           if attempt == 4:
                # Fallback to slow mode if batch failed (likely too big or other error)
                if "SQLITE_TOOBIG" in output:
                     pass # handled by caller? No, caller relies on this. 
                     # Wait, I moved logic OUT of the caller loop.
                     # I should put the Adaptive Logic HERE inside the helper.
                     print(f"\n      ⚠️ Batch failed ({len(values_list)} rows), splitting...")
                     _upload_batch_slow(table, columns, values_list, env)
                     return

                print(f"\n      ❌ Failed batch. Error: {output[:100]}")
           else:
                time.sleep(1)

def _upload_batch_slow(table, columns, values_list, env):
    # One by one
    print("      ⚠️ fallback: uploading row by row...")
    for val_str in values_list:
         # val_str is "(...)"
         single_sql = f"INSERT INTO {table} ({','.join(columns)}) VALUES {val_str};"
         with open("temp_single.sql", "w", encoding="utf-8") as f:
            f.write(single_sql)
         run_command(f"npx wrangler d1 execute {DATABASE_NAME} --file=temp_single.sql --remote", env)


def upload_to_d1():
    print("🚀 Starting Cloudflare D1 Sync...")
    print(f"   Database: {DATABASE_NAME} ({DATABASE_ID})")
    print("="*80)
    
    # Check wrangler authentication/installation
    # Actually, we can just set the token in env var
    env = {
        "CLOUDFLARE_API_TOKEN": CLOUDFLARE_API_TOKEN,
        "CLOUDFLARE_EMAIL": CLOUDFLARE_EMAIL
    }
    
    # 0. RESET DATABASE (DROP TABLES)
    print("\n💥 Step 0: Resetting Database (DROP TABLES)...")
    tables_to_drop = ["drugs", "dosage_guidelines", "drug_interactions", "drug_interactions_v8", "disease_interactions", "food_interactions", "med_ingredients"]
    for table in tables_to_drop:
        cmd = f'npx wrangler d1 execute {DATABASE_NAME} --command="DROP TABLE IF EXISTS {table}" --remote'
        run_command(cmd, env)
        print(f"   🗑️  Dropped {table}")

    # 1. Upload Schema (Dynamic)
    print("\n📋 Step 1: Creating Schema (Dynamic from Local DB)...")
    conn_schema = sqlite3.connect(DB_PATH)
    cursor_schema = conn_schema.cursor()
    # Explicitly exclude sqlite_sequence
    cursor_schema.execute("SELECT name, sql FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name != 'sqlite_sequence'")
    tables_schema = cursor_schema.fetchall()
    conn_schema.close()

    for i, (tbl_name, sql) in enumerate(tables_schema):
        if not sql: continue
        print(f"   🔨 Creating Table {i+1}: {tbl_name}...")
        
        # Write to temp file
        with open("temp_schema.sql", "w", encoding="utf-8") as f:
            f.write(sql)
        
        cmd = f"npx wrangler d1 execute {DATABASE_NAME} --file=temp_schema.sql --remote"
        run_command(cmd, env)


    # 2. Upload Data
    print("\n📦 Step 2: Uploading Data...")
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Get tables again (or reuse)
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name != 'sqlite_sequence'")
    tables = [r[0] for r in cursor.fetchall()]
    
    for table in tables:
        print(f"\n   Processing table: {table}")
        
        # No need to clear remote table if we just dropped and recreated it
        
        cursor.execute(f"SELECT COUNT(*) FROM {table}")
        count = cursor.fetchone()[0]
        print(f"   Rows: {count:,}")
        
        cursor.execute(f"SELECT * FROM {table}")
        columns = [description[0] for description in cursor.description]
        
        # Smart Batching Configuration
        MAX_BATCH_SIZE_BYTES = 800 * 1024  # 800KB safe limit (D1 limit is ~1MB)
        MAX_ROW_COUNT = 1000               # Also cap by count to avoid parsing issues
        
        current_batch_rows = []
        current_batch_size = 0
        
        processed = 0
        
        while True:
            # Fetch one by one to pack efficiently? 
            # Or fetch a chunk and split? Fetching larger chunks is better for cursor.
            rows = cursor.fetchmany(MAX_ROW_COUNT)
            if not rows:
                # Process remaining buffer
                if current_batch_rows:
                    _upload_batch(table, columns, current_batch_rows, env)
                    processed += len(current_batch_rows)
                    print(f"\r      Uploaded {processed:,} / {count:,} rows...", end="")
                break
            
            for row in rows:
                # Calculate row size approximation
                # This is a rough estimate: values string length + delimiters
                # It doesn't need to be perfect, just safe.
                row_size = 0
                formatted_values = []
                for val in row:
                    if val is None:
                        formatted_values.append("NULL")
                        row_size += 4
                    elif isinstance(val, (int, float)):
                        s_val = str(val)
                        formatted_values.append(s_val)
                        row_size += len(s_val)
                    elif isinstance(val, bytes):
                        # Hex string x'...'
                        hex_val = val.hex()
                        s_val = f"x'{hex_val}'"
                        formatted_values.append(s_val)
                        row_size += len(s_val)
                    else:
                        clean_val = str(val).replace("'", "''")
                        s_val = f"'{clean_val}'"
                        formatted_values.append(s_val)
                        row_size += len(s_val)
                
                # Check if adding this row exceeds limits
                if (current_batch_size + row_size > MAX_BATCH_SIZE_BYTES) or (len(current_batch_rows) >= MAX_ROW_COUNT):
                    # Upload current batch
                    if current_batch_rows:
                        _upload_batch(table, columns, current_batch_rows, env)
                        processed += len(current_batch_rows)
                        print(f"\r      Uploaded {processed:,} / {count:,} rows...", end="")
                        
                        # Reset batch
                        current_batch_rows = []
                        current_batch_size = 0
                
                # Add row to batch
                current_batch_rows.append(f"({','.join(formatted_values)})")
                current_batch_size += row_size

        # Flush final batch
        if current_batch_rows:
            _upload_batch(table, columns, current_batch_rows, env)
            processed += len(current_batch_rows)
            print(f"\r      Uploaded {processed:,} / {count:,} rows...", end="")

    conn.close()
    print("\n\n🎉 Migration Complete!")

if __name__ == "__main__":
    upload_to_d1()
