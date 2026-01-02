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
DB_PATH = "mediswitch.db"
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

    # 1. Upload Schema (Statement by Statement)
    print("\n📋 Step 1: Creating Schema (Statement by Statement)...")
    schema_file = "d1_migration_sql/01_schema.sql"
    if os.path.exists(schema_file):
        with open(schema_file, 'r', encoding='utf-8') as f:
            full_sql = f.read()
        
        # Split by semicolon but be careful about triggers/quotes (simple split works for simple schema)
        statements = [s.strip() for s in full_sql.split(';') if s.strip()]
        
        for i, sql in enumerate(statements):
            # Skip comments
            if sql.startswith('--'):
                continue
            
            # Escape quotes for command line (basic)
            # Wrangler --command accepts string. 
            # Best to use a temporary file for each statement if it's complex? 
            # Or just try --command.
            # SQL contains newlines, better to put in temp file.
            
            temp_stmt_file = f"temp_schema_{i}.sql"
            with open(temp_stmt_file, 'w') as tf:
                tf.write(sql + ";")
            
            print(f"   🔨 Executing Statement {i+1}...")
            cmd = f"npx wrangler d1 execute {DATABASE_NAME} --file={temp_stmt_file} --remote"
            success, output = run_command(cmd, env)
            
            if success:
                print(f"      ✅ Success")
            else:
                print(f"      ❌ Failed: {output[:100]}...")
                # Dont stop, try next
            
            if os.path.exists(temp_stmt_file):
                os.remove(temp_stmt_file)
            
    else:
        print("   ❌ Schema file not found.")

    # 2. Upload Data
    print("\n📦 Step 2: Uploading Data...")
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Get tables
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")
    tables = [r[0] for r in cursor.fetchall()]
    
    for table in tables:
        print(f"\n   Processing table: {table}")
        
        # No need to clear remote table if we just dropped and recreated it
        
        cursor.execute(f"SELECT COUNT(*) FROM {table}")
        count = cursor.fetchone()[0]
        print(f"   Rows: {count:,}")
        
        cursor.execute(f"SELECT * FROM {table}")
        columns = [description[0] for description in cursor.description]
        
        chunk = []
        processed = 0
        
        while True:
            rows = cursor.fetchmany(CHUNK_SIZE)
            if not rows:
                break
                
            # Build SQL INSERT batch
            values_list = []
            for row in rows:
                # Sanitize values
                formatted_values = []
                for val in row:
                    if val is None:
                        formatted_values.append("NULL")
                    elif isinstance(val, (int, float)):
                        formatted_values.append(str(val))
                    else:
                        # Escape single quotes
                        clean_val = str(val).replace("'", "''")
                        formatted_values.append(f"'{clean_val}'")
                values_list.append(f"({','.join(formatted_values)})")
            
            sql = f"INSERT INTO {table} ({','.join(columns)}) VALUES {','.join(values_list)};"
            
            # Write to temp file
            with open("temp_batch.sql", "w", encoding="utf-8") as f:
                f.write(sql)
            
            # Execute with retry logic
            for attempt in range(MAX_RETRIES):
                cmd = f"npx wrangler d1 execute {DATABASE_NAME} --file=temp_batch.sql --remote"
                success, output = run_command(cmd, env)
                if success:
                    processed += len(rows)
                    print(f"\r      Uploaded {processed:,} / {count:,} rows...", end="")
                    break
                else:
                    if attempt == MAX_RETRIES - 1:
                        print(f"\n      ❌ Failed batch after {MAX_RETRIES} attempts. Error: {output[:100]}...")
                    else:
                        time.sleep(2) # Wait before retry
            
            # Clean up
            if os.path.exists("temp_batch.sql"):
                os.remove("temp_batch.sql")

    conn.close()
    print("\n\n🎉 Migration Complete!")

if __name__ == "__main__":
    upload_to_d1()
