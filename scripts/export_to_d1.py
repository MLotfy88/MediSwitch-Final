#!/usr/bin/env python3
"""
تصدير بيانات الأدوية إلى D1 - نسخة نظيفة
Single INSERT per drug - آمن وقابل للتقسيم
"""

import csv
import os
from datetime import datetime

def export_to_sql(csv_file, output_file):
    """Export meds.csv to SQL with individual INSERTs"""
    
    if not os.path.exists(csv_file):
        print(f"❌ File not found: {csv_file}")
        return False
    
    with open(csv_file, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        rows = list(reader)
    
    print(f"📖 Reading database from {csv_file}...")
    print(f"📊 Found {len(rows)} medications")
    
    with open(output_file, 'w', encoding='utf-8') as f:
        # Schema
        f.write(f"""-- D1 Database Export
-- Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
-- Single INSERT per drug for safe chunking

DROP TABLE IF EXISTS drugs;

CREATE TABLE IF NOT EXISTS drugs (
  id INTEGER PRIMARY KEY,
  trade_name TEXT,
  arabic_name TEXT,
  price TEXT,
  old_price TEXT,
  main_category TEXT,
  category TEXT,
  category_ar TEXT,
  active TEXT,
  company TEXT,
  dosage_form TEXT,
  dosage_form_ar TEXT,
  concentration TEXT,
  unit TEXT,
  usage TEXT,
  usage_ar TEXT,
  description TEXT,
  pharmacology TEXT,
  barcode TEXT,
  qr_code TEXT,
  visits INTEGER DEFAULT 0,
  last_price_update TEXT,
  image_url TEXT,
  updated_at INTEGER DEFAULT 0,
  has_drug_interaction INTEGER DEFAULT 0,
  has_food_interaction INTEGER DEFAULT 0,
  has_disease_interaction INTEGER DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_trade_name ON drugs (trade_name);
CREATE INDEX IF NOT EXISTS idx_category ON drugs (category);
CREATE INDEX IF NOT EXISTS idx_active ON drugs (active);

-- Data (one INSERT per drug)
""")
        
        print("📝 Exporting records...")
        
        count = 0
        skipped = 0
        seen_ids = set()
        
        for row in rows:
            # Get ID
            id_raw = row.get('id', '').strip()
            if not id_raw or not id_raw.isdigit():
                skipped += 1
                continue
            
            drug_id = int(id_raw)
            
            # Skip duplicates
            if drug_id in seen_ids:
                skipped += 1
                continue
            
            seen_ids.add(drug_id)
            
            # Helper to escape and quote
            def esc(val):
                if val is None:
                    return "''"
                s = str(val).strip()
                s = s.replace("'", "''")  # SQL escape
                return f"'{s}'"

            # Extract all fields with correct mapping
            trade = esc(row.get('trade_name', ''))
            arabic = esc(row.get('arabic_name', ''))
            price = esc(row.get('price', ''))
            old_p = esc(row.get('old_price', ''))
            main_cat = esc(row.get('main_category', ''))
            cat = esc(row.get('category', ''))
            cat_ar = esc(row.get('category_ar', ''))
            active = esc(row.get('active', ''))
            company = esc(row.get('company', ''))
            form = esc(row.get('dosage_form', ''))
            form_ar = esc(row.get('dosage_form_ar', ''))
            conc = esc(row.get('concentration', ''))
            unit = esc(row.get('units', '')) # Map 'units' -> 'unit'
            usage = esc(row.get('usage', ''))
            usage_ar = esc(row.get('usage_ar', ''))
            desc = esc(row.get('description', ''))
            pharm = esc(row.get('pharmacology', ''))
            barcode = esc(row.get('barcode', ''))
            qr = esc(row.get('qr_code', ''))
            
            visits = 0
            
            update = esc(row.get('last_price_update', ''))
            img = esc(row.get('image_url', ''))
            
            # New flags (defaults)
            has_drug = 0
            has_food = 0
            has_disease = 0
            
            # Write single INSERT
            sql = f"INSERT INTO drugs (id, trade_name, arabic_name, price, old_price, main_category, category, category_ar, active, company, dosage_form, dosage_form_ar, concentration, unit, usage, usage_ar, description, pharmacology, barcode, qr_code, visits, last_price_update, image_url, updated_at, has_drug_interaction, has_food_interaction, has_disease_interaction) VALUES ({drug_id}, {trade}, {arabic}, {price}, {old_p}, {main_cat}, {cat}, {cat_ar}, {active}, {company}, {form}, {form_ar}, {conc}, {unit}, {usage}, {usage_ar}, {desc}, {pharm}, {barcode}, {qr}, {visits}, {update}, {img}, 0, {has_drug}, {has_food}, {has_disease});\n"
            
            f.write(sql)
            count += 1
    
    file_size = os.path.getsize(output_file) / (1024 * 1024)
    
    print()
    print("✅ Export complete!")
    print(f"   Total records: {count}")
    if skipped > 0:
        print(f"   Skipped: {skipped}")
    print(f"   Output file: {output_file}")
    print(f"   File size: {file_size:.2f} MB")
    
    return True

if __name__ == "__main__":
    csv_file = "assets/meds.csv"
    output_file = "d1_import.sql"
    
    success = export_to_sql(csv_file, output_file)
    
    if not success:
        exit(1)
