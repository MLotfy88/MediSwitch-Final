#!/usr/bin/env python3
"""
Export Dosage Guidelines to SQL for D1 Import
Generates: d1_dosages.sql
"""
import json
import sys
import os
import gzip  # Import gzip

def load_json(file_path):
    """Load JSON from file (supports .gz)"""
    try:
        if file_path.endswith('.gz'):
            with gzip.open(file_path, 'rt', encoding='utf-8') as f:
                return json.load(f)
        else:
            with open(file_path, 'r', encoding='utf-8') as f:
                return json.load(f)
    except Exception as e:
        print(f"❌ Error loading {file_path}: {e}")
        return []

def export_dosages_sql(json_path, output_path='d1_dosages.sql'):
    if not os.path.exists(json_path):
        print(f"❌ JSON file not found: {json_path}")
        return False
        
    data = load_json(json_path)
    if not data: # load_json returns [] on error
        return False
        
    if isinstance(data, list):
        dosages = data
    else:
        dosages = data.get('dosage_guidelines', [])
    
    print(f"📊 Found {len(dosages)} dosage guidelines")
    
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write("-- MediSwitch Dosage Guidelines Import\n\n")
        f.write("DROP TABLE IF EXISTS dosage_guidelines;\n")
        f.write("""CREATE TABLE dosage_guidelines (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    med_id INTEGER,
    dailymed_setid TEXT,
    min_dose REAL,
    max_dose REAL,
    frequency INTEGER,
    duration INTEGER,
    instructions TEXT,
    condition TEXT,
    source TEXT,
    is_pediatric INTEGER,
    active_ingredient TEXT,
    strength TEXT,
    standard_dose TEXT,
    package_label TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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
                d.get('dailymed_setid'),
                d.get('min_dose'),
                d.get('max_dose'),
                d.get('frequency'),
                d.get('duration'),
                d.get('instructions'),
                d.get('condition'),
                d.get('source', 'DailyMed'),
                d.get('is_pediatric', False)
            ]
            
            # Format: (med_id, dailymed, min, max, freq, dur, instr, cond, source, ped)
            # Extra fields set to NULL
            v_str = f"({sql_val(vals[0])}, {sql_val(vals[1])}, {sql_val(vals[2])}, {sql_val(vals[3])}, {sql_val(vals[4])}, {sql_val(vals[5])}, {sql_val(vals[6])}, {sql_val(vals[7])}, {sql_val(vals[8])}, {sql_bool(vals[9])}, NULL, NULL, NULL, NULL)"
            batch.append(v_str)

            if len(batch) >= batch_size:
                f.write("INSERT INTO dosage_guidelines (med_id, dailymed_setid, min_dose, max_dose, frequency, duration, instructions, condition, source, is_pediatric, active_ingredient, strength, standard_dose, package_label) VALUES\n")
                f.write(",\n".join(batch))
                f.write(";\n\n")
                batch = []
        
        if batch:
            f.write("INSERT INTO dosage_guidelines (med_id, dailymed_setid, min_dose, max_dose, frequency, duration, instructions, condition, source, is_pediatric, active_ingredient, strength, standard_dose, package_label) VALUES\n")
            f.write(",\n".join(batch))
            f.write(";\n\n")
            
    print(f"✅ Exported to {output_path}")
    return True

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='Export dosages to SQL for D1')
    parser.add_argument('--json-file', default='assets/data/dosage_guidelines.json.gz', help='Input JSON file')
    # Add other arguments expected by workflow to avoid errors, even if unused for now
    parser.add_argument('--database-id', help='D1 Database ID')
    parser.add_argument('--account-id', help='Cloudflare Account ID')
    parser.add_argument('--api-token', help='Cloudflare API Token')
    
    args = parser.parse_args()
    
    export_dosages_sql(args.json_file)
