import sqlite3
import os

DB_PATH = "assets/database/mediswitch.db"

def finalize_db():
    if not os.path.exists(DB_PATH):
        print("DB not found")
        return

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    print("🚀 Dropping old text columns to reclaim space...")

    # SQLite doesn't support DROP COLUMN in older versions easily, but recent ones do.
    # We'll assume standard DROP COLUMN support.
    
    cols_to_drop = {
        "drug_interactions": ["management_text", "mechanism_text", "recommendation", "effect"],
        "food_interactions": ["management_text", "mechanism_text", "interaction"],
        "disease_interactions": ["interaction_text"]
    }

    for table, cols in cols_to_drop.items():
        print(f"📦 Table: {table}")
        for col in cols:
            print(f"  - Dropping {col}...")
            try:
                cursor.execute(f"ALTER TABLE {table} DROP COLUMN {col}")
            except sqlite3.OperationalError as e:
                print(f"    Error dropping {col}: {e}")

    conn.commit()
    
    print("\n⏳ Running VACUUM...")
    original_isolation = conn.isolation_level
    conn.isolation_level = None
    conn.execute("VACUUM")
    conn.isolation_level = original_isolation
    print("✅ VACUUM complete.")

    conn.close()

if __name__ == "__main__":
    finalize_db()
