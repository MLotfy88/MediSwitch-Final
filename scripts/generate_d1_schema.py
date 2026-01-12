import sqlite3
import os

DB_PATH = 'assets/database/mediswitch.db'
INTERACTION_TABLES = ['drug_interactions', 'food_interactions', 'disease_interactions']

def generate_schema():
    if not os.path.exists(DB_PATH):
        print(f"Database not found: {DB_PATH}")
        return

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Get list of tables
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")
    tables = [r[0] for r in cursor.fetchall()]
    
    main_schema_path = 'cloudflare-worker/schema_generated.sql'
    interactions_schema_path = 'cloudflare-worker/schema_interactions.sql'

    def write_table_schema(file_handle, table):
        print(f"Processing table: {table}")
        file_handle.write(f"DROP TABLE IF EXISTS {table};\n")
        
        # Get CREATE statement
        cursor.execute(f"SELECT sql FROM sqlite_master WHERE type='table' AND name='{table}'")
        create_sql = cursor.fetchone()[0]
        file_handle.write(f"{create_sql};\n\n")
        
        # Indices
        cursor.execute(f"SELECT sql FROM sqlite_master WHERE type='index' AND tbl_name='{table}' AND sql IS NOT NULL")
        indices = cursor.fetchall()
        for idx in indices:
            file_handle.write(f"{idx[0]};\n")
        file_handle.write("\n")

    with open(main_schema_path, 'w') as f_main, open(interactions_schema_path, 'w') as f_int:
        f_main.write("-- D1 Main Schema Generated from mediswitch.db\nPRAGMA foreign_keys = OFF;\n\n")
        f_int.write("-- D1 Interactions Schema Generated from mediswitch.db\nPRAGMA foreign_keys = OFF;\n\n")
        
        for table in tables:
            if table == 'android_metadata': continue
            if table in INTERACTION_TABLES:
                write_table_schema(f_int, table)
            else:
                write_table_schema(f_main, table)
            
    conn.close()
    print(f"Schemas generated: {main_schema_path}, {interactions_schema_path}")

if __name__ == "__main__":
    generate_schema()
