
import sqlite3
import zlib
import json
import os

DB_PATH = '/home/adminlotfy/project/assets/database/mediswitch.db'

def check_db():
    print(f"Checking database at: {DB_PATH}")
    if not os.path.exists(DB_PATH):
        print("❌ Database file not found!")
        return

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    try:
        # Check if column exists
        cursor.execute("PRAGMA table_info(dosage_guidelines)")
        columns = [info[1] for info in cursor.fetchall()]
        if 'structured_dosage' not in columns:
            print("❌ Column 'structured_dosage' DOES NOT EXIST in dosage_guidelines table.")
            return
        else:
            print("✅ Column 'structured_dosage' exists.")

        # Check Dormicum data
        term = "Dormicum"
        cursor.execute("""
            SELECT id, instructions, structured_dosage 
            FROM dosage_guidelines 
            WHERE instructions LIKE ?
        """, (f"%{term}%",))
        
        row = cursor.fetchone()
        if not row:
            print(f"❌ No records found for {term} in dosage_guidelines.")
            
            # Try searching by ingredient (Midazolam) just in case
            print("Trying generic search 'Midazolam'...")
            cursor.execute("""
            SELECT id, instructions, structured_dosage 
            FROM dosage_guidelines 
            WHERE instructions LIKE ?
            """, ("%Midazolam%",))
            row = cursor.fetchone()

        if row:
            id, instructions, blob_data = row
            print(f"✅ Found Record ID: {id}")
            print(f"   Instructions snippet: {instructions[:50]}...")
            
            if blob_data:
                print(f"✅ structured_dosage HAS DATA ({len(blob_data)} bytes).")
                try:
                    decompressed = zlib.decompress(blob_data)
                    data = json.loads(decompressed)
                    print("✅ Successfully decompressed and parsed JSON.")
                    print(f"   Keys: {list(data.keys())}")
                    if 'ui_sections' in data:
                        print(f"   ui_sections found: {len(data['ui_sections'])} sections.")
                    else:
                        print("❌ 'ui_sections' key MISSING in JSON.")
                except Exception as e:
                    print(f"❌ Failed to decompress/parse structured_dosage: {e}")
            else:
                print("❌ structured_dosage is NULL or EMPTY.")
        else:
            print(f"❌ No records found for {term} or Midazolam.")

    except Exception as e:
        print(f"❌ Error querying database: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    check_db()
