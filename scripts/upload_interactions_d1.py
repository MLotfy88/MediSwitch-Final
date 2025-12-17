#!/usr/bin/env python3
"""
Export Drug Interactions to SQL for D1 Import
Generates: d1_interactions.sql
"""
import json
import sys
import os

def export_interactions_sql(json_path, output_path='d1_interactions.sql'):
    if not os.path.exists(json_path):
        print(f"❌ JSON file not found: {json_path}")
        return False
        
    try:
        with open(json_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print(f"❌ Error reading JSON: {e}")
        return False
        
    interactions = data.get('interactions', [])
    print(f"📊 Found {len(interactions)} interactions")
    
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write("-- MediSwitch Drug Interactions Import\n\n")
        f.write("DROP TABLE IF EXISTS drug_interactions;\n")
        f.write("""CREATE TABLE drug_interactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    med_id INTEGER,
    interaction_drug_name TEXT,
    interaction_dailymed_id TEXT,
    severity TEXT,
    description TEXT,
    source TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);\n\n""")
        
        if not interactions:
            print("⚠️ No interactions to export.")
            return True
        
        # Deduplication tracking
        seen = set()
        unique_batch = []
        
        for i in interactions:
            med_id = i.get('med_id')
            drug_name = i.get('interaction_drug_name')
            
            if not med_id or not drug_name: continue
            
            # Simple dedupe key
            key = (med_id, drug_name.lower())
            if key in seen: continue
            seen.add(key)
            
            unique_batch.append(i)
            
        print(f"📝 Generating INSERT statements for {len(unique_batch)} unique interactions...")
        
        batch_size = 500
        current_batch = []
        
        for i in unique_batch:
            def sql_val(val):
                if val is None: return "NULL"
                clean_val = str(val).replace("'", "''")
                return f"'{clean_val}'"
                
            vals = [
                i.get('med_id'),
                i.get('interaction_drug_name'),
                i.get('interaction_dailymed_id', 'N/A'),
                i.get('severity', 'Moderate'),
                i.get('description', ''),
                i.get('source', 'DailyMed')
            ]
            
            v_str = f"({vals[0]}, {sql_val(vals[1])}, {sql_val(vals[2])}, {sql_val(vals[3])}, {sql_val(vals[4])}, {sql_val(vals[5])})"
            current_batch.append(v_str)
            
            if len(current_batch) >= batch_size:
                f.write("INSERT INTO drug_interactions (med_id, interaction_drug_name, interaction_dailymed_id, severity, description, source) VALUES\n")
                f.write(",\n".join(current_batch))
                f.write(";\n\n")
                current_batch = []
                
        if current_batch:
            f.write("INSERT INTO drug_interactions (med_id, interaction_drug_name, interaction_dailymed_id, severity, description, source) VALUES\n")
            f.write(",\n".join(current_batch))
            f.write(";\n\n")

    print(f"✅ Exported to {output_path}")
    return True

if __name__ == "__main__":
    json_file = sys.argv[1] if len(sys.argv) > 1 else 'assets/data/drug_interactions.json'
    export_interactions_sql(json_file)
