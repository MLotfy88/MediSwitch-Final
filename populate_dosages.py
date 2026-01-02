import sqlite3
import json
import os

DB_PATH = "mediswitch.db"
JSON_PATH = "assets/data/dosage_guidelines.json"

def populate_dosages():
    if not os.path.exists(DB_PATH):
        print("❌ Database not found!")
        return
    if not os.path.exists(JSON_PATH):
        print("❌ JSON file not found!")
        return

    print(f"📦 Loading dosages from {JSON_PATH}...")
    with open(JSON_PATH, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    guidelines = data.get('dosage_guidelines', [])
    print(f"✅ Loaded {len(guidelines):,} records.")

    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    
    print("🧹 Clearing existing records (if any)...")
    c.execute("DELETE FROM dosage_guidelines")
    
    print("🚀 Inserting records...")
    sql = """
        INSERT INTO dosage_guidelines (
            med_id, dailymed_setid, min_dose, max_dose, frequency, 
            duration, instructions, condition, source, is_pediatric
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """
    
    batch = []
    count = 0
    for g in guidelines:
        batch.append((
            g.get('med_id'),
            g.get('dailymed_setid'),
            g.get('min_dose'),
            g.get('max_dose'),
            g.get('frequency'),
            g.get('duration'),
            g.get('instructions'),
            g.get('condition'),
            g.get('source'),
            1 if g.get('is_pediatric') else 0
        ))
        
        if len(batch) >= 5000:
            c.executemany(sql, batch)
            count += len(batch)
            batch = []
            print(f"   Inserted {count:,}...")
            
    if batch:
        c.executemany(sql, batch)
        count += len(batch)
        
    conn.commit()
    conn.close()
    print(f"🎉 Successfully populated {count:,} dosage guidelines.")

if __name__ == "__main__":
    populate_dosages()
