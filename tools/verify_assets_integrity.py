#!/usr/bin/env python3
"""
Asset Integrity Verification Tool

Strictly compares the contents of 'mediswitch.db' with the generated files in 'assets/'.
Checks for:
1. Row counts match with 0 discrepancy.
2. Column existence match.
3. Fill rates (non-empty values) match for every column.
"""

import sqlite3
import json
import csv
import os
import glob
import sys

DB_PATH = 'mediswitch.db'
ASSETS_DIR = 'assets'

def get_db_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def analyze_db_table(table_name, columns_to_check=None):
    """Returns {count, columns: {col: fill_count}}"""
    conn = get_db_connection()
    c = conn.cursor()
    
    # Get total count
    c.execute(f"SELECT COUNT(*) FROM {table_name}")
    total_rows = c.fetchone()[0]
    
    # Get columns
    if not columns_to_check:
        c.execute(f"PRAGMA table_info({table_name})")
        columns_to_check = [r['name'] for r in c.fetchall()]
    
    col_stats = {}
    for col in columns_to_check:
        c.execute(f"SELECT COUNT(*) FROM {table_name} WHERE {col} IS NOT NULL AND {col} != ''")
        col_stats[col] = c.fetchone()[0]
        
    conn.close()
    return {'rows': total_rows, 'columns': col_stats}

def analyze_csv(file_path):
    """Returns {count, columns: {col: fill_count}}"""
    if not os.path.exists(file_path):
        return None
        
    with open(file_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        rows = list(reader)
        total_rows = len(rows)
        
        if total_rows == 0:
            return {'rows': 0, 'columns': {}}
            
        columns = reader.fieldnames
        col_stats = {col: 0 for col in columns}
        
        for row in rows:
            for col in columns:
                val = row.get(col, '')
                if val and str(val).strip(): # Non-empty check
                    col_stats[col] += 1
                    
    return {'rows': total_rows, 'columns': col_stats}

def analyze_json(file_path):
    """Returns {count, columns: {col: fill_count}}"""
    if not os.path.exists(file_path):
        return None
        
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
        
    total_rows = len(data)
    if total_rows == 0:
        return {'rows': 0, 'columns': {}}
        
    # Assume distinct keys from all rows (schema might vary slightly per json, usually consistent)
    # But for our case, keys should be consistent.
    all_keys = set()
    for item in data:
        all_keys.update(item.keys())
        
    col_stats = {k: 0 for k in all_keys}
    
    for item in data:
        for k in all_keys:
            val = item.get(k)
            # Handle list/dict values as "filled" if not empty
            if isinstance(val, (list, dict)):
                if val: col_stats[k] += 1
            elif val is not None and str(val) != "":
                col_stats[k] += 1
                
    return {'rows': total_rows, 'columns': col_stats}

def analyze_json_chunks(pattern):
    """Analyzes multiple JSON files as one dataset"""
    files = glob.glob(pattern)
    total_rows = 0
    combined_stats = {}
    
    print(f"  ... reading {len(files)} chunk files matching '{pattern}'")
    
    for file_path in files:
        stats = analyze_json(file_path)
        if not stats: continue
        
        total_rows += stats['rows']
        for col, count in stats['columns'].items():
            combined_stats[col] = combined_stats.get(col, 0) + count
            
    return {'rows': total_rows, 'columns': combined_stats}

def print_comparison(title, db_stats, asset_stats):
    print(f"\n{'='*80}")
    print(f"🔍 {title}")
    print(f"{'='*80}")
    
    if not asset_stats:
        print("❌ Asset file NOT FOUND!")
        return False
        
    # Compare Rows
    row_diff = db_stats['rows'] - asset_stats['rows']
    row_status = "✅ MATCH" if row_diff == 0 else f"❌ DIFF ({row_diff})"
    print(f"Rows: DB={db_stats['rows']:,} | Asset={asset_stats['rows']:,} -> {row_status}")
    
    if row_diff != 0:
        return False

    # Compare Columns
    print(f"\n{'-'*80}")
    print(f"{'Column':<30} | {'DB Fill':>10} | {'Asset Fill':>10} | {'Status':>10}")
    print(f"{'-'*80}")
    
    all_cols = set(db_stats['columns'].keys()) | set(asset_stats['columns'].keys())
    success = True
    
    for col in sorted(all_cols):
        db_val = db_stats['columns'].get(col, 'N/A')
        asset_val = asset_stats['columns'].get(col, 'N/A')
        
        status = "✅"
        if db_val != asset_val:
            status = "❌"
            success = False
            
        # Format numbers
        d_str = f"{db_val:,}" if isinstance(db_val, int) else db_val
        a_str = f"{asset_val:,}" if isinstance(asset_val, int) else asset_val
        
        print(f"{col:<30} | {d_str:>10} | {a_str:>10} | {status:>10}")
        
    return success

def main():
    print("🚀 Starting Strict Asset Integrity Verification...")
    overall_success = True
    
    # 1. Drugs (CSV)
    print("\n1️⃣  Checking Drugs (meds.csv)...")
    db_drugs = analyze_db_table('drugs')
    # Note: analyze_csv might interpret numbers as strings, logic handles non-empty check same.
    asset_drugs = analyze_csv(os.path.join(ASSETS_DIR, 'meds.csv'))
    if not print_comparison("Drugs Table vs CSV", db_drugs, asset_drugs):
        overall_success = False

    # 2. Dosage Guidelines (JSON)
    print("\n2️⃣  Checking Dosages...")
    db_dosages = analyze_db_table('dosage_guidelines')
    asset_dosages = analyze_json(os.path.join(ASSETS_DIR, 'data/dosage_guidelines.json'))
    if not print_comparison("Dosage Guidelines", db_dosages, asset_dosages):
        overall_success = False
        
    # 3. Food Interactions (JSON)
    print("\n3️⃣  Checking Food Interactions...")
    db_food = analyze_db_table('food_interactions')
    asset_food = analyze_json(os.path.join(ASSETS_DIR, 'data/interactions/enriched/enriched_food_interactions.json'))
    if not print_comparison("Food Interactions", db_food, asset_food):
        overall_success = False
        
    # 4. Disease Interactions (Chunked JSON)
    print("\n4️⃣  Checking Disease Interactions (Chunks)...")
    db_disease = analyze_db_table('disease_interactions')
    asset_disease = analyze_json_chunks(os.path.join(ASSETS_DIR, 'data/interactions/enriched/enriched_disease_part_*.json'))
    if not print_comparison("Disease Interactions", db_disease, asset_disease):
        overall_success = False

    # 5. Drug Interactions (Chunked JSON)
    print("\n5️⃣  Checking Drug Interactions (Chunks)...")
    db_interactions = analyze_db_table('drug_interactions')
    # Exclude ddinter_id because it might not be in the JSON export if it was removed/renamed, 
    # but strictly checking we want to see everything.
    # The DB has columns like 'alternatives_a', the json should too.
    asset_interactions = analyze_json_chunks(os.path.join(ASSETS_DIR, 'data/interactions/enriched/enriched_rules_part_*.json'))
    if not print_comparison("Drug Interactions", db_interactions, asset_interactions):
        overall_success = False

    print(f"\n{'='*80}")
    if overall_success:
        print("🎉 SUCCESS: All Assets match the Database perfectly!")
        print("✅ Column counts match.")
        print("✅ Row counts match.")
        print("✅ Data fill rates match.")
    else:
        print("⚠️ WARNING: Mismatches found! Check the logs above.")
    print(f"{'='*80}")
    
    sys.exit(0 if overall_success else 1)

if __name__ == "__main__":
    main()
