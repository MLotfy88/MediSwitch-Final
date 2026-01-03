import sqlite3
import os
import shutil

# --- Configuration ---
CHUNK_DIR = "d1_interactions_chunks"
BATCH_SIZE = 1000
DB_PATH = "mediswitch.db"

def clean_sql_val(val):
    """Sanitize values for SQL injection prevention and NULL handling"""
    if val is None or val == "": return "NULL"
    if isinstance(val, (int, float)): return str(val)
    # Escape single quotes
    safe_v = str(val).replace("'", "''")
    return f"'{safe_v}'"

def write_chunk(table_name, alias, data_list, cols):
    """Write data to chunked SQL files"""
    if not data_list: return
    
    os.makedirs(CHUNK_DIR, exist_ok=True)
    
    for i in range(0, len(data_list), BATCH_SIZE):
        chunk_idx = i // BATCH_SIZE
        batch = data_list[i:i + BATCH_SIZE]
        
        sql_lines = []
        for row in batch:
            # Ensure strict column order mapping
            vals = [clean_sql_val(row.get(col)) for col in cols]
            sql_lines.append(f"INSERT OR REPLACE INTO {table_name} ({', '.join(cols)}) VALUES ({', '.join(vals)});")
        
        fname = f"{alias}_part_{chunk_idx:03d}.sql"
        with open(os.path.join(CHUNK_DIR, fname), "w", encoding="utf-8") as f:
            f.write("\n".join(sql_lines))
        print(f"  ✓ Processed {fname}: {len(batch):,} records")

def migrate_interactions():
    """Export only interaction tables for the new Split D1 Database"""
    
    if not os.path.exists(DB_PATH):
        print(f"❌ Database not found: {DB_PATH}")
        return
    
    # Clean previous chunks
    if os.path.exists(CHUNK_DIR):
        shutil.rmtree(CHUNK_DIR)
    os.makedirs(CHUNK_DIR)
    
    print("🚀 Starting Interaction Data Migration...")
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    
    # 1. Drug Interactions (The Heavy One)
    print("\n🧪 Exporting Drug Interactions...")
    cursor = conn.execute("SELECT * FROM drug_interactions")
    interactions = [dict(row) for row in cursor.fetchall()]
    # Schema must match interactions_db_schema.sql EXACTLY
    interaction_cols = ['id', 'ingredient1', 'ingredient2', 'severity', 'effect', 'source', 
                        'management_text', 'mechanism_text', 'recommendation', 'risk_level', 
                        'type', 'metabolism_info', 'source_url', 'reference_text', 
                        'alternatives_a', 'alternatives_b', 'updated_at']
    
    write_chunk("drug_interactions", "interactions", interactions, interaction_cols)
    
    # 2. Food Interactions
    print("\n🍎 Exporting Food Interactions...")
    cursor = conn.execute("SELECT * FROM food_interactions")
    food = [dict(row) for row in cursor.fetchall()]
    food_cols = ['id', 'med_id', 'trade_name', 'interaction', 'ingredient', 'severity', 
                 'management_text', 'mechanism_text', 'reference_text', 'source', 'created_at']
    write_chunk("food_interactions", "food", food, food_cols)
    
    # 3. Disease Interactions
    print("\n🏥 Exporting Disease Interactions...")
    cursor = conn.execute("SELECT * FROM disease_interactions")
    disease = [dict(row) for row in cursor.fetchall()]
    disease_cols = ['id', 'med_id', 'trade_name', 'disease_name', 'interaction_text', 
                    'severity', 'reference_text', 'source', 'created_at']
    write_chunk("disease_interactions", "disease", disease, disease_cols)
    
    conn.close()
    print("\n✅ Migration Export Complete!")
    print(f"📂 SQL Chunks ready in: {CHUNK_DIR}/")

if __name__ == "__main__":
    migrate_interactions()
