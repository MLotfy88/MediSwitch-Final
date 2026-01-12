import sqlite3
import os
import shutil

SOURCE_DB = 'assets/database/mediswitch.db'
CORE_DB = 'assets/database/mediswitch_core.db'

def create_core_db():
    if not os.path.exists(SOURCE_DB):
        print(f"Source DB not found: {SOURCE_DB}")
        return

    if os.path.exists(CORE_DB):
        os.remove(CORE_DB)

    print(f"Creating Core DB from {SOURCE_DB}...")
    
    # 1. Copy source to core (to keep indices and structure easily)
    shutil.copy2(SOURCE_DB, CORE_DB)
    
    conn = sqlite3.connect(CORE_DB)
    cursor = conn.cursor()
    
    # 2. DROP Large tables
    tables_to_drop = [
        'drug_interactions', 
        'food_interactions', 
        'disease_interactions', 
        'dosage_guidelines'
    ]
    
    for table in tables_to_drop:
        print(f"Dropping {table} from Core DB...")
        cursor.execute(f"DROP TABLE IF EXISTS {table}")
    
    # 3. VACUUM to reclaim space
    print("Vacuuming Core DB...")
    cursor.execute("VACUUM")
    
    conn.commit()
    conn.close()
    
    core_size = os.path.getsize(CORE_DB) / (1024*1024)
    print(f"Core DB created successfully! Size: {core_size:.2f} MB")

if __name__ == "__main__":
    create_core_db()
