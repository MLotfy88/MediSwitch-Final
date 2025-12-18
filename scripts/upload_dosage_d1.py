#!/usr/bin/env python3
"""
Export Dosage Guidelines to SQL for D1 Import
Generates: d1_dosages.sql
"""
import json
import sys
import os

def export_dosages_sql(json_path, output_path='d1_dosages.sql'):
    if not os.path.exists(json_path):
        print(f"❌ JSON file not found: {json_path}")
        return False
        
    try:
        with open(json_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print(f"❌ Error reading JSON: {e}")
        return False
        
    dosages = data.get('dosage_guidelines', [])
    print(f"📊 Found {len(dosages)} dosage guidelines")
    
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write("-- MediSwitch Dosage Guidelines Import\n\n")
        f.write("DROP TABLE IF EXISTS dosage_guidelines;\n")
        f.write("""CREATE TABLE dosage_guidelines (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    med_id INTEGER,
    min_dose REAL,
    max_dose REAL,
    frequency INTEGER,
    duration INTEGER,
    instructions TEXT,
    condition TEXT,
    source TEXT,
    is_pediatric BOOLEAN DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at INTEGER DEFAULT (strftime('%s', 'now'))
);\n\n""")
        
        if not dosages:
            print("⚠️ No dosages to export.")
            return True
            
        print("📝 Generating INSERT statements...")
        batch_size = 50
        batch = []
        
        for d in dosages:
            med_id = d.get('med_id')
            if not med_id: continue
            
            # Safe Value Extraction
            def sql_val(val):
                if val is None: return "NULL"
                if isinstance(val, str):
                    clean_val = val.replace("'", "''")
                    return f"'{clean_val}'"
                return str(val)
                
            def sql_bool(val):
                return "1" if val else "0"
            
            vals = [
                d.get('med_id'),
                d.get('min_dose'),
                d.get('max_dose'),
                d.get('frequency'),
                d.get('duration'),
                d.get('instructions'),
                d.get('condition'),
                d.get('source', 'DailyMed'),
                d.get('is_pediatric', False)
            ]
            
            # Format: (med_id, min, max, freq, dur, instr, cond, source, ped)
            v_str = f"({sql_val(vals[0])}, {sql_val(vals[1])}, {sql_val(vals[2])}, {sql_val(vals[3])}, {sql_val(vals[4])}, {sql_val(vals[5])}, {sql_val(vals[6])}, {sql_val(vals[7])}, {sql_bool(vals[8])})"
            batch.append(v_str)

            if len(batch) >= batch_size:
                f.write("INSERT INTO dosage_guidelines (med_id, min_dose, max_dose, frequency, duration, instructions, condition, source, is_pediatric) VALUES\n")
                f.write(",\n".join(batch))
                f.write(";\n\n")
                batch = []
        
        if batch:
            f.write("INSERT INTO dosage_guidelines (med_id, min_dose, max_dose, frequency, duration, instructions, condition, source, is_pediatric) VALUES\n")
            f.write(",\n".join(batch))
            f.write(";\n\n")
            
    print(f"✅ Exported to {output_path}")
    return True

if __name__ == "__main__":
    json_file = sys.argv[1] if len(sys.argv) > 1 else 'assets/data/dosage_guidelines.json'
    export_dosages_sql(json_file)
