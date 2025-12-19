#!/usr/bin/env python3
"""
Bridge Daily Update Script
1. Runs the NEW robust scraper (smart resume mode).
2. Converts JSONL output to a Clean CSV (no legacy columns).
3. Calls the existing merge_meds.py to apply updates and generate Price Reports.
"""

import os
import sys
import json
import csv
import subprocess
from datetime import datetime

# Paths
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRAPER_SCRIPT = os.path.join(BASE_DIR, 'scripts', 'scrape_dwaprices_by_id.py')
MERGE_SCRIPT = os.path.join(BASE_DIR, 'scripts', 'merge_meds.py')
SCRAPED_JSONL = os.path.join(BASE_DIR, 'assets', 'meds_scraped_new.jsonl')
TEMP_CSV = os.path.join(BASE_DIR, 'assets', 'meds_updates_temp.csv')
MEDS_CSV = os.path.join(BASE_DIR, 'assets', 'meds.csv')

def run_scraper():
    print("🚀 Starting Smart Scraper (Resume Mode)...")
    try:
        subprocess.run(['python3', SCRAPER_SCRIPT], check=True)
    except subprocess.CalledProcessError as e:
        print(f"❌ Scraper failed: {e}")
        sys.exit(1)

def convert_jsonl_to_clean_csv():
    print(f"🔄 Converting {SCRAPED_JSONL} to Clean CSV...")
    if not os.path.exists(SCRAPED_JSONL):
        print("❌ Scraped file not found.")
        sys.exit(1)

    records = []
    with open(SCRAPED_JSONL, 'r', encoding='utf-8') as f:
        for line in f:
            if line.strip():
                try:
                    records.append(json.loads(line))
                except:
                    pass
    
    if not records:
        print("⚠️ No records found in scraper output.")
        return False

    # Define the STRICT schema and order to match assets/meds.csv exactly
    cols = [
        'id', 'trade_name', 'arabic_name', 'active', 'category', 'company',
        'price', 'old_price', 'last_price_update', 'units', 'barcode',
        'qr_code', 'pharmacology', 'usage', 'visits', 'concentration',
        'dosage_form', 'dosage_form_ar'
    ]

    clean_records = []
    for r in records:
        # Map values from scraper JSON keys to CSV columns
        row = {}
        for col in cols:
            val = r.get(col, '')
            # Special case for last_price_update if missing from source
            if col == 'last_price_update' and not val:
                val = datetime.now().strftime('%Y-%m-%d')
            row[col] = val
        clean_records.append(row)

    with open(TEMP_CSV, 'w', encoding='utf-8', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=cols)
        writer.writeheader()
        writer.writerows(clean_records)
        
    print(f"✅ Created {TEMP_CSV} with {len(clean_records)} records.")
    return True

def run_merge():
    print("🤝 Running Merger (Legacy logic with Clean Data)...")
    try:
        # python3 scripts/merge_meds.py <main> <update> <output>
        subprocess.run(['python3', MERGE_SCRIPT, MEDS_CSV, TEMP_CSV, MEDS_CSV], check=True)
    except subprocess.CalledProcessError as e:
        print(f"❌ Merge failed: {e}")
        sys.exit(1)

def cleanup():
    if os.path.exists(TEMP_CSV):
        os.remove(TEMP_CSV)
        print("🧹 Cleanup done.")

def main():
    run_scraper()
    if convert_jsonl_to_clean_csv():
        run_merge()
        cleanup()
    else:
        print("⏹️ Stopping (No data).")

if __name__ == "__main__":
    main()
