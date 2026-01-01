
import sqlite3
import json
import os
import csv
from typing import List, Dict, Any

# --- Configuration ---
DDINTER_DB_PATH = 'assets/external_research_data/updated/ddinter_complete.db'
OUTPUT_DIR = 'assets/data/interactions/enriched'
RAW_CSV_PATH = 'assets/external_research_data/ddinter_interactions_v6.csv'

def connect_db(db_path):
    """Connect to SQLite database."""
    if not os.path.exists(db_path):
        print(f"❌ Error: Database not found at {db_path}")
        return None
    return sqlite3.connect(db_path)

def load_mechanism_map(csv_path: str) -> Dict[str, str]:
    """Load mechanism descriptions from raw CSV (Legacy support)."""
    mapping = {}
    if not os.path.exists(csv_path):
        print(f"⚠️ Warning: Mechanism CSV not found at {csv_path}")
        return mapping
        
    print(f"📖 Loading mechanisms from {csv_path}...")
    try:
        with open(csv_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                idx = row.get('idx')
                mech = row.get('mechanisms')
                if idx and mech:
                    mech = ' '.join(mech.split()).strip()
                    if mech:
                        mapping[str(idx)] = mech
    except Exception as e:
        print(f"❌ Error loading mechanisms: {e}")
    return mapping

def fetch_drug_drug_interactions(conn, mechanism_map) -> List[Dict]:
    """Fetch enriched DDI data with updated fields."""
    print("🚀 Fetching Drug-Drug Interactions...")
    c = conn.cursor()
    
    # Query updated schema
    # Note: We join with drugs table to get drug names
    sql = """
        SELECT 
            d1.drug_name as drug_a,
            d2.drug_name as drug_b,
            di.severity,
            di.interaction_description,
            di.management_text,
            di.mechanism_flags,
            di.alternative_drugs_a,
            di.alternative_drugs_b,
            di.interaction_id,
            d1.ddinter_id as id_a,
            d2.ddinter_id as id_b
        FROM drug_drug_interactions di
        JOIN drugs d1 ON di.drug_a_id = d1.ddinter_id
        JOIN drugs d2 ON di.drug_b_id = d2.ddinter_id
        WHERE di.interaction_description IS NOT NULL
    """
    
    try:
        c.execute(sql)
        rows = c.fetchall()
        results = []
        
        for r in rows:
            inter_id = str(r[8])
            mech_json = r[5]
            mech_text = None
            
            # 1. Try DB Mechanism Flags
            if mech_json:
                try:
                    mechs = json.loads(mech_json)
                    if mechs:
                        mech_text = ", ".join(mechs)
                except:
                    pass
            
            # 2. Fallback to CSV Map
            if not mech_text and mechanism_map:
                mech_text = mechanism_map.get(inter_id)

            results.append({
                'ingredient1': r[0],
                'ingredient2': r[1],
                'severity': r[2],
                'effect': r[3],
                'arabic_effect': None,
                'recommendation': None,
                'arabic_recommendation': None,
                'management_text': r[4],
                'mechanism_text': mech_text,
                'alternatives_a': r[6], # JSON string
                'alternatives_b': r[7], # JSON string
                'risk_level': r[2],
                'ddinter_id': r[8],
                'source': 'DDInter'
            })
            
        print(f"✅ Fetched {len(results)} enriched DDIs.")
        return results
    except Exception as e:
        print(f"❌ Error fetching DDI: {e}")
        return []

def export_disease_interactions(conn, output_dir):
    """Export Drug-Disease Interactions to JSON."""
    print("🚀 Exporting Disease Interactions...")
    c = conn.cursor()
    try:
        c.execute('''
            SELECT d.ddinter_id, d.drug_name, di.disease_name, di.severity, di.interaction_text, di.reference_text
            FROM drug_disease_interactions di
            JOIN drugs d ON di.drug_id = d.ddinter_id
        ''')
        
        rows = c.fetchall()
        results = []
        for r in rows:
            results.append({
                'ddinter_id': r[0],
                'trade_name': r[1],
                'disease_name': r[2],
                'severity': r[3],
                'interaction_text': r[4],
                'references': r[5],
                'source': 'DDInter'
            })
            
        out_path = os.path.join(output_dir, 'enriched_disease_interactions.json')
        with open(out_path, 'w', encoding='utf-8') as f:
            json.dump(results, f, ensure_ascii=False, indent=2)
        print(f"✅ Exported {len(results)} disease interactions to {out_path}")
    except Exception as e:
        print(f"⚠️ Error exporting disease interactions (Table might be empty/missing): {e}")

def export_food_interactions(conn, output_dir):
    """Export Drug-Food Interactions to JSON."""
    print("🚀 Exporting Food Interactions...")
    c = conn.cursor()
    try:
        c.execute('''
            SELECT d.ddinter_id, d.drug_name, fi.food_name, fi.severity, fi.description, fi.management, fi.mechanism_flags
            FROM drug_food_interactions fi
            JOIN drugs d ON fi.drug_id = d.ddinter_id
        ''')
        
        rows = c.fetchall()
        results = []
        for r in rows:
            mech = r[6]
            if mech:
                try:
                    m_list = json.loads(mech)
                    if m_list: mech = ", ".join(m_list)
                except: pass
            
            results.append({
                 'ddinter_id': r[0],
                 'trade_name': r[1],
                 'food_name': r[2],
                 'severity': r[3],
                 'interaction': f"{r[4]}\n\nManagement: {r[5]}",
                 'mechanism': mech,
                 'source': 'DDInter'
            })

        out_path = os.path.join(output_dir, 'enriched_food_interactions.json')
        with open(out_path, 'w', encoding='utf-8') as f:
            json.dump(results, f, ensure_ascii=False, indent=2)
        print(f"✅ Exported {len(results)} food interactions to {out_path}")
    except Exception as e:
        print(f"⚠️ Error exporting food interactions: {e}")

def main():
    print("🌟 Starting Enrichment Pipeline v5...")
    
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)
        
    conn = connect_db(DDINTER_DB_PATH)
    if not conn:
        return

    # 1. Load Legacy Map
    mech_map = load_mechanism_map(RAW_CSV_PATH)

    # 2. Export New Data Types (Disease, Food)
    export_disease_interactions(conn, OUTPUT_DIR)
    export_food_interactions(conn, OUTPUT_DIR)
    
    # 3. Export Main Drug-Drug Interactions
    ddi_data = fetch_drug_drug_interactions(conn, mech_map)
    
    if ddi_data:
        # Split into chunks
        chunk_size = 5000
        total = len(ddi_data)
        print(f"📦 Splitting {total} records into chunks...")
        
        for i in range(0, total, chunk_size):
            chunk = ddi_data[i:i + chunk_size]
            part_num = (i // chunk_size) + 1
            part_path = os.path.join(OUTPUT_DIR, f'enriched_rules_part_{part_num:03d}.json')
            
            with open(part_path, 'w', encoding='utf-8') as f:
                json.dump({'data': chunk}, f, ensure_ascii=False, indent=2)
        
        print(f"✅ Created {(total // chunk_size) + 1} JSON parts.")
        
    conn.close()
    print("🎉 Pipeline Completed Successfully!")

if __name__ == '__main__':
    main()
