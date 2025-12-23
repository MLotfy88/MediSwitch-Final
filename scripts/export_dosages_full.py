#!/usr/bin/env python3
import json
import os
from datetime import datetime

def export_dosages_to_sql(json_file, output_prefix, chunk_size=5000):
    """
    Exports dosage_guidelines from JSON to multiple SQL files for D1.
    """
    if not os.path.exists(json_file):
        print(f"❌ File not found: {json_file}")
        return False

    print(f"📖 Reading dosages from {json_file}...")
    with open(json_file, 'r', encoding='utf-8') as f:
        try:
            data = json.load(f)
            records = data.get('dosage_guidelines', [])
        except Exception as e:
            print(f"❌ Error parsing JSON: {e}")
            return False

    total = len(records)
    print(f"📊 Found {total} dosage records.")

    if total == 0:
        print("⚠️ No records found to export.")
        return False

    # Create chunks
    for i in range(0, total, chunk_size):
        chunk = records[i:i + chunk_size]
        chunk_idx = (i // chunk_size) + 1
        output_file = f"{output_prefix}_{chunk_idx}.sql"

        with open(output_file, 'w', encoding='utf-8') as f:
            if chunk_idx == 1:
                f.write("-- MediSwitch Dosages Export - Part 1\n")
                f.write("DROP TABLE IF EXISTS dosage_guidelines;\n")
                f.write("""CREATE TABLE IF NOT EXISTS dosage_guidelines (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    med_id INTEGER NOT NULL,
    dailymed_setid TEXT,
    min_dose REAL,
    max_dose REAL,
    frequency INTEGER,
    duration INTEGER,
    instructions TEXT,
    condition TEXT,
    source TEXT,
    is_pediatric BOOLEAN,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);\n""")

            # Removed BEGIN TRANSACTION/COMMIT as D1 handles it automatically
            
            for r in chunk:
                # Escape values
                def esc(val):
                    if val is None: return "NULL"
                    if isinstance(val, bool): return "1" if val else "0"
                    if isinstance(val, (int, float)): return str(val)
                    s = str(val).replace("'", "''")
                    return f"'{s}'"

                med_id = r.get('med_id', 0)
                setid = esc(r.get('dailymed_setid'))
                min_d = esc(r.get('min_dose'))
                max_d = esc(r.get('max_dose'))
                freq = esc(r.get('frequency'))
                dur = esc(r.get('duration'))
                inst = esc(r.get('instructions'))
                cond = esc(r.get('condition'))
                src = esc(r.get('source'))
                ped = esc(r.get('is_pediatric'))

                sql = f"INSERT INTO dosage_guidelines (med_id, dailymed_setid, min_dose, max_dose, frequency, duration, instructions, condition, source, is_pediatric) VALUES ({med_id}, {setid}, {min_d}, {max_d}, {freq}, {dur}, {inst}, {cond}, {src}, {ped});\n"
                f.write(sql)

        print(f"✅ Generated {output_file} ({min(i + chunk_size, total)}/{total})")

    return True

if __name__ == "__main__":
    json_path = "assets/data/dosage_guidelines.json"
    output_p = "d1_dosages_part"
    
    # Using 10k chunk size for efficiency if Wrangler allows
    success = export_dosages_to_sql(json_path, output_p, chunk_size=10000)
    
    if success:
        print("\n🚀 All SQL files generated!")
        print("To sync to D1, run:")
        print("for f in d1_dosages_part_*.sql; do npx wrangler d1 execute mediswitsh-db --file=$f --remote; done")
    else:
        exit(1)
