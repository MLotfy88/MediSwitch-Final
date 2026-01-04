#!/usr/bin/env python3
"""
Verification Script: DB Assembly & Med Ingredients
"""
import sqlite3
import os
import sys

BASE_DIR = os.getcwd()

def assemble_db():
    print("  🧩 Assembling database from parts...")
    parts_dir = os.path.join(BASE_DIR, 'assets', 'database', 'parts')
    temp_db_path = os.path.join(BASE_DIR, 'verify_mediswitch.db')
    
    if os.path.exists(temp_db_path):
        os.remove(temp_db_path)
        
    parts = sorted([f for f in os.listdir(parts_dir) if f.startswith('mediswitch.db.part-')])
    print(f"     Found {len(parts)} parts.")
    
    with open(temp_db_path, 'wb') as outfile:
        for part in parts:
            part_path = os.path.join(parts_dir, part)
            with open(part_path, 'rb') as infile:
                outfile.write(infile.read())
                
    print(f"  ✅ Database assembled at {temp_db_path}")
    return temp_db_path

def main():
    print("🔍 Starting Verification...")
    try:
        db_path = assemble_db()
        
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # 1. Check Table Count
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='med_ingredients';")
        if not cursor.fetchone():
            print("❌ 'med_ingredients' table NOT FOUND!")
            sys.exit(1)
            
        print("✅ 'med_ingredients' table exists.")
        
        # 2. Count Rows
        cursor.execute("SELECT COUNT(*) FROM med_ingredients")
        count = cursor.fetchone()[0]
        print(f"✅ 'med_ingredients' contains {count:,} rows.")
        
        # 3. Sample Data
        print("\n🔍 Sample Data (First 5):")
        cursor.execute("SELECT * FROM med_ingredients LIMIT 5")
        for row in cursor.fetchall():
            print(f"   - {row}")
            
        conn.close()
        os.remove(db_path)
        
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
