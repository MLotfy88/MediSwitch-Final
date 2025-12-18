#!/usr/bin/env python3
"""
Update Meds CSV from Scraped Details (Exact Schema Mode)
Reads: assets/meds_scraped_new.jsonl
Writes: assets/meds.csv (Exact Match to JSON Keys)

Target Columns:
id, arabic_name, trade_name, active, category, company, price, old_price, 
last_price_update, units, barcode, qr_code, pharmacology, usage, visits, 
concentration, dosage_form, dosage_form_ar
"""

import pandas as pd
import json
import os
import shutil
import sys
import datetime

# --- Path Configuration ---
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRAPED_DB = os.path.join(BASE_DIR, 'assets', 'meds_scraped_new.jsonl')
MEDS_CSV = os.path.join(BASE_DIR, 'assets', 'meds.csv')
BACKUP_DIR = os.path.join(BASE_DIR, 'backups')

def main():
    print(f"🔄 Generating meds.csv from {SCRAPED_DB} (Exact Match Mode)...")
    
    if not os.path.exists(SCRAPED_DB):
        print("❌ Scraped DB not found. Run scraper first.")
        sys.exit(1)

    # 1. Load Scraped Data
    records = []
    print(f"📂 Loading scraped data...")
    try:
        with open(SCRAPED_DB, 'r', encoding='utf-8') as f:
            for line in f:
                if line.strip():
                    try:
                        rec = json.loads(line)
                        if rec.get('id'):
                            records.append(rec)
                    except: pass
    except Exception as e:
        print(f"❌ Error reading scraped file: {e}")
        sys.exit(1)
        
    print(f"📊 Loaded {len(records)} records.")
    
    if not records:
        print("⚠️ No records found. Aborting.")
        sys.exit(1)

    # 2. Define Strict Column Order (Based on user request + verified keys)
    # The order can be logical or strictly alphabetical, user seemed to imply a specific structure in their JSON example,
    # but practically we just need all keys. I will group them logically.
    cols = [
        'id', 
        'trade_name', 
        'arabic_name', 
        'active', 
        'category', 
        'company', 
        'price', 
        'old_price', 
        'last_price_update', 
        'units', 
        'barcode', 
        'qr_code', 
        'pharmacology', 
        'usage', 
        'visits', 
        'concentration', 
        'dosage_form', 
        'dosage_form_ar'
    ]

    # 3. Create DataFrame
    # We load directly from records. Keys not in 'cols' will be dropped later, keys missing will be NaNs.
    df = pd.DataFrame(records)
    
    # 4. Cleanup and Normalize
    # Ensure ID string
    df['id'] = df['id'].astype(str).str.strip()
    
    # Deduplicate by ID (Keep last update)
    df.drop_duplicates(subset=['id'], keep='last', inplace=True)
    
    # Ensure all columns exist
    for c in cols:
        if c not in df.columns:
            df[c] = ''
            
    # Reorder and Select Strict Columns
    df = df[cols]
    
    # 5. Backup Old CSV (if exists)
    if os.path.exists(MEDS_CSV):
        try:
           os.makedirs(BACKUP_DIR, exist_ok=True)
           ts = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
           shutil.copy(MEDS_CSV, os.path.join(BACKUP_DIR, f'meds_backup_interim_{ts}.csv'))
        except Exception as e:
            print(f"⚠️ Backup failed: {e}")

    # 6. Write New CSV
    df.to_csv(MEDS_CSV, index=False, encoding='utf-8-sig')
    print(f"✅ Successfully wrote {len(df)} records to {MEDS_CSV} with Exact Schema.")
    print(f"   Columns: {', '.join(df.columns)}")

if __name__ == "__main__":
    main()
