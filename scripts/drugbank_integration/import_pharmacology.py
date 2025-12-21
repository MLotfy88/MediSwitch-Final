#!/usr/bin/env python3
"""
Phase 2: Import Pharmacology Data
==================================
Import matched pharmacology data into the database.
"""

import csv
import sqlite3
from pathlib import Path


def update_database_schema(db_path: str):
    """Add pharmacology columns to the drugs table."""
    print("🔧 Updating database schema...")
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Add new columns if they don't exist
    columns_to_add = [
        ('indication', 'TEXT'),
        ('mechanism_of_action', 'TEXT'),
        ('pharmacodynamics', 'TEXT'),
        ('data_source_pharmacology', 'TEXT'),
    ]
    
    for column_name, column_type in columns_to_add:
        try:
            cursor.execute(f"ALTER TABLE drugs ADD COLUMN {column_name} {column_type}")
            print(f"   ✅ Added column: {column_name}")
        except sqlite3.OperationalError as e:
            if 'duplicate column name' in str(e).lower():
                print(f"   ℹ️  Column already exists: {column_name}")
            else:
                raise
    
    conn.commit()
    conn.close()
    print("✅ Schema updated successfully!\n")


def import_pharmacology_data(db_path: str, matched_csv: str):
    """Import pharmacology data from matched drugs CSV."""
    print("📥 Importing pharmacology data...")
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Read matched drugs
    with open(matched_csv, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        matches = list(reader)
    
    print(f"   Found {len(matches)} matched drugs to import")
    
    updated_count = 0
    skipped_count = 0
    
    for match in matches:
        dailymed_id = match['dailymed_id']
        indication = match['indication']
        mechanism = match['mechanism_of_action']
        pharmacodynamics = match['pharmacodynamics']
        
        # Only update if we have meaningful data
        if indication or mechanism or pharmacodynamics:
            cursor.execute("""
                UPDATE drugs
                SET indication = ?,
                    mechanism_of_action = ?,
                    pharmacodynamics = ?,
                    data_source_pharmacology = 'DrugBank'
                WHERE id = ?
            """, (indication, mechanism, pharmacodynamics, dailymed_id))
            
            if cursor.rowcount > 0:
                updated_count += 1
        else:
            skipped_count += 1
    
    conn.commit()
    conn.close()
    
    print(f"✅ Pharmacology import complete!")
    print(f"   Updated: {updated_count} drugs")
    print(f"   Skipped (no data): {skipped_count} drugs\n")
    
    return updated_count


def verify_import(db_path: str):
    """Verify the import was successful."""
    print("🔍 Verifying import...")
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Count drugs with pharmacology data
    cursor.execute("""
        SELECT COUNT(*) 
        FROM drugs 
        WHERE indication IS NOT NULL AND indication != ''
    """)
    indication_count = cursor.fetchone()[0]
    
    cursor.execute("""
        SELECT COUNT(*) 
        FROM drugs 
        WHERE mechanism_of_action IS NOT NULL AND mechanism_of_action != ''
    """)
    mechanism_count = cursor.fetchone()[0]
    
    cursor.execute("""
        SELECT COUNT(*) 
        FROM drugs 
        WHERE data_source_pharmacology = 'DrugBank'
    """)
    drugbank_count = cursor.fetchone()[0]
    
    # Get a sample
    cursor.execute("""
        SELECT tradeName, active, indication
        FROM drugs
        WHERE data_source_pharmacology = 'DrugBank'
        LIMIT 5
    """)
    samples = cursor.fetchall()
    
    conn.close()
    
    print(f"✅ Verification complete!")
    print(f"   Drugs with indication: {indication_count}")
    print(f"   Drugs with mechanism: {mechanism_count}")
    print(f"   Drugs from DrugBank: {drugbank_count}")
    
    print(f"\n📋 Sample imported drugs:")
    print("="*80)
    for trade_name, active, indication in samples:
        indication_preview = indication[:100] + "..." if len(indication) > 100 else indication
        print(f"   • {trade_name} ({active})")
        print(f"     {indication_preview}\n")


def main():
    """Main execution."""
    print("🚀 Phase 2: Import Pharmacology Data")
    print("="*80 + "\n")
    
    db_path = "/home/adminlotfy/project/mediswitch.db"
    matched_csv = "/home/adminlotfy/project/scripts/drugbank_integration/output/matched_drugs.csv"
    
    # Step 1: Update schema
    update_database_schema(db_path)
    
    # Step 2: Import data
    updated_count = import_pharmacology_data(db_path, matched_csv)
    
    # Step 3: Verify
    verify_import(db_path)
    
    print("="*80)
    print("✅ Pharmacology import completed successfully!")
    print(f"   Total drugs updated: {updated_count}")


if __name__ == "__main__":
    main()
