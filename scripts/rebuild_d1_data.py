import sqlite3
import os
import binascii

# --- Configuration ---
CHUNK_DIR = "d1_sql_chunks"
BATCH_SIZE = 500 # Smaller batch for safety with BLOBs
DB_PATH = "assets/database/mediswitch.db"

def clean_sql_val(val):
    """Clean and format value for SQL INSERT"""
    if val is None: return "NULL"
    if isinstance(val, (int, float)): return str(val)
    if isinstance(val, bytes):
        # Convert binary to hex literal X'...'
        hex_str = binascii.hexlify(val).decode('utf-8')
        return f"X'{hex_str}'"
    
    # Text escaping
    txt = str(val)
    # Escape single quotes by doubling them
    safe_v = txt.replace("'", "''")
    return f"'{safe_v}'"

def write_chunk(table_name, alias, data_list, cols):
    """Write a batch of SQL INSERT statements"""
    if not data_list: return
    
    os.makedirs(CHUNK_DIR, exist_ok=True)
    
    total_len = len(data_list)
    print(f"  Writing {total_len} rows for {table_name}...")
    
    for i in range(0, total_len, BATCH_SIZE):
        chunk_idx = i // BATCH_SIZE
        batch = data_list[i:i + BATCH_SIZE]
        
        sql_lines = []
        for row in batch:
            # Row is a tuple/sqlite3.Row. Access by column name.
            vals = [clean_sql_val(row[col]) for col in cols]
            sql_lines.append(f"INSERT INTO {table_name} ({', '.join(cols)}) VALUES ({', '.join(vals)});")
        
        fname = f"{alias}_part_{chunk_idx:03d}.sql"
        with open(os.path.join(CHUNK_DIR, fname), "w", encoding="utf-8") as f:
            f.write("\n".join(sql_lines))
        # print(f"    Saved {fname}")

def export_from_db():
    if not os.path.exists(DB_PATH):
        print(f"❌ Database not found: {DB_PATH}")
        return
    
    print(f"🚀 Exporting data from {DB_PATH}...")
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    
    # Get all tables
    cursor = conn.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")
    tables = [r[0] for r in cursor.fetchall()]
    
    # Tables to skip or handle specially if needed
    # user logic says interactions moved to diff db? 
    # But current mediswitch.db (644MB) seems to have everything or is optimized?
    # The 'split_db' logic kept 'mediswitch.db' as the source. 
    # Check if interaction tables exist in current DB.
    
    for table in tables:
        if table == "android_metadata": continue
        
        print(f"\n📦 Processing table: {table}")
        
        # Get columns
        c = conn.execute(f"SELECT * FROM {table} LIMIT 1")
        cols = [description[0] for description in c.description]
        
        # Determine prefix for files
        prefix = f"d1_{table}"
        
        # Fetch data
        cur = conn.execute(f"SELECT * FROM {table}")
        
        # Fetch all is risky for 600MB? 
        # Iterate efficiently.
        batch = []
        chunk_idx = 0
        row_count = 0
        
        while True:
            # Fetch many
            rows = cur.fetchmany(BATCH_SIZE)
            if not rows: break
            
            write_chunk(table, prefix, rows, cols)
            row_count += len(rows)
            # Adjust offset/naming handled inside write_chunk? 
            # My write_chunk takes a LIST. I need to adapt logic to avoid loading ALL into memory.
            # Reworking write_chunk call.
        
        # Re-write loop to call write_chunk with proper indexing is hard if I chunk here.
        # Let's adapt `write_chunk` to take `rows` and `start_index`.
        
    conn.close()
    
    # WAIT. The original script loaded everything into RAM! 
    # 644MB might crash standard heavy heap.
    # Let's write a smarter loop here.

def smart_export():
    if not os.path.exists(DB_PATH):
        print(f"❌ Database not found: {DB_PATH}")
        return
    
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    
    cursor = conn.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")
    tables = [r[0] for r in cursor.fetchall()]
    
    # Create base directory
    # Clear existing chunks
    if os.path.exists(CHUNK_DIR):
        import shutil
        shutil.rmtree(CHUNK_DIR)
    
    os.makedirs(os.path.join(CHUNK_DIR, "main"), exist_ok=True)
    os.makedirs(os.path.join(CHUNK_DIR, "interactions"), exist_ok=True)
    
    INTERACTION_TABLES = ['drug_interactions', 'food_interactions', 'disease_interactions']

    for table in tables:
        if table == "android_metadata": continue
        print(f"\n📦 Exporting {table}...")
        
        # Determine target directory
        if table in INTERACTION_TABLES:
            target_dir = os.path.join(CHUNK_DIR, "interactions")
        else:
            target_dir = os.path.join(CHUNK_DIR, "main")

        # Dynamic Batch Size - Reduced for HEX literal overhead
        if table == "dosage_guidelines":
            current_batch_size = 10
        elif table in INTERACTION_TABLES:
            current_batch_size = 100
        else:
            current_batch_size = 200
        
        # Get columns
        c = conn.execute(f"SELECT * FROM {table} LIMIT 1")
        cols = [description[0] for description in c.description]
        
        cur = conn.execute(f"SELECT * FROM {table}")
        
        file_idx = 0
        
        while True:
            rows = cur.fetchmany(current_batch_size)
            if not rows:
                break
            
            sql_lines = []
            for row in rows:
                vals = [clean_sql_val(row[col]) for col in cols]
                sql_lines.append(f"INSERT OR REPLACE INTO {table} ({', '.join(cols)}) VALUES ({', '.join(vals)});")
            
            fname = f"d1_{table}_part_{file_idx:03d}.sql"
            with open(os.path.join(target_dir, fname), "w", encoding="utf-8") as f:
                f.write("\n".join(sql_lines))
            
            file_idx += 1
            print(f"  Saved {fname} ({len(rows)} rows) in {target_dir}")
            
    print("\n✅ Export complete!")

if __name__ == "__main__":
    smart_export()
