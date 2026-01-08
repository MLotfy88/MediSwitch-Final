import pandas as pd
import csv
import json
import gzip
import re
import os


import sqlite3

import glob

# --- Configuration ---
MEDS_DB_PATH = 'assets/database/mediswitch.db' 
SPL_RESULTS_DIR = 'external_repo_analysis/data/dailymed/results'
OUTPUT_JSONL = 'production_data/spl_enriched_dosages.jsonl'

# ... (rest of normalization) ...

def normalize_ingredient(active_ing):
    """
    Normalize active ingredient strings for matching.
    - lowercase
    - strip whitespace
    - remove salt forms (simple list)
    - handle synonyms
    """
    if not active_ing: return ""
    norm = str(active_ing).lower().strip()
    
    # Synonyms Map (Partial)
    synonyms = {
        "acetaminophen": "paracetamol",
        "adrenaline": "epinephrine",
        "meperidine": "pethidine",
        "albuterol": "salbutamol",
    }
    
    # Remove salts/modifiers
    salts = [
        "hydrochloride", "sodium", "dipropionate", "monohydate", "calcium", 
        "potassium", "magnesium", "sulfate", "tartrate", "maleate", "fumarate",
        "acetate", "succinate", "citrate", "phosphate"
    ]
    
    for salt in salts:
        norm = norm.replace(salt, "").strip()
        
    # Check synonyms
    if norm in synonyms:
        norm = synonyms[norm]
        
    return norm

def load_local_db():
    print(f"Loading local database from {MEDS_DB_PATH} using SQLite...")
    if not os.path.exists(MEDS_DB_PATH):
        raise FileNotFoundError(f"Database not found at {MEDS_DB_PATH}")
        
    conn = sqlite3.connect(MEDS_DB_PATH)
    try:
        # User requested matching by ACTIVE INGREDIENT from med_ingredients table
        query = "SELECT med_id as id, ingredient as active FROM med_ingredients"
        df = pd.read_sql_query(query, conn)
    finally:
        conn.close()
        
    print(f"Loaded {len(df)} ingredient records.")
    # Ensure active ingredient is string
    df['active'] = df['active'].fillna('')
    df['norm_active'] = df['active'].apply(normalize_ingredient)
    return df

def process_spl_file(csv_path, local_lookup, output_handle):
    """
    Process a single SPL CSV.gz file and write matches to output_handle immediately.
    Returns count of matches found in this file.
    """
    print(f"Processing {os.path.basename(csv_path)}...")
    try:
        spl_df = pd.read_csv(csv_path, compression='gzip')
    except Exception as e:
        print(f"Error reading {csv_path}: {e}")
        return 0

    spl_df['generic_name'] = spl_df['generic_name'].fillna('')
    spl_df['norm_generic'] = spl_df['generic_name'].apply(normalize_ingredient)
    
    spl_grouped = spl_df.groupby('norm_generic')
    
    file_match_count = 0
    records_written = 0
    
    for spl_active, spl_rows in spl_grouped:
        if not spl_active: continue
        
        matches = local_lookup.get(spl_active)
        if matches:
            file_match_count += 1
            for local_drug in matches:
                # Vectorized iteration if possible, but inner loop is small
                for _, spl_row in spl_rows.iterrows():
                    # Clean SPL text separators (###)
                    raw_text = str(spl_row.get('text', ''))
                    cleaned_spl_text = raw_text.replace('###', '\n\n')
                    
                    record = {
                        "med_id": local_drug['id'],
                        "active_ingredient": local_drug['active'],
                        "spl_set_id": spl_row['set_id'],
                        "spl_generic": spl_row['generic_name'],
                        "section_type": spl_row['type'],
                        "section_text": cleaned_spl_text,
                        "source": "dailymed_spl_xml"
                    }
                    output_handle.write(json.dumps(record) + '\n')
                    records_written += 1
    
    print(f"  Matched {file_match_count} ingredients, wrote {records_written} records.")
    return file_match_count

def main():
    local_df = load_local_db()
    
    if os.path.exists(SPL_RESULTS_DIR):
        csv_files = glob.glob(os.path.join(SPL_RESULTS_DIR, "*.csv.gz"))
        if not csv_files:
            print(f"No .csv.gz files found in {SPL_RESULTS_DIR}.")
            return

        print(f"Found {len(csv_files)} SPL data files.")
        
        # Build Lookup
        local_lookup = {}
        for idx, row in local_df.iterrows():
            key = row['norm_active']
            if key:
                if key not in local_lookup: local_lookup[key] = []
                local_lookup[key].append(row.to_dict())

        total_matches = 0
        print(f"Writing matches incrementally to {OUTPUT_JSONL}...")
        
        with open(OUTPUT_JSONL, 'w', encoding='utf-8') as f_out:
            for csv_path in csv_files:
                count = process_spl_file(csv_path, local_lookup, f_out)
                total_matches += count
                f_out.flush() # Ensure wrote to disk

        print(f"Done. Total ingredients matched: {total_matches}")
        
    else:
         print(f"Directory {SPL_RESULTS_DIR} not found.")

if __name__ == "__main__":
    main()
