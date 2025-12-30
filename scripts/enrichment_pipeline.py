import sqlite3
import csv
import json
import os
import re
from typing import List, Dict, Set, Tuple

# Configuration
DDINTER_DB_PATH = 'ddinter_data/ddinter_complete.db'
LOCAL_MEDS_CSV = 'assets/meds.csv'
OUTPUT_DIR = 'assets/data/interactions/enriched'
CHUNK_SIZE = 1000

# Regex for splitting ingredients
INGREDIENT_SPLIT_REGEX = re.compile(r'[+;/]')

def connect_db(db_path):
    """Connects to the SQLite database."""
    try:
        conn = sqlite3.connect(db_path)
        conn.row_factory = sqlite3.Row
        return conn
    except sqlite3.Error as e:
        print(f"Error connecting to database {db_path}: {e}")
        return None

def normalize_text(text: str) -> str:
    """Normalizes text for matching (lowercase, trim)."""
    if not text:
        return ""
    return text.lower().strip()

def get_local_meds(csv_path: str) -> List[Dict]:
    """Reads local medicines from CSV."""
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

def find_ddinter_id(conn, query_name: str) -> str:
    """
    Searches for a drug in DDInter by name (mimicking Trade Name or Ingredient lookup).
    DDInter 'drugs' table usually has 'name' column.
    """
    normalized = normalize_text(query_name)
    if not normalized:
        return None
    
    # Try exact match on name
    cursor = conn.execute("SELECT ddinter_id FROM drugs WHERE lower(drug_name) = ?", (normalized,))
    row = cursor.fetchone()
    if row:
        return row['ddinter_id']
    
    return None

def fetch_interactions(conn, ddinter_id: str) -> List[Dict]:
    """Fetch interactions for a specific DDInter ID."""
    try:
        # Check table columns first (optional resilience)
        
        # SQL to join and get name
        # Adapting to standard DDInter schema where drug_a/drug_b are IDs
        sql_joined = """
            SELECT 
                d.drug_name AS ingredient2_name,
                di.severity,
                di.interaction_description,
                di.management_text,
                di.mechanism_flags AS mechanism_text
            FROM drug_drug_interactions di
            JOIN drugs d ON di.drug_b_id = d.ddinter_id
            WHERE di.drug_a_id = ?
        """
        
        cursor = conn.execute(sql_joined, (ddinter_id,))
        rows = cursor.fetchall()
        
        interactions = []
        for r in rows:
            interactions.append({
                'ingredient2': r['ingredient2_name'],
                'severity': r['severity'],
                'effect': r['interaction_description'],
                'management_text': r['management_text'],
                'mechanism_text': r['mechanism_text'],
                'risk_level': r['severity'], # DDInter severity IS the risk level
                'source': 'DDInter',
                'ddinter_id': ddinter_id
            })
        return interactions
    except Exception as e:
        print(f"Error fetching interactions for {ddinter_id}: {e}")
        return []

def process_pipeline():
    print( "🚀 Starting Enrichment Pipeline...")
    
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)
        
    conn_ddinter = connect_db(DDINTER_DB_PATH)
    if not conn_ddinter:
        return

    local_meds = get_local_meds(LOCAL_MEDS_CSV)
    print(f"loaded {len(local_meds)} local medicines.")
    
    # Cache to avoid re-querying for the same ingredient
    ingredient_cache = {} 
    
    all_rules = []
    processed_pairs = set()

    count_trade_matches = 0
    count_active_matches = 0

    for i_med, med in enumerate(local_meds):
        trade_name = med['trade_name']
        active_str = med['active']
        
        # 1. Strategy: Search by Trade Name
        ddinter_id = find_ddinter_id(conn_ddinter, trade_name)
        
        matched_id = None
        matched_ing_name = ""

        if ddinter_id:
            count_trade_matches += 1
            if trade_name not in ingredient_cache:
                ingredient_cache[trade_name] = True
                matched_id = ddinter_id
                matched_ing_name = trade_name
        else:
            # 2. Strategy: Fallback to Active Ingredient(s)
            ingredients = [i.strip() for i in INGREDIENT_SPLIT_REGEX.split(active_str) if i.strip()]
            
            for ing in ingredients:
                if ing in ingredient_cache:
                    continue # Already processed
                
                ing_id = find_ddinter_id(conn_ddinter, ing)
                if ing_id:
                    count_active_matches += 1
                    ingredient_cache[ing] = True
                    
                    # Process this match immediately
                    inters = fetch_interactions(conn_ddinter, ing_id)
                    for rule in inters:
                        key = tuple(sorted((normalize_text(ing), normalize_text(rule['ingredient2']))))
                        if key in processed_pairs:
                            continue
                        processed_pairs.add(key)
                        
                        new_rule = {
                            'ingredient1': ing,
                            'ingredient2': rule['ingredient2'],
                            'severity': rule['severity'],
                            'effect': rule['effect'],
                            'management_text': rule['management_text'],
                            'mechanism_text': rule['mechanism_text'],
                            'risk_level': rule['risk_level'],
                            'ddinter_id': rule['ddinter_id'],
                            'source': 'DDInter'
                        }
                        all_rules.append(new_rule)

        if (i_med + 1) % 100 == 0:
            print(f"Processed {i_med + 1}/{len(local_meds)} meds. Found {len(all_rules)} rules.", flush=True)


        # Handle Trade Name Match Processing outside loop
        if matched_id:
             inters = fetch_interactions(conn_ddinter, matched_id)
             for rule in inters:
                 key = tuple(sorted((normalize_text(matched_ing_name), normalize_text(rule['ingredient2']))))
                 if key in processed_pairs:
                     continue
                 processed_pairs.add(key)
                 
                 new_rule = {
                     'ingredient1': matched_ing_name,
                     'ingredient2': rule['ingredient2'],
                     'severity': rule['severity'],
                     'effect': rule['effect'],
                     'management_text': rule['management_text'],
                     'mechanism_text': rule['mechanism_text'],
                     'risk_level': rule['risk_level'],
                     'ddinter_id': rule['ddinter_id'],
                     'source': 'DDInter'
                 }
                 all_rules.append(new_rule)

    conn_ddinter.close()
    
    print(f"Stats: Trade Name Matches: {count_trade_matches}, Active Matches: {count_active_matches}")
    print(f"✨ Extracted {len(all_rules)} unique interaction rules.")
    
    # Chunking and Saving
    total_chunks = (len(all_rules) // CHUNK_SIZE) + 1
    for i in range(total_chunks):
        chunk_data = all_rules[i*CHUNK_SIZE : (i+1)*CHUNK_SIZE]
        if not chunk_data:
            continue
            
        filename = os.path.join(OUTPUT_DIR, f'enriched_rules_part_{i+1:03d}.json')
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump({'data': chunk_data}, f, ensure_ascii=False, indent=2)
        print(f"Saved chunk {i+1}/{total_chunks}: {filename}")

if __name__ == '__main__':
    process_pipeline()
