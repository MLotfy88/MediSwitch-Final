#!/usr/bin/env python3
"""
Export optimized mediswitch.db to chunked SQL files for D1 sync via GitHub Actions.
Updated to map local (camelCase) schema to D1 (snake_case) schema manually for drugs table.
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
    # Clear previous chunks for this base_name to avoid leftovers
    # (Actually better to just overwrite, but assuming user deleted old ones or clean slate)
    
    for i in range(0, len(rows), chunk_size):
        chunk = rows[i:i + chunk_size]
        filename = f"{base_name}_part_{chunk_index:03d}.sql"
        filepath = os.path.join(OUTPUT_DIR, filename)
        with open(filepath, 'w', encoding='utf-8') as f:
            for row in chunk:
                f.write(f"{header} {row};\n")
        print(f"   ✅ {filename} ({len(chunk)} rows)")
        chunk_index += 1

def export_drugs(conn):
    """
    Export drugs table with explicit mapping from local (camelCase) to D1 (snake_case).
    """
    print("\n📦 Exporting Drugs (Mapping camelCase -> snake_case)...")
    conn.row_factory = sqlite3.Row # Enable name access
    cursor = conn.cursor()
    
    # Check what columns we actually have in local DB
    cursor.execute("SELECT * FROM drugs LIMIT 1")
    row = cursor.fetchone()
    cols = row.keys()
    print(f"   Local Columns: {cols}")

    # Map D1 (Target) <- Local (Source)
    # Target Schema:
    # id, trade_name, arabic_name, price, old_price, category, active, company, 
    # dosage_form, dosage_form_ar, concentration, unit, usage, pharmacology, 
    # barcode, qr_code, visits, last_price_update, 
    # has_drug_interaction, has_food_interaction, has_disease_interaction

    # Prepare Query
    cursor.execute("SELECT * FROM drugs")
    
    header = """INSERT OR IGNORE INTO drugs (
        id, trade_name, arabic_name, price, old_price, category, active, company,
        dosage_form, dosage_form_ar, concentration, unit, usage, pharmacology,
        barcode, qr_code, visits, last_price_update,
        has_drug_interaction, has_food_interaction, has_disease_interaction
    ) VALUES"""
    
    sql_rows = []
    
    for row in cursor.fetchall():
        # strict mapping
        vals = [
            row['id'],
            row['tradeName'] if 'tradeName' in row.keys() else '',
            row['arabicName'] if 'arabicName' in row.keys() else '',
            row['price'],
            row['oldPrice'] if 'oldPrice' in row.keys() else '',
            row['category'], # 'mainCategory' is ignored!
            row['active'],
            row['company'],
            row['dosageForm'] if 'dosageForm' in row.keys() else '',
            row['dosageForm_ar'] if 'dosageForm_ar' in row.keys() else '',
            row['concentration'],
            row['unit'],
            row['usage'],
            row['description'] if 'description' in row.keys() else '', # Map description -> pharmacology? Or is there a pharmacology column? CHECK. DatabaseHelper says pharmacology. Local might be description or mechanism_of_action?
            # Let's check logic: MedicineModel.fromCsv maps row[12] to pharmacology AND description.
            # Local DB has 'indication', 'mechanism_of_action', 'pharmacodynamics'.
            # It also has 'description'.
            # Let's map 'description' to 'pharmacology' for now as closest match or empty.
            row['barcode'],
            '', # qr_code (not in local keys usually or named differently? 'imageUrl' exists. let's put empty for qr_code)
            row['visits'],
            row['lastPriceUpdate'] if 'lastPriceUpdate' in row.keys() else '',
            0, # has_drug_interaction (re-calc or set 0)
            0, # has_food_interaction
            0  # has_disease_interaction
        ]
        
        # Helper to safely get column even if missing
        def get_col(name):
            return row[name] if name in row.keys() else ''

        # Refined Mapping based on viewed schema
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
            get_col('indication') if get_col('indication') else get_col('description'), # Indication/Desc -> Pharmacology
            get_col('barcode'),
            '', # qr_code
            get_col('visits'),
            get_col('lastPriceUpdate'),
            0, 0, 0
        ]
        
        escaped_vals = [escape_sql(v) for v in vals]
        sql_rows.append(f"({', '.join(escaped_vals)})")
    
    print(f"   Total: {len(sql_rows):,} rows")
    write_chunked_sql("d1_import", header, sql_rows)

def export_drug_interactions(conn):
    """Export drug_interactions table"""
    print("\n📦 Exporting Drug Interactions...")
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM drug_interactions")
    columns = [desc[0] for desc in cursor.description]
    
    header = f"INSERT OR IGNORE INTO drug_interactions ({', '.join(columns)}) VALUES"
    sql_rows = []
    
    for row in cursor.fetchall():
        vals = [escape_sql(v) for v in row]
        sql_rows.append(f"({', '.join(vals)})")
    
    print(f"   Total: {len(sql_rows):,} rows")
    write_chunked_sql("d1_rules", header, sql_rows, chunk_size=300)

def export_disease_interactions(conn):
    """Export disease_interactions table (optimized)"""
    print("\n📦 Exporting Disease Interactions (Optimized)...")
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM disease_interactions")
    columns = [desc[0] for desc in cursor.description]
    
    header = f"INSERT OR IGNORE INTO disease_interactions ({', '.join(columns)}) VALUES"
    sql_rows = []
    
    for row in cursor.fetchall():
        vals = [escape_sql(v) for v in row]
        sql_rows.append(f"({', '.join(vals)})")
    
    print(f"   Total: {len(sql_rows):,} rows")
    write_chunked_sql("d1_disease", header, sql_rows)

def export_food_interactions(conn):
    """Export food_interactions table (optimized)"""
    print("\n📦 Exporting Food Interactions (Optimized)...")
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM food_interactions")
    columns = [desc[0] for desc in cursor.description]
    
    header = f"INSERT OR IGNORE INTO food_interactions ({', '.join(columns)}) VALUES"
    sql_rows = []
    
    for row in cursor.fetchall():
        vals = [escape_sql(v) for v in row]
        sql_rows.append(f"({', '.join(vals)})")
    
    print(f"   Total: {len(sql_rows):,} rows")
    write_chunked_sql("d1_food", header, sql_rows)

def export_dosage_guidelines(conn):
    """Export dosage_guidelines table"""
    print("\n📦 Exporting Dosage Guidelines...")
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM dosage_guidelines")
    columns = [desc[0] for desc in cursor.description]
    
    header = f"INSERT OR IGNORE INTO dosage_guidelines ({', '.join(columns)}) VALUES"
    sql_rows = []
    
    for row in cursor.fetchall():
        vals = [escape_sql(v) for v in row]
        sql_rows.append(f"({', '.join(vals)})")
    
    print(f"   Total: {len(sql_rows):,} rows")
    write_chunked_sql("d1_dosages", header, sql_rows)

def main():
    if not os.path.exists(DB_PATH):
        print(f"❌ Database not found: {DB_PATH}")
        return
    
    # Create output directory
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    print("🚀 Exporting MediSwitch Database to D1-Ready SQL Chunks (FIXED SCHEMA)")
    print("="*80)
    
    conn = sqlite3.connect(DB_PATH)
    
    try:
        export_drugs(conn)
        export_drug_interactions(conn)
        export_disease_interactions(conn)
        export_food_interactions(conn)
        export_dosage_guidelines(conn)
    finally:
        conn.close()
    
    print("\n" + "="*80)
    print(f"✅ Export Complete! Files saved to: {OUTPUT_DIR}/")

if __name__ == "__main__":
    main()
