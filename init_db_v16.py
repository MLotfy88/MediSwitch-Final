#!/usr/bin/env python3
"""
Initialize mediswitch.db with V16 schema and seed drugs from meds.csv
"""
import sqlite3
import csv
import os

DB_PATH = "mediswitch.db"
CSV_PATH = "assets/meds.csv"

def init_db():
    if os.path.exists(DB_PATH):
        print(f"🗑️ Removing existing {DB_PATH}...")
        os.remove(DB_PATH)
        
    print(f"🚀 Initializing {DB_PATH} with V16 Schema...")
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    
    # 1. Create DRUGS Table (V16)
    print("  📦 Creating drugs table...")
    c.execute("""
    CREATE TABLE drugs (
        id INTEGER PRIMARY KEY,
        trade_name TEXT NOT NULL,
        arabic_name TEXT,
        price TEXT,
        old_price TEXT,
        category TEXT,
        active TEXT,
        company TEXT,
        dosage_form TEXT,
        dosage_form_ar TEXT,
        concentration REAL,
        unit TEXT,
        usage TEXT,
        pharmacology TEXT,
        barcode TEXT,
        qr_code TEXT,
        visits INTEGER,
        last_price_update TEXT,
        updated_at INTEGER DEFAULT 0,
        indication TEXT,
        mechanism_of_action TEXT,
        pharmacodynamics TEXT,
        data_source_pharmacology TEXT,
        has_drug_interaction INTEGER DEFAULT 0,
        has_food_interaction INTEGER DEFAULT 0,
        has_disease_interaction INTEGER DEFAULT 0,
        description TEXT,
        atc_codes TEXT,
        external_links TEXT
    )
    """)
    c.execute("CREATE INDEX idx_trade_name ON drugs(trade_name)")

    # 2. Create Drug Interactions Table
    print("  🧪 Creating drug_interactions table...")
    c.execute("""
    CREATE TABLE drug_interactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ingredient1 TEXT,
        ingredient2 TEXT,
        severity TEXT,
        effect TEXT,
        arabic_effect TEXT,
        recommendation TEXT,
        arabic_recommendation TEXT,
        management_text TEXT,
        mechanism_text TEXT,
        alternatives_a TEXT,
        alternatives_b TEXT,
        risk_level TEXT,
        ddinter_id TEXT,
        source TEXT,
        type TEXT,
        metabolism_info TEXT,
        source_url TEXT,
        reference_text TEXT,
        updated_at INTEGER DEFAULT 0
    )
    """)
    c.execute("CREATE INDEX idx_rules_pair ON drug_interactions(ingredient1, ingredient2)")

    # 3. Create Food Interactions Table (Granular)
    print("  apple Creating food_interactions table...")
    c.execute("""
    CREATE TABLE food_interactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        med_id INTEGER NOT NULL,
        trade_name TEXT,
        interaction TEXT NOT NULL,
        ingredient TEXT,
        severity TEXT,
        management_text TEXT,
        mechanism_text TEXT,
        reference_text TEXT,
        source TEXT DEFAULT 'DrugBank',
        created_at INTEGER DEFAULT 0
    )
    """)
    c.execute("CREATE INDEX idx_food_med_id ON food_interactions(med_id)")

    # 4. Create Disease Interactions Table
    print("  🏥 Creating disease_interactions table...")
    c.execute("""
    CREATE TABLE disease_interactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        med_id INTEGER NOT NULL,
        trade_name TEXT,
        disease_name TEXT NOT NULL,
        interaction_text TEXT NOT NULL,
        severity TEXT,
        reference_text TEXT,
        source TEXT DEFAULT 'DDInter',
        created_at INTEGER DEFAULT 0
    )
    """)
    c.execute("CREATE INDEX idx_disease_med_id ON disease_interactions(med_id)")
    
    # 5. Create Dosage Guidelines
    print("  📏 Creating dosage_guidelines table...")
    c.execute("""
    CREATE TABLE dosage_guidelines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        med_id INTEGER NOT NULL,
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
    """)
    c.execute("CREATE INDEX idx_guideline_med_id ON dosage_guidelines(med_id)")
    
    # 6. Create Med Ingredients
    print("  🧩 Creating med_ingredients table...")
    c.execute("""
    CREATE TABLE med_ingredients (
        med_id INTEGER,
        ingredient TEXT,
        updated_at INTEGER DEFAULT 0,
        PRIMARY KEY (med_id, ingredient)
    )
    """)
    c.execute("CREATE INDEX idx_mi_mid ON med_ingredients(med_id)")

    # Seed Drugs from CSV
    print(f"  📥 Seeding drugs from {CSV_PATH}...")
    if not os.path.exists(CSV_PATH):
        print("❌ meds.csv not found!")
        return

    count = 0
    with open(CSV_PATH, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            try:
                drug_id = int(row.get('id'))
                if not drug_id: continue
                
                c.execute("""
                INSERT INTO drugs (
                    id, trade_name, arabic_name, price, old_price, category,
                    active, company, dosage_form, dosage_form_ar, concentration,
                    unit, usage, pharmacology, barcode, qr_code, visits, last_price_update
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    drug_id,
                    row.get('trade_name'),
                    row.get('arabic_name'),
                    row.get('price'),
                    row.get('old_price'),
                    row.get('category'),
                    row.get('active'),
                    row.get('company'),
                    row.get('dosage_form'),
                    row.get('dosage_form_ar'),
                    row.get('concentration'),
                    row.get('units'), # Note: 'units' in CSV maps to 'unit' in DB
                    row.get('usage'),
                    row.get('pharmacology'),
                    row.get('barcode'),
                    row.get('qr_code'),
                    row.get('visits', 0),
                    row.get('last_price_update')
                ))
                count += 1
            except Exception as e:
                print(f"    ⚠️ Error on row {row}: {e}")
                
    conn.commit()
    conn.close()
    print(f"✅ Initialized mediswitch.db with {count} drugs.")

if __name__ == "__main__":
    init_db()
