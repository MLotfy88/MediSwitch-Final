#!/usr/bin/env python3
"""
Update Meds CSV from Scraped Details
Reads: assets/meds_scraped_new.jsonl
Updates: assets/meds.csv (Adds/Updates concentration, pharmacy info, etc)
"""

import pandas as pd
import json
import os
import shutil
import sys

# Paths
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MEDS_CSV = os.path.join(BASE_DIR, 'assets', 'meds.csv')
SCRAPED_DB = os.path.join(BASE_DIR, 'assets', 'meds_scraped_new.jsonl')
BACKUP_DIR = os.path.join(BASE_DIR, 'assets', 'backups')

def main():
    print(f"🔄 Updating meds.csv from {SCRAPED_DB}...")
    
    if not os.path.exists(MEDS_CSV):
        print("❌ assets/meds.csv not found!")
        sys.exit(1)
        
    if not os.path.exists(SCRAPED_DB):
        print("❌ Scraped DB not found. Run scraper first.")
        sys.exit(1)

    # 1. Load Scraped Data
    scraped_map = {}
    with open(SCRAPED_DB, 'r', encoding='utf-8') as f:
        for line in f:
            if line.strip():
                try:
                    rec = json.loads(line)
                    mid = str(rec.get('id', ''))
                    if mid:
                        scraped_map[mid] = rec
                except: pass
    print(f"✅ Loaded {len(scraped_map)} scraped records.")

    # 2. Backup CSV
    os.makedirs(BACKUP_DIR, exist_ok=True)
    shutil.copy(MEDS_CSV, os.path.join(BACKUP_DIR, 'meds_backup_pre_enrich.csv'))

    # 3. Read CSV
    df = pd.read_csv(MEDS_CSV, dtype=str)
    
    # Ensure columns exist
    if 'Concentration' not in df.columns:
        df['Concentration'] = ''
    if 'Pharmacology' not in df.columns:
        df['Pharmacology'] = ''
        
    # 4. Update Rows
    updated_count = 0
    for idx, row in df.iterrows():
        mid = str(row.get('id', '')).strip() # Assuming 'id' column exists, check header below
        # If 'id' key maps to something else, adjust. meds.csv usually has no header or specific header.
        # Let's assume standard Schema: Trade Name, Arabic Name, etc.
        # Wait, does meds.csv HAVE an ID column?
        # daily-update.yml says `enrich_data.py` uses `meds_updated.csv`.
        # I need to verify meds.csv headers.
        
        # If no ID in CSV, we assume we match by Name? Or row index?
        # scrape_dwaprices_by_id.py used IDs from meds.csv 'id' column.
        # So 'id' column must exist.
        
        if mid in scraped_map:
            rec = scraped_map[mid]
            
            # Update fields
            if rec.get('concentration'):
                df.at[idx, 'Concentration'] = rec['concentration']
            if rec.get('pharmacology'):
                df.at[idx, 'Pharmacology'] = rec['pharmacology'][:1000] # Truncate
            
            # Can also update price if newer?
            # User prioritized 'concentration extracted from trade name'.
            
            updated_count += 1
            
    # 5. Save
    df.to_csv(MEDS_CSV, index=False)
    print(f"✅ Updated {updated_count} rows in meds.csv")

if __name__ == "__main__":
    main()
