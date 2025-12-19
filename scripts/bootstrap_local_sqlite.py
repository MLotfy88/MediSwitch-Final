#!/usr/bin/env python3
import csv
import json
import sqlite3
import os
import glob
from datetime import datetime

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MEDS_CSV = os.path.join(BASE_DIR, 'assets', 'meds.csv')
DOSAGES_JSON = os.path.join(BASE_DIR, 'assets', 'data', 'dosage_guidelines.json')
RULES_PATTERN = os.path.join(BASE_DIR, 'assets', 'data', 'interactions', 'rules_part_*.json')
INGREDIENTS_PATTERN = os.path.join(BASE_DIR, 'assets', 'data', 'interactions', 'ingredients_part_*.json')
DB_PATH = os.path.join(BASE_DIR, 'mediswitch.db')

def bootstrap():
    print(f"🚀 Bootstrapping local database at {DB_PATH}...")
    
    # Remove existing if any
    if os.path.exists(DB_PATH):
        os.remove(DB_PATH)
        print("🗑️ Removed existing mediswitch.db")

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    # 1. Create Schema
    print("🏗️ Creating schema...")
    cursor.execute('''
        CREATE TABLE drugs (
            tradeName TEXT PRIMARY KEY,
            id INTEGER,
            arabicName TEXT,
            price TEXT,
            oldPrice TEXT,
            mainCategory TEXT,
            category TEXT,
            category_ar TEXT,
            active TEXT,
            company TEXT,
            dosageForm TEXT,
            dosageForm_ar TEXT,
            concentration REAL,
            unit TEXT,
            usage TEXT,
            usage_ar TEXT,
            description TEXT,
            barcode TEXT,
            visits INTEGER,
            lastPriceUpdate TEXT,
            imageUrl TEXT,
            updatedAt INTEGER DEFAULT 0
        )
    ''')

    cursor.execute('''
        CREATE TABLE dosage_guidelines (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            med_id INTEGER,
            dailymed_setid TEXT,
            min_dose REAL,
            max_dose REAL,
            frequency INTEGER,
            duration INTEGER,
            instructions TEXT,
            condition TEXT,
            source TEXT,
            is_pediatric INTEGER
        )
    ''')

    cursor.execute('''
        CREATE TABLE drug_interactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ingredient1 TEXT,
            ingredient2 TEXT,
            severity TEXT,
            effect TEXT,
            source TEXT,
            updated_at INTEGER DEFAULT 0
        )
    ''')

    cursor.execute('''
        CREATE TABLE med_ingredients (
            med_id INTEGER,
            ingredient TEXT,
            PRIMARY KEY (med_id, ingredient)
        )
    ''')

    # 2. Seed Medicines
    print(f"💊 Seeding Medicines from {MEDS_CSV}...")
    with open(MEDS_CSV, 'r', encoding='utf-8-sig') as f:
        reader = csv.DictReader(f)
        meds_count = 0
        ing_count = 0
        for row in reader:
            # Map CSV 18-column schema to Table columns
            # CSV Headers: id,trade_name,arabic_name,active,category,company,price,old_price,last_price_update,units,barcode,qr_code,pharmacology,usage,visits,concentration,dosage_form,dosage_form_ar
            
            med_id = int(row['id']) if row['id'] and row['id'].isdigit() else None
            
            try:
                cursor.execute('''
                    INSERT INTO drugs (
                        id, tradeName, arabicName, active, category, company, 
                        price, oldPrice, lastPriceUpdate, unit, barcode, 
                        description, usage, visits, concentration, 
                        dosageForm, dosageForm_ar, mainCategory
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ''', (
                    med_id,
                    row['trade_name'],
                    row['arabic_name'],
                    row['active'],
                    row['category'],
                    row['company'],
                    row['price'],
                    row['old_price'],
                    row['last_price_update'],
                    row['units'],
                    row['barcode'],
                    row['pharmacology'], # description
                    row['usage'],
                    int(row['visits']) if row['visits'] and row['visits'].isdigit() else 0,
                    row['concentration'],
                    row['dosage_form'],
                    row['dosage_form_ar'],
                    row['category'] # mainCategory
                ))
                meds_count += 1
                
                # Seed Ingredients
                if med_id and row['active']:
                    import re
                    ingredients = [i.strip().lower() for i in re.split(r'[+;,/]', row['active']) if i.strip()]
                    for ing in ingredients:
                        try:
                            cursor.execute('INSERT OR IGNORE INTO med_ingredients (med_id, ingredient) VALUES (?, ?)', (med_id, ing))
                            ing_count += 1
                        except: pass
            except Exception as e:
                print(f"⚠️ Error inserting drug {row['trade_name']}: {e}")

    print(f"✅ Seeded {meds_count} drugs and {ing_count} ingredient mappings.")

    # 3. Seed Dosages
    if os.path.exists(DOSAGES_JSON):
        print(f"📏 Seeding Dosages from {DOSAGES_JSON}...")
        with open(DOSAGES_JSON, 'r', encoding='utf-8') as f:
            data = json.load(f)
            # Check structure (Legacy vs New)
            dosages = data if isinstance(data, list) else data.get('dosage_guidelines', [])
            
            d_count = 0
            for d in dosages:
                cursor.execute('''
                    INSERT INTO dosage_guidelines (
                        med_id, dailymed_setid, min_dose, max_dose, frequency, 
                        duration, instructions, condition, source, is_pediatric
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ''', (
                    d.get('med_id'),
                    d.get('dailymed_setid'),
                    d.get('min_dose'),
                    d.get('max_dose'),
                    d.get('frequency'),
                    d.get('duration'),
                    d.get('instructions'),
                    d.get('condition'),
                    d.get('source'),
                    1 if d.get('is_pediatric') else 0
                ))
                d_count += 1
        print(f"✅ Seeded {d_count} dosage guidelines.")

    # 4. Seed Interactions
    print("🧪 Seeding Interactions...")
    rule_count = 0
    for fpath in sorted(glob.glob(RULES_PATTERN)):
        with open(fpath, 'r', encoding='utf-8') as f:
            content = json.load(f)
            rules = content.get('data', [])
            for r in rules:
                cursor.execute('''
                    INSERT INTO drug_interactions (ingredient1, ingredient2, severity, effect, source)
                    VALUES (?, ?, ?, ?, ?)
                ''', (
                    r['ingredient1'],
                    r['ingredient2'],
                    r['severity'],
                    r.get('effect') or r.get('description'),
                    r['source']
                ))
                rule_count += 1
    print(f"✅ Seeded {rule_count} interaction rules.")

    conn.commit()
    conn.close()
    print(f"🎉 All done! Database ready at {DB_PATH}")

if __name__ == "__main__":
    bootstrap()
