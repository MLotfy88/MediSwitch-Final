import sqlite3
import zlib
import os

DB_PATH = "assets/database/mediswitch.db"

def compress_column(cursor, table, text_col, blob_col):
    print(f"  Processing {table}: {text_col} -> {blob_col}...")
    
    # Check if blob column exists
    try:
        cursor.execute(f"ALTER TABLE {table} ADD COLUMN {blob_col} BLOB")
    except sqlite3.OperationalError:
        pass # Already exists
        
    cursor.execute(f"SELECT id, {text_col} FROM {table} WHERE {text_col} IS NOT NULL AND {text_col} != ''")
    rows = cursor.fetchall()
    
    updates = []
    for row in rows:
        row_id = row[0]
        text_val = row[1]
        try:
            if isinstance(text_val, str):
                compressed = zlib.compress(text_val.encode('utf-8'))
            elif isinstance(text_val, bytes):
                # Ensure we don't double compress if it's already a blob? 
                # For now, treat bytes as raw data needing compression unless we can detect otherwise.
                # But wait, why would text column have bytes? SQLite dynamic typing.
                # Assuming it is RAW bytes string.
                compressed = zlib.compress(text_val)
            else:
                # Int or other?
                compressed = zlib.compress(str(text_val).encode('utf-8'))
                
            updates.append((compressed, row_id))
        except Exception as e:
            print(f"Error compressing row {row_id}: {e}")
            
    print(f"    Compressing {len(updates)} rows...")
    cursor.executemany(f"UPDATE {table} SET {blob_col} = ? WHERE id = ?", updates)


def run_compression():
    if not os.path.exists(DB_PATH):
        print("DB not found")
        return

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    print("🚀 Starting Text Compression...")

    # 1. Drug Interactions
    # Columns to compress: management_text, mechanism_text, recommendation, effect, risk_level? (risk_level is short, skip)
    # Also arabic_effect, arabic_recommendation
    
    # We will compress larger text fields.
    tables_config = {
        "drug_interactions": [
            ("management_text", "management_text_blob"),
            ("mechanism_text", "mechanism_text_blob"),
            ("recommendation", "recommendation_blob"),
            ("effect", "effect_blob")
        ],
        "food_interactions": [
            ("management_text", "management_text_blob"),
            ("mechanism_text", "mechanism_text_blob"),
            ("interaction", "interaction_blob") 
        ],
        "disease_interactions": [
            ("interaction_text", "interaction_text_blob")
        ]
    }

    for table, cols in tables_config.items():
        print(f"\n📦 Table: {table}")
        for text_col, blob_col in cols:
            compress_column(cursor, table, text_col, blob_col)

    conn.commit()
    print("\n✅ Compression done. Now Verify manually before dropping columns.")
    conn.close()

if __name__ == "__main__":
    run_compression()
