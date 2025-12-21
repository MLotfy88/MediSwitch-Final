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
    old_price TEXT,
    price TEXT,
    active TEXT,
    company TEXT,
    dosage_form TEXT,
    dosage_form_ar TEXT,
    unit TEXT,
    description TEXT,
    category TEXT,
    pharmacology TEXT,
    category_ar TEXT,
    size INTEGER,
    last_update TEXT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

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
            
            # Extract all fields
            trade = esc(row.get('trade_name', ''))
            arabic = esc(row.get('arabic_name', ''))
            old_p = esc(row.get('old_price', ''))
            price = esc(row.get('price', ''))
            active = esc(row.get('active', ''))
            company = esc(row.get('company', ''))
            form = esc(row.get('dosage_form', ''))
            form_ar = esc(row.get('dosage_form_ar', ''))
            unit = esc(row.get('unit', ''))
            desc = esc(row.get('description', ''))
            cat = esc(row.get('category', ''))
            pharm = esc(row.get('pharmacology', ''))
            cat_ar = esc(row.get('category_ar', ''))
            
            size_raw = row.get('size', '0').strip()
            size = size_raw if size_raw.isdigit() else '0'
            
            update = esc(row.get('last_update', ''))
            
            # Write single INSERT
            sql = f"INSERT INTO drugs (id, trade_name, arabic_name, old_price, price, active, company, dosage_form, dosage_form_ar, unit, description, category, pharmacology, category_ar, size, last_update, updated_at) VALUES ({drug_id}, {trade}, {arabic}, {old_p}, {price}, {active}, {company}, {form}, {form_ar}, {unit}, {desc}, {cat}, {pharm}, {cat_ar}, {size}, {update}, CURRENT_TIMESTAMP);\n"
            
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
