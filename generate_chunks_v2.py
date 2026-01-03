import sqlite3
import os

DB_PATH = "/home/adminlotfy/project/assets/database/mediswitch.db"
OUTPUT_DIR = "d1_upload_chunks_new"
CHUNK_SIZE = 100  # Smaller size for stability

if not os.path.exists(OUTPUT_DIR):
    os.makedirs(OUTPUT_DIR)

def generate_chunks(table_name):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Get column names
    cursor.execute(f"PRAGMA table_info({table_name})")
    cols = [col[1] for col in cursor.execute(f"PRAGMA table_info({table_name})").fetchall()]
    col_str = ", ".join(cols)
    
    cursor.execute(f"SELECT count(*) FROM {table_name}")
    total = cursor.fetchone()[0]
    print(f"Generating chunks for {table_name} ({total} rows)...")
    
    for i in range(0, total, CHUNK_SIZE):
        cursor.execute(f"SELECT * FROM {table_name} LIMIT ? OFFSET ?", (CHUNK_SIZE, i))
        rows = cursor.fetchall()
        
        chunk_file = os.path.join(OUTPUT_DIR, f"{table_name}_{i//CHUNK_SIZE:05d}.sql")
        with open(chunk_file, "w") as f:
            for row in rows:
                # Escape strings
                vals = []
                for v in row:
                    if v is None:
                        vals.append("NULL")
                    elif isinstance(v, str):
                        vals.append("'" + v.replace("'", "''") + "'")
                    else:
                        vals.append(str(v))
                f.write(f"INSERT OR IGNORE INTO {table_name} ({col_str}) VALUES ({', '.join(vals)});\n")
            
    conn.close()

# Generate for remaining tables
generate_chunks("disease_interactions")
generate_chunks("drug_interactions")
print("Done!")
