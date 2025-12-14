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
        with open(csv_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
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
        
        # Schema Init (Safe)
        f.write("CREATE TABLE IF NOT EXISTS drugs (\n")
        f.write("  id INTEGER PRIMARY KEY,\n") # CSV might not have ID, we might need to auto-gen or allow NULL if AutoInc
        f.write("  trade_name TEXT,\n")
        f.write("  arabic_name TEXT,\n")
        f.write("  old_price TEXT,\n")
        f.write("  price TEXT,\n")
        f.write("  active TEXT,\n")
        f.write("  main_category TEXT,\n")
        f.write("  main_category_ar TEXT,\n")
        f.write("  category TEXT,\n")
        f.write("  category_ar TEXT,\n")
        f.write("  company TEXT,\n")
        f.write("  dosage_form TEXT,\n")
        f.write("  dosage_form_ar TEXT,\n")
        f.write("  unit TEXT,\n")
        f.write("  usage TEXT,\n")
        f.write("  usage_ar TEXT,\n")
        f.write("  description TEXT,\n")
        f.write("  last_price_update TEXT,\n")
        f.write("  concentration TEXT,\n")
        f.write("  visits INTEGER DEFAULT 0\n")
        f.write(");\n\n")
        
        # Clear existing data? User wants a sync.
        # "Sync Full Database" implies replacing the state.
        f.write("-- Clear existing data\n")
        f.write("DELETE FROM drugs;\n\n")
        
        print("📝 Exporting records...")
        
        batch_size = 500 # D1 limit per statement is typically high, but safe batching is good
        batch = []
        total_exported = 0
        
        # Mapping CSV headers to DB columns
        # CSV headers based on verification: 
        # Trade Name,Arabic Name,Old Price,Price,Active Ingredient,Main Category,Main Category AR,Category,Category AR,Company,Dosage Form,Dosage Form AR,Unit,Usage,Usage AR,Description,Last Price Update,Concentration,Image URL
        
        # We need to ensure we map correctly.
        # DictReader uses first row keys.
        
        for idx, row in enumerate(rows):
            # Safe value extractor
            def get_val(key):
                val = row.get(key, '').strip()
                val = val.replace("'", "''") # Escape SQL
                return f"'{val}'"
            
            # ID generation: use loop index + 1 if no ID col, or try to find ID
            # meds.csv typically doesn't have ID column in standard exports unless added
            # We will use idx+1 as ID for consistency in this bulk load
            id_val = str(idx + 1)
            
            # Map columns
            trade = get_val('Trade Name')
            arabic = get_val('Arabic Name')
            old_p = get_val('Old Price')
            price = get_val('Price')
            active = get_val('Active Ingredient')
            main = get_val('Main Category')
            main_ar = get_val('Main Category AR')
            cat = get_val('Category')
            cat_ar = get_val('Category AR')
            comp = get_val('Company')
            form = get_val('Dosage Form')
            form_ar = get_val('Dosage Form AR')
            unit = get_val('Unit')
            usage = get_val('Usage')
            usage_ar = get_val('Usage AR')
            desc = get_val('Description')
            last = get_val('Last Price Update')
            conc = get_val('Concentration')
            visits = '0' # Default
            
            values = f"({id_val}, {trade}, {arabic}, {old_p}, {price}, {active}, {main}, {main_ar}, {cat}, {cat_ar}, {comp}, {form}, {form_ar}, {unit}, {usage}, {usage_ar}, {desc}, {last}, {conc}, {visits})"
            batch.append(values)
            
            if len(batch) >= batch_size:
                f.write("INSERT INTO drugs (id, trade_name, arabic_name, old_price, price, active, main_category, main_category_ar, category, category_ar, company, dosage_form, dosage_form_ar, unit, usage, usage_ar, description, last_price_update, concentration, visits) VALUES\n")
                f.write(',\n'.join(batch))
                f.write(';\n\n')
                total_exported += len(batch)
                batch = []
                
        if batch:
            f.write("INSERT INTO drugs (id, trade_name, arabic_name, old_price, price, active, main_category, main_category_ar, category, category_ar, company, dosage_form, dosage_form_ar, unit, usage, usage_ar, description, last_price_update, concentration, visits) VALUES\n")
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
