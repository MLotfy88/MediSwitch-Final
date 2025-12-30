import sqlite3
import csv
import json
import os
import re
from typing import List, Dict, Set

# Configuration
DDINTER_DB_PATH = 'ddinter_data/ddinter_complete.db'
LOCAL_MEDS_CSV = 'assets/meds.csv'
OUTPUT_DIR = 'assets/data/interactions/enriched'
CHUNK_SIZE = 1000

# Enhanced regex for splitting ingredients
INGREDIENT_SEPARATORS = re.compile(r'[+;/,]|\s+and\s+|\s+with\s+', re.IGNORECASE)

def normalize_ingredient(text: str) -> str:
    """
    Advanced normalization:
    - Convert to lowercase
    - Remove special characters
    - Remove common pharmaceutical suffixes
    """
    if not text:
        return ""
    
    text = text.lower().strip()
    
    # Remove dosage info (numbers + units)
    text = re.sub(r'\d+\s*(mg|mcg|g|ml|iu|i\.u\.|%)', '', text, flags=re.IGNORECASE)
    
    # Remove parenthetical info
    text = re.sub(r'\([^)]*\)', '', text)
    
    # Remove common pharmaceutical suffixes
    suffixes = [
        ' hydrochloride', ' hcl', ' sulfate', ' sodium', ' calcium',
        ' magnesium', ' potassium', ' acetate', ' chloride', ' maleate',
        ' citrate', ' phosphate', ' succinate', ' tartrate', ' mesylate',
        ' besylate', ' fumarate', ' gluconate', ' lactate'
    ]
    for suffix in suffixes:
        text = text.replace(suffix, '')
    
    # Remove extra whitespace and special chars
    text = re.sub(r'[^a-z0-9\s]', ' ', text)
    text = ' '.join(text.split())
    
    return text.strip()

def connect_db(db_path):
    """Connects to the SQLite database."""
    try:
        conn = sqlite3.connect(db_path)
        conn.row_factory = sqlite3.Row
        return conn
    except sqlite3.Error as e:
        print(f"Error connecting to database {db_path}: {e}")
        return None

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

def build_ddinter_index(conn):
    """
    Build a normalized index of DDInter drugs for fast lookup.
    Returns: {normalized_name: ddinter_id}
    """
    cursor = conn.execute("SELECT ddinter_id, drug_name FROM drugs")
    index = {}
    
    for row in cursor.fetchall():
        ddinter_id = row['ddinter_id']
        drug_name = row['drug_name']
        
        # Index both original and normalized
        normalized = normalize_ingredient(drug_name)
        if normalized:
            index[normalized] = ddinter_id
            # Also index the original (case-insensitive)
            index[drug_name.lower().strip()] = ddinter_id
    
    return index

def find_ddinter_id(ddinter_index: Dict, ingredient: str) -> str:
    """
    Find DDInter ID for an ingredient using the index.
    """
    normalized = normalize_ingredient(ingredient)
    
    # Try exact normalized match first
    if normalized in ddinter_index:
        return ddinter_index[normalized]
    
    # Try original lowercase
    lower_ing = ingredient.lower().strip()
    if lower_ing in ddinter_index:
        return ddinter_index[lower_ing]
    
    return None

def split_compound_ingredients(active_str: str) -> List[str]:
    """
    Split compound drug formulas into individual ingredients.
    Examples:
      "Atenolol+chlorthalidone" -> ["Atenolol", "chlorthalidone"]
      "Iron+vitamin b3+b1" -> ["Iron", "vitamin b3", "b1"]
    """
    if not active_str:
        return []
    
    # Split by common separators
    ingredients = INGREDIENT_SEPARATORS.split(active_str)
    
    # Clean and filter
    cleaned = []
    for ing in ingredients:
        ing = ing.strip()
        if ing and len(ing) > 1:  # Filter single chars
            cleaned.append(ing)
    
    return cleaned

