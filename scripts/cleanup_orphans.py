import sqlite3
import os

DB_PATH = "assets/database/mediswitch.db"

def cleanup_orphans():
    if not os.path.exists(DB_PATH):
        print(f"❌ Database not found: {DB_PATH}")
        return

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    print(f"🧹 Starting Database Cleanup: {DB_PATH}\n")

    # 1. Clean Disease Interactions
    print("--- Cleaning Disease Interactions ---")
    cursor.execute("""
        DELETE FROM disease_interactions 
        WHERE med_id NOT IN (SELECT id FROM drugs)
    """)
    rows_deleted = cursor.rowcount
    print(f"✅ Deleted {rows_deleted} orphan disease interactions.")

    # 2. Clean Food Interactions
    print("\n--- Cleaning Food Interactions ---")
    cursor.execute("""
        DELETE FROM food_interactions 
        WHERE med_id NOT IN (SELECT id FROM drugs)
    """)
    rows_deleted = cursor.rowcount
    print(f"✅ Deleted {rows_deleted} orphan food interactions.")

    # 3. Clean Drug Interactions
    print("\n--- Cleaning Drug Interactions ---")
    # Using the strict definition: Delete if NEITHER ingredient exists in our system
    cursor.execute("""
        DELETE FROM drug_interactions 
        WHERE 
            LOWER(TRIM(ingredient1)) NOT IN (SELECT LOWER(TRIM(ingredient)) FROM med_ingredients)
            AND 
            LOWER(TRIM(ingredient2)) NOT IN (SELECT LOWER(TRIM(ingredient)) FROM med_ingredients)
    """)
    rows_deleted = cursor.rowcount
    print(f"✅ Deleted {rows_deleted} orphan drug interactions.")

    print("\n-----------------------------------")
    conn.commit() # Commit deletions first
    
    print("⏳ Running VACUUM to reclaim disk space...")
    # VACUUM cannot run in a transaction, so we need to ensure autocommit
    original_isolation = conn.isolation_level
    conn.isolation_level = None 
    conn.execute("VACUUM")
    conn.isolation_level = original_isolation
    print("✅ VACUUM complete.")

    conn.close()
    
    print("\n🎉 Cleanup finished successfully!")

if __name__ == "__main__":
    cleanup_orphans()
