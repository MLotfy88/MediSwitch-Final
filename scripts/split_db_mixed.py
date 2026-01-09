import sqlite3
import os
import shutil

DB_PATH = "assets/database/mediswitch.db"
OUTPUT_DIR = "d1_sql_chunks"
MAX_FILE_SIZE_BYTES = 400 * 1024  # 400KB

# استراتيجية مختلفة لكل جدول
TABLE_STRATEGIES = {
    'drugs': 25,                    # دفعات 25 صف
    'dosage_guidelines': 1,         # صف واحد فقط (بيانات مضغوطة كبيرة)
    'drug_interactions': 10,        # دفعات 10 صفوف
    'disease_interactions': 15,     # دفعات 15 صف
    'food_interactions': 20,        # دفعات 20 صف
    'med_ingredients': 50,          # دفعات 50 صف (جدول صغير)
}

def split_db():
    if os.path.exists(OUTPUT_DIR):
        shutil.rmtree(OUTPUT_DIR)
    os.makedirs(OUTPUT_DIR)

    # Reconstruct DB from parts if missing (Critical for GitHub Actions)
    if not os.path.exists(DB_PATH) or os.path.getsize(DB_PATH) == 0:
        print(f"Main database {DB_PATH} not found or empty. Attempting to reconstruct from parts...")
        parts_dir = "assets/database/parts"
        if os.path.exists(parts_dir):
            parts = sorted([p for p in os.listdir(parts_dir) if p.startswith("mediswitch.db.part-")])
            if parts:
                print(f"Found {len(parts)} parts. Reassembling...")
                with open(DB_PATH, "wb") as outfile:
                    for part in parts:
                        part_path = os.path.join(parts_dir, part)
                        print(f"  Appending {part}...")
                        with open(part_path, "rb") as infile:
                            shutil.copyfileobj(infile, outfile)
                print(f"Reconstructed database size: {os.path.getsize(DB_PATH) / (1024*1024):.2f} MB")
            else:
                print(f"No parts found in {parts_dir}!")
        else:
            print(f"Parts directory {parts_dir} not found!")

    if not os.path.exists(DB_PATH) or os.path.getsize(DB_PATH) == 0:
        print("❌ Error: Could not find or reconstruct database!")
        return

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    # 1. Export Schema
    print("Generating schema...")
    cursor.execute("SELECT name, sql FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name != 'sqlite_sequence'")
    tables_schema = cursor.fetchall()
    
    with open(f"{OUTPUT_DIR}/0000_schema.sql", "w", encoding="utf-8") as f:
        for name, sql in tables_schema:
            if not sql: continue
            f.write(f"DROP TABLE IF EXISTS {name};\n")
            f.write(sql + ";\n\n")

    # 2. Export Data
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name != 'sqlite_sequence'")
    tables = [r[0] for r in cursor.fetchall()]

    file_counter = 1
    for table in tables:
        print(f"Processing table: {table}")
        
        # تحديد الاستراتيجية لهذا الجدول
        rows_per_insert = TABLE_STRATEGIES.get(table, 1)  # افتراضياً صف واحد
        print(f"  Strategy: {rows_per_insert} rows per INSERT")
        
        cursor.execute(f"SELECT COUNT(*) FROM {table}")
        count = cursor.fetchone()[0]
        
        cursor.execute(f"SELECT * FROM {table}")
        columns = [description[0] for description in cursor.description]
        col_list = ",".join(columns)

        current_file_size = 0
        current_file_content = []
        
        while True:
            rows = cursor.fetchmany(rows_per_insert)
            if not rows:
                break
            
            # توليد INSERT (فردي أو متعدد حسب الاستراتيجية)
            if rows_per_insert == 1:
                # صف واحد فقط
                row = rows[0]
                vals = []
                for val in row:
                    if val is None:
                        s = "NULL"
                    elif isinstance(val, (int, float)):
                        s = str(val)
                    elif isinstance(val, bytes):
                        s = f"x'{val.hex()}'"
                    else:
                        clean_val = str(val).replace("'", "''")
                        s = f"'{clean_val}'"
                    vals.append(s)
                insert_stmt = f"INSERT OR REPLACE INTO {table} ({col_list}) VALUES ({','.join(vals)});\n"
            else:
                # دفعات متعددة
                row_vals_list = []
                for row in rows:
                    vals = []
                    for val in row:
                        if val is None:
                            s = "NULL"
                        elif isinstance(val, (int, float)):
                            s = str(val)
                        elif isinstance(val, bytes):
                            s = f"x'{val.hex()}'"
                        else:
                            clean_val = str(val).replace("'", "''")
                            s = f"'{clean_val}'"
                        vals.append(s)
                    row_str = f"({','.join(vals)})"
                    row_vals_list.append(row_str)
                
                insert_stmt = f"INSERT OR REPLACE INTO {table} ({col_list}) VALUES {','.join(row_vals_list)};\n"
            
            stmt_size = len(insert_stmt)

            if current_file_size + stmt_size > MAX_FILE_SIZE_BYTES:
                # Flush current file
                chunk_file = f"{OUTPUT_DIR}/{file_counter:04d}_{table}.sql"
                with open(chunk_file, "w", encoding="utf-8") as f:
                    f.write("".join(current_file_content))
                print(f"  Created {chunk_file} ({current_file_size/1024:.1f} KB)")
                file_counter += 1
                current_file_content = []
                current_file_size = 0
            
            current_file_content.append(insert_stmt)
            current_file_size += stmt_size

        # Flush final file for this table
        if current_file_content:
            chunk_file = f"{OUTPUT_DIR}/{file_counter:04d}_{table}.sql"
            with open(chunk_file, "w", encoding="utf-8") as f:
                f.write("".join(current_file_content))
            print(f"  Created {chunk_file} ({current_file_size/1024:.1f} KB)")
            file_counter += 1

    conn.close()
    print(f"\n✅ Done! Generated {file_counter} files")

if __name__ == "__main__":
    split_db()
