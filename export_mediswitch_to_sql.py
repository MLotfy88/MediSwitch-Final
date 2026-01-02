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

def export_table(conn, table_name, base_name, columns=None, chunk_size=CHUNK_SIZE):
    """Generic table exporter with streaming to handle large tables"""
    print(f"📦 Exporting {table_name}...")
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    cursor.execute(f"SELECT * FROM {table_name}")
    
    # Get columns from cursor if not provided
    if not columns:
        columns = [desc[0] for desc in cursor.description]
    
    header = f"INSERT OR IGNORE INTO {table_name} ({', '.join(columns)}) VALUES"
    
    chunk_index = 0
    # Clear old chunks first
    for f in os.listdir(OUTPUT_DIR):
        if f.startswith(base_name) and f.endswith(".sql"):
            os.remove(os.path.join(OUTPUT_DIR, f))
            
    while True:
        rows = cursor.fetchmany(chunk_size)
        if not rows:
            break
            
        sql_rows = []
        for row in rows:
            vals = []
            for col in columns:
                vals.append(row[col] if col in row.keys() else None)
            sql_rows.append(f"({', '.join(escape_sql(v) for v in vals)})")
            
        filename = f"{base_name}_part_{chunk_index:03d}.sql"
        filepath = os.path.join(OUTPUT_DIR, filename)
        with open(filepath, 'w', encoding='utf-8') as f:
            for sql_row in sql_rows:
                f.write(f"{header} {sql_row};\n")
        
        chunk_index += 1
        if chunk_index % 100 == 0:
            print(f"   ... Processed {chunk_index} chunks for {table_name}")

    print(f"   ✅ {base_name}: Exported in {chunk_index} chunks.")

def main():
    if not os.path.exists(DB_PATH):
        print(f"❌ Database not found: {DB_PATH}")
        return
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    try:
        # 1. DRUGS (26 Columns)
        export_table(conn, "drugs", "d1_import", columns=[
            "id", "trade_name", "arabic_name", "price", "old_price", "category",
            "active", "company", "dosage_form", "dosage_form_ar", "concentration",
            "unit", "usage", "pharmacology", "barcode", "qr_code", "visits",
            "last_price_update", "updated_at", "indication", "mechanism_of_action",
            "pharmacodynamics", "data_source_pharmacology", "has_drug_interaction",
            "has_food_interaction", "has_disease_interaction", "description",
            "atc_codes", "external_links"
        ])

        # 2. DRUG INTERACTIONS (17 Columns)
        export_table(conn, "drug_interactions", "d1_rules", columns=[
            "id", "ingredient1", "ingredient2", "severity", "effect", "arabic_effect",
            "recommendation", "arabic_recommendation", "management_text", "mechanism_text",
            "alternatives_a", "alternatives_b", "risk_level", "ddinter_id", "source",
            "type", "metabolism_info", "source_url", "reference_text", "updated_at"
        ])

        # 3. DISEASE INTERACTIONS (8 Columns - removed phantom management/mechanism)
        export_table(conn, "disease_interactions", "d1_disease", columns=[
            "id", "med_id", "trade_name", "disease_name", "interaction_text", "severity", 
            "reference_text", "source", "created_at"
        ])

        # 4. FOOD INTERACTIONS (10 Columns - granular schema)
        export_table(conn, "food_interactions", "d1_food", columns=[
            "id", "med_id", "trade_name", "interaction", "ingredient", "severity", 
            "management_text", "mechanism_text", "reference_text", "source", "created_at"
        ])

        # 5. DOSAGE GUIDELINES (11 Columns)
        export_table(conn, "dosage_guidelines", "d1_dosages", columns=[
            "id", "med_id", "dailymed_setid", "min_dose", "max_dose", "frequency",
            "duration", "instructions", "condition", "source", "is_pediatric"
        ])

        # 6. MED INGREDIENTS (3 Columns)
        export_table(conn, "med_ingredients", "d1_ingredients", columns=[
            "med_id", "ingredient", "updated_at"
        ])

        print("\n✨ All tables exported with 100% explicit mapping!")
        
    finally:
        conn.close()
    print("\n✅ Unified Export Complete!")

if __name__ == "__main__":
    main()
