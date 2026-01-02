#!/usr/bin/env python3
"""
Export optimized mediswitch.db to chunked SQL files for D1 sync.
STRICT EXPLICIT MAPPING to prevent schema mismatch errors.
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
    for i in range(0, len(rows), chunk_size):
        chunk = rows[i:i + chunk_size]
        filename = f"{base_name}_part_{chunk_index:03d}.sql"
        filepath = os.path.join(OUTPUT_DIR, filename)
        with open(filepath, 'w', encoding='utf-8') as f:
            for row in chunk:
                f.write(f"{header} {row};\n")
        chunk_index += 1
    print(f"   ✅ {base_name}: {len(rows)} rows in {chunk_index} chunks.")

def export_drugs(conn):
    print("📦 Exporting Drugs (Strict Mapping)...")
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM drugs")
    
    header = """INSERT OR IGNORE INTO drugs (
        id, trade_name, arabic_name, price, old_price, category, active, company,
        dosage_form, dosage_form_ar, concentration, unit, usage, pharmacology,
        barcode, qr_code, visits, last_price_update,
        has_drug_interaction, has_food_interaction, has_disease_interaction
    ) VALUES"""
    
    sql_rows = []
    for row in cursor.fetchall():
        def get_col(names):
            if isinstance(names, str): names = [names]
            for name in names:
                if name in row.keys(): return row[name]
            return None

        vals = [
            get_col('id'),
            get_col('tradeName'),
            get_col('arabicName'),
            get_col('price'),
            get_col('oldPrice'),
            get_col('category'),
            get_col('active'),
            get_col('company'),
            get_col('dosageForm'),
            get_col('dosageForm_ar'),
            get_col('concentration'),
            get_col('unit'),
            get_col('usage'),
            get_col(['indication', 'description', 'pharmacology']),
            get_col('barcode'),
            get_col(['qrCode', 'imageUrl']),
            get_col('visits') or 0,
            get_col('lastPriceUpdate'),
            0, 0, 0 # Interaction flags
        ]
        sql_rows.append(f"({', '.join(escape_sql(v) for v in vals)})")
    write_chunked_sql("d1_import", header, sql_rows)

def export_drug_interactions(conn):
    print("📦 Exporting Drug Interactions (Strict Mapping)...")
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM drug_interactions")
    
    header = """INSERT OR IGNORE INTO drug_interactions (
        id, ingredient1, ingredient2, severity, effect, arabic_effect,
        recommendation, arabic_recommendation, management_text, mechanism_text,
        alternatives_a, alternatives_b, risk_level, ddinter_id, source, type, updated_at
    ) VALUES"""
    
    sql_rows = []
    for row in cursor.fetchall():
        def get_col(name):
            return row[name] if name in row.keys() else None

        vals = [
            get_col('id'),
            get_col('ingredient1'),
            get_col('ingredient2'),
            get_col('severity'),
            get_col('effect'),
            get_col('arabic_effect'),
            get_col('recommendation'),
            get_col('arabic_recommendation'),
            get_col('management_text'),
            get_col('mechanism_text'),
            get_col('alternatives_a'), # NULL if missing
            get_col('alternatives_b'), # NULL if missing
            get_col('risk_level'),
            get_col('ddinter_id'),
            get_col('source') or 'DailyMed',
            get_col('type') or 'pharmacodynamic',
            get_col('updated_at') or 0
        ]
        sql_rows.append(f"({', '.join(escape_sql(v) for v in vals)})")
    write_chunked_sql("d1_rules", header, sql_rows, chunk_size=300)

def export_med_ingredients(conn):
    print("📦 Exporting Med Ingredients (Strict Mapping)...")
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM med_ingredients")
    
    header = "INSERT OR IGNORE INTO med_ingredients (med_id, ingredient, updated_at) VALUES"
    sql_rows = []
    for row in cursor.fetchall():
        vals = [row['med_id'], row['ingredient'], 0]
        sql_rows.append(f"({', '.join(escape_sql(v) for v in vals)})")
    write_chunked_sql("d1_ingredients", header, sql_rows)

def export_food_interactions(conn):
    print("📦 Exporting Food Interactions (Strict Mapping)...")
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM food_interactions")
    
    header = "INSERT OR IGNORE INTO food_interactions (id, med_id, trade_name, interaction, source) VALUES"
    sql_rows = []
    for row in cursor.fetchall():
        def get_col(name): return row[name] if name in row.keys() else None
        
        vals = [
            get_col('id'),
            get_col('med_id'),
            get_col('trade_name'),
            get_col('interaction') if 'interaction' in row.keys() else get_col('interaction_text'),
            get_col('source') or 'DrugBank'
        ]
        sql_rows.append(f"({', '.join(escape_sql(v) for v in vals)})")
    write_chunked_sql("d1_food", header, sql_rows)

def export_disease_interactions(conn):
    print("📦 Exporting Disease Interactions (Strict Mapping)...")
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM disease_interactions")
    
    header = "INSERT OR IGNORE INTO disease_interactions (id, med_id, trade_name, disease_name, interaction_text, severity, source) VALUES"
    sql_rows = []
    for row in cursor.fetchall():
        def get_col(name): return row[name] if name in row.keys() else None
        
        vals = [
            get_col('id'),
            get_col('med_id'),
            get_col('trade_name'),
            get_col('disease_name'),
            get_col('interaction_text'),
            get_col('severity'),
            get_col('source') or 'DDInter'
        ]
        sql_rows.append(f"({', '.join(escape_sql(v) for v in vals)})")
    write_chunked_sql("d1_disease", header, sql_rows)

def export_dosage_guidelines(conn):
    print("📦 Exporting Dosage Guidelines (Strict Mapping)...")
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM dosage_guidelines")
    
    header = """INSERT OR IGNORE INTO dosage_guidelines (
        id, med_id, dailymed_setid, min_dose, max_dose, frequency,
        duration, instructions, condition, source, is_pediatric
    ) VALUES"""
    
    sql_rows = []
    for row in cursor.fetchall():
        def get_col(name): return row[name] if name in row.keys() else None
        
        vals = [
            get_col('id'),
            get_col('med_id'),
            get_col('dailymed_setid'),
            get_col('min_dose'),
            get_col('max_dose'),
            get_col('frequency'),
            get_col('duration'),
            get_col('instructions'),
            get_col('condition'),
            get_col('source'),
            get_col('is_pediatric')
        ]
        sql_rows.append(f"({', '.join(escape_sql(v) for v in vals)})")
    write_chunked_sql("d1_dosages", header, sql_rows)

def main():
    if not os.path.exists(DB_PATH):
        print(f"❌ Database not found: {DB_PATH}")
        return
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    try:
        export_drugs(conn)
        export_drug_interactions(conn)
        export_med_ingredients(conn)
        export_disease_interactions(conn)
        export_food_interactions(conn)
        export_dosage_guidelines(conn)
    finally:
        conn.close()
    print("\n✅ Export Complete! All chunks generated with STRICT mapping.")

if __name__ == "__main__":
    main()
