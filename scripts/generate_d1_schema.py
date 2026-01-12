import sqlite3
import os

DB_PATH = 'assets/database/mediswitch.db'
OUTPUT_SCHEMA = 'cloudflare-worker/schema_generated.sql'

def generate_schema():
    if not os.path.exists(DB_PATH):
        print(f"Database not found: {DB_PATH}")
        return

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Get list of tables
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")
    tables = [r[0] for r in cursor.fetchall()]
    
    with open(OUTPUT_SCHEMA, 'w') as f:
        f.write("-- D1 Schema Generated from mediswitch.db\n")
        f.write("PRAGMA foreign_keys = OFF;\n\n")
        
        for table in tables:
            print(f"Processing table: {table}")
            f.write(f"DROP TABLE IF EXISTS {table};\n")
            
            # Get CREATE statement
            cursor.execute(f"SELECT sql FROM sqlite_master WHERE type='table' AND name='{table}'")
            create_sql = cursor.fetchone()[0]
            
            # Clean up: strict mode issues in D1? D1 is mostly SQLite compatible.
            # But sometimes 'AUTOINCREMENT' needs generic key handling.
            # usually fine.
            f.write(f"{create_sql};\n\n")
            
            # Indices
            cursor.execute(f"SELECT sql FROM sqlite_master WHERE type='index' AND tbl_name='{table}' AND sql IS NOT NULL")
            indices = cursor.fetchall()
            for idx in indices:
                f.write(f"{idx[0]};\n")
            f.write("\n")
            
    conn.close()
    print(f"Schema generated at {OUTPUT_SCHEMA}")

if __name__ == "__main__":
    generate_schema()
