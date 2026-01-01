import sqlite3
import os
import json

DB_PATH = 'ddinter_complete.db'

def check_db():
    if not os.path.exists(DB_PATH):
        print("❌ Database file not found!")
        return

    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()

    tables = ['drugs', 'drug_drug_interactions', 'drug_food_interactions', 'drug_disease_interactions', 'compound_preparations']
    
    print("\n📊 TABLE ROW COUNTS")
    print("="*30)
    for t in tables:
        try:
            c.execute(f"SELECT COUNT(*) FROM {t}")
            print(f"✅ {t}: {c.fetchone()[0]:,}")
        except Exception as e:
            print(f"❌ {t}: ERROR ({e})")

    print("\n📊 DATA QUALITY (Fill Rates)")
    print("="*30)
    
    # 1. Drug-Drug Interactions
    print("\n🔹 Drug-Drug Interactions Analysis:")
    try:
        c.execute("SELECT COUNT(*) FROM drug_drug_interactions")
        total_ddi = c.fetchone()[0]
        
        fields = {
            'mechanism_flags': 'Mechanisms',
            'interaction_description': 'Description', 
            'management_text': 'Management', 
            'alternative_drugs_a': 'Alternatives A', 
            'alternative_drugs_b': 'Alternatives B'
        }
        
        for col, label in fields.items():
            query = f"SELECT COUNT(*) FROM drug_drug_interactions WHERE {col} IS NOT NULL AND {col} != '' AND {col} != 'null'"
            c.execute(query)
            val = c.fetchone()[0]
            pct = (val/total_ddi)*100 if total_ddi else 0
            icon = "✅" if pct > 0 else "⚠️"
            if pct > 90: icon = "🌟"
            print(f"{icon} {label}: {val:,} ({pct:.1f}%)")
            
    except Exception as e:
        print(f"❌ Error analyzing DDIs: {e}")

    # 2. Drugs
    print("\n🔹 Drugs Basic Info Analysis:")
    try:
        c.execute("SELECT COUNT(*) FROM drugs")
        total_drugs = c.fetchone()[0]
        
        d_fields = {
            'description': 'Description', 
            'atc_codes': 'ATC Codes', 
            'structure_2d_svg': 'SVG Structure'
        }
        for col, label in d_fields.items():
            query = f"SELECT COUNT(*) FROM drugs WHERE {col} IS NOT NULL AND {col} != '' AND {col} != 'null' AND {col} != '[]'"
            c.execute(query)
            val = c.fetchone()[0]
            pct = (val/total_drugs)*100 if total_drugs else 0
            print(f"✅ {label}: {val:,} ({pct:.1f}%)")
            
    except Exception as e:
        print(f"❌ Error analyzing Drugs: {e}")

    conn.close()

if __name__ == '__main__':
    check_db()
