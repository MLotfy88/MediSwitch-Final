#!/usr/bin/env python3
"""
Quick migration script to add V16 enriched columns to existing mediswitch.db
"""
import sqlite3

DB_PATH = "mediswitch.db"

def migrate_to_v16():
    print("🔧 Migrating mediswitch.db to V16 schema...")
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    
    try:
        # 1. Drugs table
        print("  📦 Adding enriched columns to drugs table...")
        try:
            c.execute("ALTER TABLE drugs ADD COLUMN description TEXT")
            print("    ✅ Added description")
        except sqlite3.OperationalError as e:
            print(f"    ⚠️ description: {e}")
        
        try:
            c.execute("ALTER TABLE drugs ADD COLUMN atc_codes TEXT")
            print("    ✅ Added atc_codes")
        except sqlite3.OperationalError as e:
            print(f"    ⚠️ atc_codes: {e}")
        
        try:
            c.execute("ALTER TABLE drugs ADD COLUMN external_links TEXT")
            print("    ✅ Added external_links")
        except sqlite3.OperationalError as e:
            print(f"    ⚠️ external_links: {e}")
        
        # 2. Drug Interactions table
        print("  🧪 Adding enriched columns to drug_interactions table...")
        try:
            c.execute("ALTER TABLE drug_interactions ADD COLUMN metabolism_info TEXT")
            print("    ✅ Added metabolism_info")
        except sqlite3.OperationalError as e:
            print(f"    ⚠️ metabolism_info: {e}")
        
        try:
            c.execute("ALTER TABLE drug_interactions ADD COLUMN source_url TEXT")
            print("    ✅ Added source_url")
        except sqlite3.OperationalError as e:
            print(f"    ⚠️ source_url: {e}")
        
        try:
            c.execute("ALTER TABLE drug_interactions ADD COLUMN reference_text TEXT")
            print("    ✅ Added reference_text")
        except sqlite3.OperationalError as e:
            print(f"    ⚠️ reference_text: {e}")
        
        # 3. Food Interactions table
        print("  🍎 Adding enriched columns to food_interactions table...")
        try:
            c.execute("ALTER TABLE food_interactions ADD COLUMN ingredient TEXT")
            print("    ✅ Added ingredient")
        except sqlite3.OperationalError as e:
            print(f"    ⚠️ ingredient: {e}")
        
        try:
            c.execute("ALTER TABLE food_interactions ADD COLUMN severity TEXT")
            print("    ✅ Added severity")
        except sqlite3.OperationalError as e:
            print(f"    ⚠️ severity: {e}")
        
        try:
            c.execute("ALTER TABLE food_interactions ADD COLUMN management_text TEXT")
            print("    ✅ Added management_text")
        except sqlite3.OperationalError as e:
            print(f"    ⚠️ management_text: {e}")
        
        try:
            c.execute("ALTER TABLE food_interactions ADD COLUMN mechanism_text TEXT")
            print("    ✅ Added mechanism_text")
        except sqlite3.OperationalError as e:
            print(f"    ⚠️ mechanism_text: {e}")
        
        try:
            c.execute("ALTER TABLE food_interactions ADD COLUMN reference_text TEXT")
            print("    ✅ Added reference_text")
        except sqlite3.OperationalError as e:
            print(f"    ⚠️ reference_text: {e}")
        
        try:
            c.execute("ALTER TABLE food_interactions ADD COLUMN created_at INTEGER DEFAULT 0")
            print("    ✅ Added created_at")
        except sqlite3.OperationalError as e:
            print(f"    ⚠️ created_at: {e}")
        
        # 4. Disease Interactions table
        print("  🏥 Adding enriched columns to disease_interactions table...")
        try:
            c.execute("ALTER TABLE disease_interactions ADD COLUMN reference_text TEXT")
            print("    ✅ Added reference_text")
        except sqlite3.OperationalError as e:
            print(f"    ⚠️ reference_text: {e}")
        
        try:
            c.execute("ALTER TABLE disease_interactions ADD COLUMN created_at INTEGER DEFAULT 0")
            print("    ✅ Added created_at")
        except sqlite3.OperationalError as e:
            print(f"    ⚠️ created_at: {e}")
        
        conn.commit()
        print("\n✅ Migration to V16 complete!")
        
    except Exception as e:
        print(f"\n❌ Migration failed: {e}")
        conn.rollback()
    finally:
        conn.close()

if __name__ == "__main__":
    migrate_to_v16()
