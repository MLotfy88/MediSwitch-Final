#!/usr/bin/env python3
"""
Export Disease Interactions to SQL for D1 Import
Generates: d1_disease_interactions.sql
"""
import json
import sys
import os

def export_disease_interactions_sql(json_path, output_path='d1_disease_interactions.sql'):
    if not os.path.exists(json_path):
        print(f"❌ JSON file not found: {json_path}")
        return False
        
    try:
        with open(json_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print(f"❌ Error reading JSON: {e}")
        return False
        
    print(f"📊 Found {len(data)} disease interactions")
    
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write("-- MediSwitch Disease Interactions Import\n\n")
        f.write("DROP TABLE IF EXISTS disease_interactions;\n")
        f.write("""CREATE TABLE IF NOT EXISTS disease_interactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  med_id INTEGER,
  trade_name TEXT,
  disease_name TEXT NOT NULL,
  interaction_text TEXT NOT NULL,
  source TEXT DEFAULT 'DDInter'
);\n""")
        f.write("CREATE INDEX IF NOT EXISTS idx_disease_med_id ON disease_interactions(med_id);\n\n")
        
        if not data:
            print("⚠️ No interactions to export.")
            return True
            
        print("📝 Generating INSERT statements...")
        batch_size = 50
        batch = []
        
        for item in data:
            med_id = item.get('med_id')
            if not med_id: continue
            
            # Safe Value Extraction
            def sql_val(val):
                if val is None: return "NULL"
                if isinstance(val, str):
                    clean_val = val.replace("'", "''")
                    return f"'{clean_val}'"
                return str(val)
            
            trade = item.get('trade_name', '')
            disease = item.get('disease_name', '')
            interaction = item.get('interaction_text', '')
            source = item.get('source', 'DDInter')

            # Format: (med_id, trade_name, disease_name, interaction_text, source)
            v_str = f"({med_id}, {sql_val(trade)}, {sql_val(disease)}, {sql_val(interaction)}, {sql_val(source)})"
            batch.append(v_str)

            if len(batch) >= batch_size:
                f.write("INSERT INTO disease_interactions (med_id, trade_name, disease_name, interaction_text, source) VALUES\n")
                f.write(",\n".join(batch))
                f.write(";\n\n")
                batch = []
        
        if batch:
            f.write("INSERT INTO disease_interactions (med_id, trade_name, disease_name, interaction_text, source) VALUES\n")
            f.write(",\n".join(batch))
            f.write(";\n\n")
            
    print(f"✅ Exported to {output_path}")
    return True

if __name__ == "__main__":
    json_file = sys.argv[1] if len(sys.argv) > 1 else 'assets/data/interactions/enriched/enriched_disease_interactions.json'
    export_disease_interactions_sql(json_file)
