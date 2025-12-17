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

    # Define minimal clean schema for updates
    # merge_meds.py needs: id, price, trade_name, arabic_name (for report)
    # We populate these from the scraper data.
    
    clean_records = []
    for r in records:
        clean_records.append({
            'id': r.get('id'),
            'trade_name': r.get('trade_name', ''),
            'arabic_name': r.get('arabic_name', ''),
            'price': r.get('price', '0'),
            'old_price': r.get('old_price', ''),
            'active': r.get('active', ''),
            'company': r.get('company', ''),
            'dosage_form': r.get('dosage_form', ''),
            'usage': r.get('usage', ''),
            'concentration': r.get('concentration', ''),
            'barcode': r.get('barcode', ''),
            'last_price_update': datetime.now().strftime('%Y-%m-%d')
        })

    keys = clean_records[0].keys()
    with open(TEMP_CSV, 'w', encoding='utf-8', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=keys)
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
