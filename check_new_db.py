
import sqlite3
import os

db_path = 'assets/external_research_data/updated/ddinter_complete.db'

if not os.path.exists(db_path):
    print(f"❌ DB not found at {db_path}")
    exit(1)

try:
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    
    tables = ['drugs', 'drug_drug_interactions', 'drug_food_interactions', 'compound_preparations']
    print(f"📦 Checking DB: {db_path}")
    
    for table in tables:
        c.execute(f"SELECT COUNT(*) FROM {table}")
        count = c.fetchone()[0]
        print(f"📊 {table}: {count:,} rows")
        
    print("\n🔍 Checking for Text Details in drug_drug_interactions:")
    
    # Check Mechanism Flags
    c.execute("SELECT COUNT(*) FROM drug_drug_interactions WHERE mechanism_flags IS NOT NULL AND mechanism_flags != '' AND mechanism_flags != '[]'")
    mech_count = c.fetchone()[0]
    print(f"   - Mechanism Flags: {mech_count:,}")
    
    # Check Descriptions
    c.execute("SELECT COUNT(*) FROM drug_drug_interactions WHERE interaction_description IS NOT NULL AND interaction_description != ''")
    desc_count = c.fetchone()[0]
    print(f"   - Descriptions: {desc_count:,}")
    
    # Check Management
    c.execute("SELECT COUNT(*) FROM drug_drug_interactions WHERE management_text IS NOT NULL AND management_text != ''")
    mgmt_count = c.fetchone()[0]
    print(f"   - Management Text: {mgmt_count:,}")

    # Check Disease Interactions
    c.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='drug_disease_interactions'")
    if c.fetchone():
        c.execute("SELECT COUNT(*) FROM drug_disease_interactions")
        disease_count = c.fetchone()[0]
        print(f"\n🦠 Drug-Disease Interactions: {disease_count:,}")
    else:
        print("\n❌ drug_disease_interactions table does not exist")

    conn.close()

except Exception as e:
    print(f"❌ Error: {e}")
