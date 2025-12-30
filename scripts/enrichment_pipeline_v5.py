import sqlite3
import csv
import json
import os
import re
from typing import List, Dict, Set
import sys

# Import synonym dictionary
sys.path.insert(0, os.path.dirname(__file__))
from drug_synonyms import DRUG_SYNONYMS

# Configuration
DDINTER_DB_PATH = 'ddinter_data/ddinter_complete.db'
LOCAL_MEDS_CSV = 'assets/meds.csv'
OUTPUT_DIR = 'assets/data/interactions/enriched'
CHUNK_SIZE = 1000

# Regex for splitting ingredients
INGREDIENT_SEPARATORS = re.compile(r'[+;/,]|\s+and\s+|\s+with\s+', re.IGNORECASE)

def normalize_ingredient(text: str) -> str:
    """Advanced normalization"""
    if not text:
        return ""
    text = text.lower().strip()
    text = re.sub(r'\d+\s*(mg|mcg|g|ml|iu|i\.u\.|%)', '', text, flags=re.IGNORECASE)
    text = re.sub(r'\([^)]*\)', '', text)
    suffixes = [
        ' hydrochloride', ' hcl', ' sulfate', ' sulphate', ' sodium', 
        ' calcium', ' magnesium', ' potassium', ' acetate', ' chloride', 
        ' maleate', ' citrate', ' phosphate', ' succinate', ' tartrate', 
        ' mesylate', ' besylate', ' fumarate', ' gluconate', ' lactate',
        ' bromide', ' nitrate', ' oxalate', ' stearate', ' benzoate'
    ]
    for suffix in suffixes:
        text = text.replace(suffix, '')
    text = re.sub(r'[^a-z0-9\s]', ' ', text)
    text = ' '.join(text.split())
    return text.strip()

def connect_db(db_path):
    try:
        conn = sqlite3.connect(db_path)
        conn.row_factory = sqlite3.Row
        return conn
    except sqlite3.Error as e:
        print(f"Error connecting to database {db_path}: {e}")
        return None

