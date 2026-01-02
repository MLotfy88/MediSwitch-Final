#!/usr/bin/env python3
"""
Export standardized mediswitch.db to chunked SQL files for D1 sync.
Since the local DB is now standardized to snake_case, this script is a direct mirror.
"""
import sqlite3
import os

DB_PATH = "mediswitch.db"
OUTPUT_DIR = "d1_sql_chunks"
CHUNK_SIZE = 500  # Rows per file

def escape_sql(val):
    """Escape SQL values properly"""
    if val is None or val == '':
        return "NULL"
    if isinstance(val, (int, float)):
        return str(val)
    if isinstance(val, bool):
        return "1" if val else "0"
    val = str(val).replace("'", "''")
    return f"'{val}'"

def write_chunked_sql(base_name, header, rows, chunk_size=CHUNK_SIZE):
    """Write SQL rows to chunked files"""
    chunk_index = 0
    # Clear old chunks first
    for f in os.listdir(OUTPUT_DIR):
        if f.startswith(base_name) and f.endswith(".sql"):
            os.remove(os.path.join(OUTPUT_DIR, f))
            
    for i in range(0, len(rows), chunk_size):
        chunk = rows[i:i + chunk_size]
        filename = f"{base_name}_part_{chunk_index:03d}.sql"
        filepath = os.path.join(OUTPUT_DIR, filename)
        with open(filepath, 'w', encoding='utf-8') as f:
            for row in chunk:
                f.write(f"{header} {row};\n")
        chunk_index += 1
    print(f"   ✅ {base_name}: {len(rows)} rows in {chunk_index} chunks.")

def export_table(conn, table_name, base_name, columns=None, chunk_size=CHUNK_SIZE):
    """Generic table exporter"""
    print(f"📦 Exporting {table_name}...")
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    cursor.execute(f"SELECT * FROM {table_name}")
    
    # Get columns from cursor if not provided
    if not columns:
        columns = [desc[0] for desc in cursor.description]
    
    header = f"INSERT OR IGNORE INTO {table_name} ({', '.join(columns)}) VALUES"
    sql_rows = []
    
    for row in cursor.fetchall():
        vals = []
        for col in columns:
            vals.append(row[col] if col in row.keys() else None)
        sql_rows.append(f"({', '.join(escape_sql(v) for v in vals)})")
    
    write_chunked_sql(base_name, header, sql_rows, chunk_size)

def main():
    if not os.path.exists(DB_PATH):
        print(f"❌ Database not found: {DB_PATH}")
        return
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    try:
        # Standardized direct export
        export_table(conn, "drugs", "d1_import", columns=[
            "id", "trade_name", "arabic_name", "price", "old_price", "category",
            "active", "company", "dosage_form", "dosage_form_ar", "concentration",
            "unit", "usage", "pharmacology", "barcode", "qr_code", "visits",
            "last_price_update", "updated_at", "indication", "mechanism_of_action",
            "pharmacodynamics", "data_source_pharmacology", "has_drug_interaction",
            "has_food_interaction", "has_disease_interaction"
        ])
        
        export_table(conn, "drug_interactions", "d1_rules", chunk_size=300)
        export_table(conn, "med_ingredients", "d1_ingredients")
        export_table(conn, "food_interactions", "d1_food")
        export_table(conn, "disease_interactions", "d1_disease")
        export_table(conn, "dosage_guidelines", "d1_dosages")
        
    finally:
        conn.close()
    print("\n✅ Unified Export Complete!")

if __name__ == "__main__":
    main()