def fetch_interactions(conn, ddinter_id: str) -> List[Dict]:
    """Fetch interactions for a specific DDInter ID."""
    try:
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
                'risk_level': r['severity'],
                'source': 'DDInter',
                'ddinter_id': ddinter_id
            })
        return interactions
    except Exception as e:
        print(f"Error fetching interactions for {ddinter_id}: {e}")
        return []

def process_pipeline():
    print("🚀 Enhanced Enrichment Pipeline (Compound Splitting)\n")
    print("=" * 70)
    
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)
        
    conn_ddinter = connect_db(DDINTER_DB_PATH)
    if not conn_ddinter:
        return

    # Build normalized index
    print("📝 Building DDInter normalized index...")
    ddinter_index = build_ddinter_index(conn_ddinter)
    print(f"   Indexed {len(ddinter_index):,} drug name variations\n")

    local_meds = get_local_meds(LOCAL_MEDS_CSV)
    print(f"📦 Loaded {len(local_meds):,} local medicines\n")
    
    all_rules = []
    processed_pairs = set()
    
    stats = {
        'total_meds': 0,
        'meds_with_match': 0,
        'total_ingredients_found': 0,
        'compound_drugs': 0
    }

    print("🔄 Processing medicines...\n")
    
    for i_med, med in enumerate(local_meds):
        stats['total_meds'] += 1
        trade_name = med['trade_name']
        active_str = med['active']
        
        if not active_str:
            continue
        
        # Split compound ingredients
        ingredients = split_compound_ingredients(active_str)
        
        if len(ingredients) > 1:
            stats['compound_drugs'] += 1
        
        med_matched = False
        
        for ingredient in ingredients:
            # Find DDInter ID
            ddinter_id = find_ddinter_id(ddinter_index, ingredient)
            
            if ddinter_id:
                stats['total_ingredients_found'] += 1
                med_matched = True
                
                # Fetch interactions
                interactions = fetch_interactions(conn_ddinter, ddinter_id)
                
                for rule in interactions:
                    # De-duplication key
                    key = tuple(sorted((
                        normalize_ingredient(ingredient),
                        normalize_ingredient(rule['ingredient2'])
                    )))
                    
                    if key in processed_pairs:
                        continue
                    
                    processed_pairs.add(key)
                    
                    new_rule = {
                        'ingredient1': ingredient,
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
        
        if med_matched:
            stats['meds_with_match'] += 1
        
        # Progress update
        if (i_med + 1) % 1000 == 0:
            print(f"   Processed {i_med + 1:,}/{len(local_meds):,} meds | "
                  f"Found {len(all_rules):,} rules", flush=True)

    conn_ddinter.close()
    
    # Save results
    print(f"\n💾 Saving results...")
    total_chunks = (len(all_rules) // CHUNK_SIZE) + 1
    
    for i in range(total_chunks):
        chunk_data = all_rules[i*CHUNK_SIZE : (i+1)*CHUNK_SIZE]
        if not chunk_data:
            continue
            
        filename = os.path.join(OUTPUT_DIR, f'enriched_rules_part_{i+1:03d}.json')
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump({'data': chunk_data}, f, ensure_ascii=False, indent=2)
    
    print(f"   Saved {total_chunks} chunks\n")
    
    # Statistics
    print("=" * 70)
    print("📊 RESULTS:\n")
    print(f"Total Medicines: {stats['total_meds']:,}")
    print(f"Medicines with Matched Ingredients: {stats['meds_with_match']:,} "
          f"({stats['meds_with_match']/stats['total_meds']*100:.1f}%)")
    print(f"Compound Drugs Detected: {stats['compound_drugs']:,}")
    print(f"Total Individual Ingredients Matched: {stats['total_ingredients_found']:,}")
    print(f"Total Interaction Rules Generated: {len(all_rules):,}")
    print(f"Unique Interaction Pairs: {len(processed_pairs):,}")
    print("\n✅ Enhanced Pipeline Complete!")

if __name__ == '__main__':
    process_pipeline()
