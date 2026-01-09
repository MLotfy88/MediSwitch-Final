import sqlite3
import os
import shutil

DB_PATH = "assets/database/mediswitch.db"
OUTPUT_DIR = "d1_sql_chunks"
MAX_FILE_SIZE_BYTES = 400 * 1024 # 400KB لتجنب مشاكل D1_RESET
ROWS_PER_INSERT = 25 # دفعات صغيرة للسرعة والاستقرار

def split_db():
    if os.path.exists(OUTPUT_DIR):
        shutil.rmtree(OUTPUT_DIR)
    os.makedirs(OUTPUT_DIR)

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
        cursor.execute(f"SELECT COUNT(*) FROM {table}")
        count = cursor.fetchone()[0]
        
        cursor.execute(f"SELECT * FROM {table}")
        columns = [description[0] for description in cursor.description]
        col_list = ",".join(columns)

        current_file_size = 0
        current_file_content = []
        
        while True:
            rows = cursor.fetchmany(ROWS_PER_INSERT)
            if not rows:
                break
            
            # توليد INSERT متعدد الصفوف لهذه الدفعة
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
    print("Done!")

if __name__ == "__main__":
    split_db()
