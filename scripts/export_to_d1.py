#!/usr/bin/env python3
"""
Export SQLite database to SQL dump for Cloudflare D1 import
"""

import sqlite3
import sys
from pathlib import Path

def export_to_sql(db_path='assets/medications.db', output_path='d1_import.sql'):
    """Export medications database to SQL dump"""
    
    print(f"📖 Reading database from {db_path}...")
    
    if not Path(db_path).exists():
        print(f"❌ Error: Database file not found: {db_path}")
        return False
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Get total count
    count = cursor.execute('SELECT COUNT(*) FROM medications').fetchone()[0]
    print(f"📊 Found {count} medications")
    
    # Open output file
    with open(output_path, 'w', encoding='utf-8') as f:
        # Write header
        f.write("-- MediSwitch D1 Database Import\n")
        f.write(f"-- Total records: {count}\n")
        f.write("-- Generated from local medications.db\n\n")
        
        # Clear existing data (optional - comment out if you want to keep existing)
        f.write("-- Clear existing data\n")
        f.write("DELETE FROM drugs;\n\n")
        
        # Get all records
        print("📝 Exporting records...")
        cursor.execute('''
            SELECT id, trade_name, arabic_name, old_price, price, active,
                   main_category, main_category_ar, category, category_ar,
                   company, dosage_form, dosage_form_ar, unit, usage, usage_ar,
                   description, last_price_update, concentration, visits
            FROM medications
            ORDER BY id
        ''')
        
        batch_size = 1000
        batch = []
        total_exported = 0
        
        for row in cursor:
            # Escape single quotes in strings
            safe_row = []
            for val in row:
                if val is None:
                    safe_row.append('NULL')
                elif isinstance(val, str):
                    # Escape single quotes
                    escaped = val.replace("'", "''")
                    safe_row.append(f"'{escaped}'")
                else:
                    safe_row.append(str(val))
            
            batch.append(f"({', '.join(safe_row)})")
            
            # Write in batches
            if len(batch) >= batch_size:
                f.write("REPLACE INTO drugs (id, trade_name, arabic_name, old_price, price, active, ")
                f.write("main_category, main_category_ar, category, category_ar, company, ")
                f.write("dosage_form, dosage_form_ar, unit, usage, usage_ar, description, ")
                f.write("last_price_update, concentration, visits) VALUES\n")
                f.write(',\n'.join(batch))
                f.write(';\n\n')
                
                total_exported += len(batch)
                print(f"  Exported {total_exported}/{count} records...")
                batch = []
        
        # Write remaining batch
        if batch:
            f.write("REPLACE INTO drugs (id, trade_name, arabic_name, old_price, price, active, ")
            f.write("main_category, main_category_ar, category, category_ar, company, ")
            f.write("dosage_form, dosage_form_ar, unit, usage, usage_ar, description, ")
            f.write("last_price_update, concentration, visits) VALUES\n")
            f.write(',\n'.join(batch))
            f.write(';\n\n')
            total_exported += len(batch)
    
    conn.close()
    
    # Get file size
    file_size = Path(output_path).stat().st_size / (1024 * 1024)  # MB
    
    print(f"\n✅ Export complete!")
    print(f"   Total records: {total_exported}")
    print(f"   Output file: {output_path}")
    print(f"   File size: {file_size:.2f} MB")
    
    return True

if __name__ == '__main__':
    db_file = sys.argv[1] if len(sys.argv) > 1 else 'assets/medications.db'
    output_file = sys.argv[2] if len(sys.argv) > 2 else 'd1_import.sql'
    
    success = export_to_sql(db_file, output_file)
    sys.exit(0 if success else 1)
