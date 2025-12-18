#!/usr/bin/env python3
"""
Export Drug Interactions to SQL for D1 Import (Chunked)
Generates: d1_interactions_part_X.sql
"""
import json
import sys
import os
import math

def export_interactions_sql(json_path, output_dir='.', chunk_size=3000):
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
        
        key = (med_id, drug_name.lower())
        if key in seen: continue
        seen.add(key)
        
        unique_batch.append(i)
        
    print(f"📝 Preparing {len(unique_batch)} unique interactions for export...")

    # Chunking 
    # D1 has limit (SQLITE_TOOBIG), usually around 1MB-5MB per query or strict size limits.
    # Safe bet is ~3000 rows per file or less depending on row size.
    
    total_chunks = math.ceil(len(unique_batch) / chunk_size)
    print(f"📦 Splitting into {total_chunks} files (Limit: {chunk_size} rows/file)...")
    
    base_name = "d1_interactions"
    
    for chunk_idx in range(total_chunks):
        start = chunk_idx * chunk_size
        end = start + chunk_size
        chunk = unique_batch[start:end]
        
        filename = f"{base_name}_part_{chunk_idx+1}.sql"
        output_path = os.path.join(output_dir, filename)
        
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(f"-- MediSwitch Drug Interactions Import (Part {chunk_idx+1}/{total_chunks})\n")
            if chunk_idx == 0:
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
            
            # Write Inserts in small batches within the file
            sql_batch_size = 100
            current_sql_batch = []
            
            for i in chunk:
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
                current_sql_batch.append(v_str)
                
                if len(current_sql_batch) >= sql_batch_size:
                    f.write("INSERT INTO drug_interactions (med_id, interaction_drug_name, interaction_dailymed_id, severity, description, source) VALUES\n")
                    f.write(",\n".join(current_sql_batch))
                    f.write(";\n\n")
                    current_sql_batch = []
            
            if current_sql_batch:
                f.write("INSERT INTO drug_interactions (med_id, interaction_drug_name, interaction_dailymed_id, severity, description, source) VALUES\n")
                f.write(",\n".join(current_sql_batch))
                f.write(";\n\n")
        
        print(f"  -> Generated {filename} ({len(chunk)} rows)")

    print(f"✅ Export Complete: {total_chunks} files generated.")
    return True

if __name__ == "__main__":
    json_file = sys.argv[1] if len(sys.argv) > 1 else 'assets/data/drug_interactions.json'
    export_interactions_sql(json_file)
