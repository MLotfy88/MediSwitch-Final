#!/usr/bin/env python3
"""
Export optimized mediswitch.db to chunked SQL files for D1 sync via GitHub Actions.
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
        print(f"   ✅ {filename} ({len(chunk)} rows)")
        chunk_index += 1

def export_drugs(conn):
    """Export drugs table"""
    print("\n📦 Exporting Drugs...")
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM drugs")
    columns = [desc[0] for desc in cursor.description]
    
    header = f"INSERT OR IGNORE INTO drugs ({', '.join(columns)}) VALUES"
    sql_rows = []
    
    for row in cursor.fetchall():
        vals = [escape_sql(v) for v in row]
        sql_rows.append(f"({', '.join(vals)})")
    
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
    
    print("🚀 Exporting MediSwitch Database to D1-Ready SQL Chunks")
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
    print("="*80)
    print("\n📋 Next Steps:")
    print("   1. Review the generated SQL files")
    print("   2. Commit and push them to GitHub:")
    print(f"      git add {OUTPUT_DIR}/")
    print("      git commit -m 'Add D1 SQL chunks from optimized database'")
    print("      git push")
    print("   3. Trigger the GitHub Action 'sync-d1.yml'")

if __name__ == "__main__":
    main()
