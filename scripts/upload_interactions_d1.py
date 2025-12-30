#!/usr/bin/env python3
"""
Export Drug Interactions to SQL for D1 Import (Chunked)
Generates: d1_interactions_part_X.sql
"""
import json
import sys
import os
import math

import glob

def export_interactions_sql(json_path, output_dir='.', chunk_size=3000):
    if not os.path.exists(json_path):
        print(f"❌ Path not found: {json_path}")
        return False
        
    generated_files = []
    
    # --- 1. Process Rules (drug_interactions table) ---
    rules_files = sorted(glob.glob(os.path.join(json_path, "enriched_rules_part_*.json")))
    if rules_files:
        print(f"📜 Found {len(rules_files)} rule chunks. Generating SQL for 'drug_interactions'...")
        
        for idx, fpath in enumerate(rules_files):
            with open(fpath, 'r', encoding='utf-8') as f:
                content = json.load(f)
                data = content.get('data', [])
                
            if not data: continue
            
            filename = f"d1_rules_part_{idx+1}.sql"
            out = os.path.join(output_dir, filename)
            generated_files.append(out)
            
            with open(out, 'w', encoding='utf-8') as f:
                f.write(f"-- Rules Part {idx+1}\n")
                if idx == 0:
                    f.write("DROP TABLE IF EXISTS drug_interactions;\n")
                    f.write("""CREATE TABLE drug_interactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ingredient1 TEXT,
    ingredient2 TEXT,
    severity TEXT,
    effect TEXT,
    arabic_effect TEXT,
    recommendation TEXT,
    arabic_recommendation TEXT,
    management_text TEXT,
    mechanism_text TEXT,
    risk_level TEXT,
    ddinter_id TEXT,
    source TEXT,
    type TEXT,
    updated_at INTEGER DEFAULT 0
);\n\n""")
                    f.write("CREATE INDEX IF NOT EXISTS idx_rules_pair ON drug_interactions(ingredient1, ingredient2);\n")
                    f.write("CREATE INDEX IF NOT EXISTS idx_rules_i1 ON drug_interactions(ingredient1);\n")
                    f.write("CREATE INDEX IF NOT EXISTS idx_rules_i2 ON drug_interactions(ingredient2);\n\n")

                # Insert Batching
                batch = []
                for item in data:
                    i1 = str(item.get('ingredient1', '')).replace("'", "''")
                    i2 = str(item.get('ingredient2', '')).replace("'", "''")
                    sev = str(item.get('severity', 'moderate')).replace("'", "''")
                    typ = str(item.get('type', 'pharmacodynamic')).replace("'", "''")
                    eff = str(item.get('effect', '')).replace("'", "''")
                    # Enriched data might not have arabic_effect populated in the json if it is just passed through, 
                    # but let's assume keys exist or default to empty
                    eff_ar = str(item.get('arabic_effect', '')).replace("'", "''")
                    rec = str(item.get('recommendation', '')).replace("'", "''")
                    rec_ar = str(item.get('arabic_recommendation', '')).replace("'", "''")
                    
                    mgmt = str(item.get('management_text', '')).replace("'", "''")
                    mech = str(item.get('mechanism_text', '')).replace("'", "''")
                    risk = str(item.get('risk_level', '')).replace("'", "''")
                    dd_id = str(item.get('ddinter_id', '')).replace("'", "''")
                    
                    src = str(item.get('source', 'DDInter')).replace("'", "''")
                    
                    batch.append(f"('{i1}', '{i2}', '{sev}', '{eff}', '{eff_ar}', '{rec}', '{rec_ar}', '{mgmt}', '{mech}', '{risk}', '{dd_id}', '{src}', '{typ}', 0)")
                    
                    if len(batch) >= 50:
                         f.write("INSERT INTO drug_interactions (ingredient1, ingredient2, severity, effect, arabic_effect, recommendation, arabic_recommendation, management_text, mechanism_text, risk_level, ddinter_id, source, type, updated_at) VALUES\n")
                         f.write(",\n".join(batch))
                         f.write(";\n")
                         batch = []
                
                if batch:
                     f.write("INSERT INTO drug_interactions (ingredient1, ingredient2, severity, effect, arabic_effect, recommendation, arabic_recommendation, management_text, mechanism_text, risk_level, ddinter_id, source, type, updated_at) VALUES\n")
                     f.write(",\n".join(batch))
                     f.write(";\n")
            print(f"  -> Generated {filename} ({len(data)} rows)")

    # --- 2. Process Ingredients Map (med_ingredients table) ---
    ing_files = sorted(glob.glob(os.path.join(json_path, "ingredients_part_*.json")))
    if ing_files:
        print(f"🗺️  Found {len(ing_files)} ingredient index chunks. Generating SQL for 'med_ingredients'...")
        
        for idx, fpath in enumerate(ing_files):
            with open(fpath, 'r', encoding='utf-8') as f:
                content = json.load(f)
                data = content.get('data', [])
                
            if not data: continue
            
            filename = f"d1_ingredients_part_{idx+1}.sql"
            out = os.path.join(output_dir, filename)
            generated_files.append(out)
            
            with open(out, 'w', encoding='utf-8') as f:
                f.write(f"-- Ingredients Map Part {idx+1}\n")
                if idx == 0:
                    f.write("DROP TABLE IF EXISTS med_ingredients;\n")
                    f.write("""CREATE TABLE med_ingredients (
    med_id INTEGER,
    ingredient TEXT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (med_id, ingredient)
);\n\n""")
                    f.write("CREATE INDEX idx_mi_mid ON med_ingredients(med_id);\n\n")

                # Insert Batching
                batch = []
                for item in data:
                    mid = item.get('med_id')
                    ings = item.get('ingredients', [])
                    
                    for ing in ings:
                        clean_ing = str(ing).replace("'", "''")
                        batch.append(f"({mid}, '{clean_ing}')")
                    
                    if len(batch) >= 100:
                         f.write("INSERT OR IGNORE INTO med_ingredients (med_id, ingredient) VALUES\n")
                         f.write(",\n".join(batch))
                         f.write(";\n")
                         batch = []
                
                if batch:
                     f.write("INSERT OR IGNORE INTO med_ingredients (med_id, ingredient) VALUES\n")
                     f.write(",\n".join(batch))
                     f.write(";\n")
            print(f"  -> Generated {filename}")

    print(f"✅ Export Complete: {len(generated_files)} SQL files generated.")
    return True

if __name__ == "__main__":
    json_path = sys.argv[1] if len(sys.argv) > 1 else 'assets/data/interactions/enriched/'
    export_interactions_sql(json_path)