def get_local_meds(csv_path: str) -> List[Dict]:
    meds = []
    try:
        with open(csv_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                meds.append({
                    'id': row.get('id'),
                    'trade_name': row.get('trade_name', ''),
                    'active': row.get('active', '')
                })
    except Exception as e:
        print(f"Error reading {csv_path}: {e}")
    return meds

def build_ddinter_index(conn):
    cursor = conn.execute("SELECT ddinter_id, drug_name FROM drugs")
    index = {}
    for row in cursor.fetchall():
        ddinter_id = row['ddinter_id']
        drug_name = row['drug_name']
        normalized = normalize_ingredient(drug_name)
        if normalized:
            index[normalized] = ddinter_id
        index[drug_name.lower().strip()] = ddinter_id
    return index

def find_ddinter_id(ddinter_index: Dict, ingredient: str) -> str:
    synonym = DRUG_SYNONYMS.get(ingredient.lower().strip())
    if synonym:
        syn_normalized = normalize_ingredient(synonym)
        if syn_normalized in ddinter_index: return ddinter_index[syn_normalized]
        if synonym.lower().strip() in ddinter_index: return ddinter_index[synonym.lower().strip()]
    
    normalized = normalize_ingredient(ingredient)
    if normalized in ddinter_index: return ddinter_index[normalized]
    if ingredient.lower().strip() in ddinter_index: return ddinter_index[ingredient.lower().strip()]
    return None

def split_compound_ingredients(active_str: str) -> List[str]:
    if not active_str: return []
    ingredients = INGREDIENT_SEPARATORS.split(active_str)
    return [i.strip() for i in ingredients if i.strip() and len(i.strip()) > 1]

def fetch_interactions(conn, ddinter_id: str) -> List[Dict]:
    try:
        sql = """
            SELECT d.drug_name, di.severity, di.interaction_description, 
                   di.management_text, di.mechanism_flags, di.interaction_id
            FROM drug_drug_interactions di
            JOIN drugs d ON di.drug_b_id = d.ddinter_id
            WHERE di.drug_a_id = ?
        """
        cursor = conn.execute(sql, (ddinter_id,))
        return [{
            'ingredient2': r['drug_name'],
            'severity': r['severity'],
            'effect': r['interaction_description'],
            'management_text': r['management_text'],
            'mechanism_text': r['mechanism_flags'],
            'risk_level': r['severity'],
            'source': 'DDInter',
            'ddinter_id': r['interaction_id']
        } for r in cursor.fetchall()]
    except:
        return []

def fetch_food_interactions(conn, ddinter_id: str) -> List[Dict]:
    try:
        sql = "SELECT food_name, severity, description, management FROM drug_food_interactions WHERE drug_id = ?"
        cursor = conn.execute(sql, (ddinter_id,))
        return [{
            'food_name': r['food_name'],
            'severity': r['severity'],
            'description': r['description'],
            'management': r['management']
        } for r in cursor.fetchall()]
    except:
        return []

def fetch_disease_interactions(conn, ddinter_id: str) -> List[Dict]:
    """Fetch drug-disease interactions (contraindications)."""
    try:
        sql = "SELECT disease_name, interaction_text FROM drug_disease_interactions WHERE drug_id = ?"
        cursor = conn.execute(sql, (ddinter_id,))
        return [{
            'disease_name': r['disease_name'],
            'interaction_text': r['interaction_text']
        } for r in cursor.fetchall()]
    except:
        return []

def process_pipeline():
    print("🚀 Enhanced Enrichment Pipeline v5 (DDI + Food + Disease)\n")
    print("=" * 70)
    
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)
        
    conn_ddinter = connect_db(DDINTER_DB_PATH)
    if not conn_ddinter: return

    print("📝 Building Index...")
    ddinter_index = build_ddinter_index(conn_ddinter)
    print(f"   Index size: {len(ddinter_index):,}")

    local_meds = get_local_meds(LOCAL_MEDS_CSV)
    print(f"📦 Loaded {len(local_meds):,} local medicines\n")
    
    all_rules = []
    all_food_interactions = []
    all_disease_interactions = []
    
    processed_pairs = set()
    processed_food_pairs = set()
    processed_disease_pairs = set()
    
    stats = {
        'total_meds': 0, 'meds_with_match': 0,
        'ddi_rules': 0, 'dfi_rules': 0, 'dsci_rules': 0
    }

    print("🔄 Processing medicines...")
    
    for i_med, med in enumerate(local_meds):
        stats['total_meds'] += 1
        active_str = med['active']
        med_id = med['id']
        trade_name = med['trade_name']
        
        if not active_str or not med_id: continue
        
        ingredients = split_compound_ingredients(active_str)
        med_matched = False
        
        for ingredient in ingredients:
            ddinter_id = find_ddinter_id(ddinter_index, ingredient)
            
            if ddinter_id:
                med_matched = True
                
                # 1. Drug-Drug (DDI)
                interactions = fetch_interactions(conn_ddinter, ddinter_id)
                for rule in interactions:
                    key = tuple(sorted((normalize_ingredient(ingredient), normalize_ingredient(rule['ingredient2']))))
                    if key in processed_pairs: continue
                    processed_pairs.add(key)
                    new_rule = rule.copy()
                    new_rule['ingredient1'] = ingredient
                    all_rules.append(new_rule)
                
                # 2. Drug-Food (DFI)
                food_interactions = fetch_food_interactions(conn_ddinter, ddinter_id)
                for food in food_interactions:
                    food_key = (med_id, food['food_name'])
                    if food_key in processed_food_pairs: continue
                    processed_food_pairs.add(food_key)
                    
                    formatted_text = f"{food['food_name'].upper()}: {food['description']}"
                    if food['management']: formatted_text += f"\n\nManagement: {food['management']}"
                    
                    all_food_interactions.append({
                        'med_id': int(med_id),
                        'trade_name': trade_name,
                        'interaction': formatted_text,
                        'source': 'DDInter'
                    })
                
                # 3. Drug-Disease (DScI)
                disease_interactions = fetch_disease_interactions(conn_ddinter, ddinter_id)
                for disease in disease_interactions:
                    disease_key = (med_id, disease['disease_name'])
                    if disease_key in processed_disease_pairs: continue
                    processed_disease_pairs.add(disease_key)
                    
                    all_disease_interactions.append({
                        'med_id': int(med_id),
                        'trade_name': trade_name,
                        'disease_name': disease['disease_name'],
                        'interaction_text': disease['interaction_text'],
                        'source': 'DDInter'
                    })
        
        if med_matched: stats['meds_with_match'] += 1
        if (i_med + 1) % 2000 == 0:
            print(f"   Processed {i_med + 1:,} meds | DDI: {len(all_rules):,} | DFI: {len(all_food_interactions):,} | DScI: {len(all_disease_interactions):,}", flush=True)

    conn_ddinter.close()
    
    # Save Outputs
    # 1. DDI (Chunked)
    print(f"\n💾 Saving DDI Rules...")
    total_chunks = (len(all_rules) // CHUNK_SIZE) + 1
    for i in range(total_chunks):
        chunk_data = all_rules[i*CHUNK_SIZE : (i+1)*CHUNK_SIZE]
        if not chunk_data: continue
        with open(os.path.join(OUTPUT_DIR, f'enriched_rules_part_{i+1:03d}.json'), 'w', encoding='utf-8') as f:
            json.dump({'data': chunk_data}, f, ensure_ascii=False, indent=2)
            
    # 2. Food (Single)
    print(f"💾 Saving Food Interactions...")
    with open(os.path.join(OUTPUT_DIR, 'enriched_food_interactions.json'), 'w', encoding='utf-8') as f:
        json.dump(all_food_interactions, f, ensure_ascii=False, indent=2)

    # 3. Disease (Single)
    print(f"💾 Saving Disease Interactions...")
    with open(os.path.join(OUTPUT_DIR, 'enriched_disease_interactions.json'), 'w', encoding='utf-8') as f:
        json.dump(all_disease_interactions, f, ensure_ascii=False, indent=2)
    
    print("=" * 70)
    print("📊 FINAL RESULTS (v5):")
    print(f"Total Medicines: {stats['total_meds']:,}")
    print(f"Matched: {stats['meds_with_match']:,}")
    print(f"Drug-Drug Interactions (DDI): {len(all_rules):,}")
    print(f"Drug-Food Interactions (DFI): {len(all_food_interactions):,}")
    print(f"Drug-Disease Interactions (DScI): {len(all_disease_interactions):,}")
    print("=" * 70)

if __name__ == '__main__':
    process_pipeline()
