#!/usr/bin/env python3
"""
Export CSV/JSON data to SQL dump for Cloudflare D1 import
Reads source of truth:
- assets/meds.csv (Drugs)
- assets/data/dosage_guidelines.json (Dosages - Optional, mostly handled by sync script)
- assets/data/drug_interactions.json (Interactions - Optional)

This script focuses on the DRUGS table for the full sync.
"""

import csv
import sys
import os
from pathlib import Path

def export_to_sql(csv_path='assets/meds.csv', output_path='d1_import.sql'):
    """Export medications CSV to SQL dump"""
    
    print(f"📖 Reading database from {csv_path}...")
    
    if not Path(csv_path).exists():
        print(f"❌ Error: CSV file not found: {csv_path}")
        return False
    
    # Read CSV
    rows = []
    try:
    try:
        with open(csv_path, 'r', encoding='utf-8-sig') as f:
            reader = csv.DictReader(f)
            # Normalize headers (strip whitespace)
            if reader.fieldnames:
                reader.fieldnames = [name.strip() for name in reader.fieldnames]
            rows = list(reader)
    except Exception as e:
        print(f"❌ Error reading CSV: {e}")
        return False

    count = len(rows)
    print(f"📊 Found {count} medications")
    
    # Open output file
    with open(output_path, 'w', encoding='utf-8') as f:
        # Write header
        f.write("-- MediSwitch D1 Database Import (Full Sync)\n")
        f.write(f"-- Total records: {count}\n")
        f.write("-- Generated from local assets/meds.csv\n\n")
        
        # Schema Init (Safe) - Updated to match clean meds.csv structure
        f.write("DROP TABLE IF EXISTS drugs;\n")
        f.write("CREATE TABLE drugs (\n")
        f.write("  id INTEGER PRIMARY KEY,\n")
        f.write("  trade_name TEXT,\n")
        f.write("  arabic_name TEXT,\n")
        f.write("  price TEXT,\n")
        f.write("  old_price TEXT,\n")
        f.write("  active TEXT,\n")
        f.write("  company TEXT,\n")
        f.write("  dosage_form TEXT,\n")
        f.write("  dosage_form_ar TEXT,\n")
        f.write("  usage TEXT,\n")
        f.write("  category TEXT,\n")
        f.write("  concentration TEXT,\n")
        f.write("  pharmacology TEXT,\n")
        f.write("  barcode TEXT,\n")
        f.write("  unit TEXT,\n")
        f.write("  visits INTEGER DEFAULT 0,\n")
        f.write("  last_price_update TEXT\n")
        f.write(");\n\n")
        
        print("📝 Exporting records...")
        
        batch_size = 500
        batch = []
        total_exported = 0
        seen_ids = set()
        
        for idx, row in enumerate(rows):
            # Map columns (Keys from update_meds.py output)
            mid_raw = row.get('id', '0').strip() # meds.csv now has 'id', insert as raw int
            mid = int(mid_raw) if mid_raw.isdigit() else 0
            
            # Skip invalid or duplicate IDs (D1 Strict Requirement)
            if mid <= 0:
                print(f"⚠️ Skipping invalid ID: {mid_raw}")
                continue
                
            if mid in seen_ids:
                print(f"⚠️ Skipping duplicate ID: {mid} (Trade: {row.get('trade_name')})")
                continue
            
            seen_ids.add(mid)

            # Safe value extractor
            def get_val(key):
                val = row.get(key, '').strip()
                val = val.replace("'", "''") # Escape SQL
                return f"'{val}'"
            
            trade = get_val('trade_name')
            arabic = get_val('arabic_name')
            old_p = get_val('old_price')
            price = get_val('price')
            active = get_val('active')
            cat = get_val('category')
            comp = get_val('company')
            form = get_val('dosage_form')
            form_ar = get_val('dosage_form_ar')
            unit = get_val('unit')
            usage = get_val('usage')
            last = get_val('last_price_update')
            conc = get_val('concentration')
            pharm = get_val('pharmacology')
            bar = get_val('barcode')
            # visits is int, handle carefully
            visits_raw = row.get('visits', '0').strip() or '0'
            try:
                visits_val = int(visits_raw) if visits_raw.isdigit() else 0
            except:
                visits_val = 0
            
            values = f"({mid}, {trade}, {arabic}, {old_p}, {price}, {active}, {comp}, {form}, {form_ar}, {usage}, {cat}, {conc}, {pharm}, {bar}, {unit}, {visits_val}, {last})"
            batch.append(values)
            
            if len(batch) >= batch_size:
                f.write("INSERT INTO drugs (id, trade_name, arabic_name, old_price, price, active, company, dosage_form, dosage_form_ar, usage, category, concentration, pharmacology, barcode, unit, visits, last_price_update) VALUES\n")
                f.write(',\n'.join(batch))
                f.write(';\n\n')
                total_exported += len(batch)
                batch = []
                
        if batch:
            f.write("INSERT INTO drugs (id, trade_name, arabic_name, old_price, price, active, company, dosage_form, dosage_form_ar, usage, category, concentration, pharmacology, barcode, unit, visits, last_price_update) VALUES\n")
            f.write(',\n'.join(batch))
            f.write(';\n\n')
            total_exported += len(batch)


    # Get file size
    file_size = Path(output_path).stat().st_size / (1024 * 1024)  # MB
    
    print(f"\n✅ Export complete!")
    print(f"   Total records: {total_exported}")
    print(f"   Output file: {output_path}")
    print(f"   File size: {file_size:.2f} MB")
    
    return True

if __name__ == '__main__':
    csv_file = sys.argv[1] if len(sys.argv) > 1 else 'assets/meds.csv'
    output_file = sys.argv[2] if len(sys.argv) > 2 else 'd1_import.sql'
    
    success = export_to_sql(csv_file, output_file)
    sys.exit(0 if success else 1)
