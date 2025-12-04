#!/usr/bin/env python3
"""
Update local SQLite database from enriched CSV
"""

import sqlite3
import pandas as pd
import sys
from pathlib import Path

def update_local_database(csv_file='meds_enriched.csv', db_file='assets/medications.db'):
    """Update local database with enriched data"""
    
    print(f"📖 Reading {csv_file}...")
    df = pd.read_csv(csv_file, encoding='utf-8-sig')
    
    print(f"📦 Found {len(df)} drugs")
    
    # Ensure database directory exists
    Path(db_file).parent.mkdir(parents=True, exist_ok=True)
    
    print(f"🗄️  Connecting to {db_file}...")
    conn = sqlite3.connect(db_file)
    cursor = conn.cursor()
    
    # Create table if not exists
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS medications (
            id INTEGER PRIMARY KEY,
            trade_name TEXT NOT NULL,
            arabic_name TEXT,
            old_price REAL,
            price REAL,
            active TEXT,
            main_category TEXT,
            main_category_ar TEXT,
            category TEXT,
            category_ar TEXT,
            company TEXT,
            dosage_form TEXT,
            dosage_form_ar TEXT,
            unit TEXT,
            usage TEXT,
            usage_ar TEXT,
            description TEXT,
            last_price_update TEXT,
            concentration TEXT,
            visits INTEGER DEFAULT 0
        )
    ''')
    
    # Use UPSERT logic instead of clearing data
    print("🔄 Upserting data (updating existing records, inserting new ones)...")
    for idx, row in df.iterrows():
        cursor.execute('''
            INSERT OR REPLACE INTO medications VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            row.get('id'),
            row.get('trade_name'),
            row.get('arabic_name', ''),
            row.get('old_price', 0),
            row.get('price', 0),
            row.get('active', ''),
            row.get('main_category', ''),
            row.get('main_category_ar', ''),
            row.get('category', ''),
            row.get('category_ar', ''),
            row.get('company', ''),
            row.get('dosage_form', ''),
            row.get('dosage_form_ar', ''),
            row.get('unit', '1'),
            row.get('usage', ''),
            row.get('usage_ar', ''),
            row.get('description', ''),
            row.get('last_price_update', ''),
            row.get('concentration', ''),
            row.get('visits', 0)
        ))
        
        if (idx + 1) % 1000 == 0:
            print(f"  Inserted {idx + 1} / {len(df)} drugs...")
    
    # Commit and close
    conn.commit()
    conn.close()
    
    print(f"✅ Successfully updated {db_file}")
    print(f"   Total drugs: {len(df)}")
    
    # Verify
    conn = sqlite3.connect(db_file)
    cursor = conn.cursor()
    count = cursor.execute('SELECT COUNT(*) FROM medications').fetchone()[0]
    conn.close()
    
    print(f"✅ Verified: {count} drugs in database")

if __name__ == '__main__':
    csv_file = sys.argv[1] if len(sys.argv) > 1 else 'meds_enriched.csv'
    db_file = sys.argv[2] if len(sys.argv) > 2 else 'assets/medications.db'
    
    update_local_database(csv_file, db_file)
