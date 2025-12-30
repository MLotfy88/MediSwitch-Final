import sqlite3
import csv
import json
from difflib import SequenceMatcher
import re

DDINTER_DB = 'ddinter_data/ddinter_complete.db'
LOCAL_MEDS_CSV = 'assets/meds.csv'
OUTPUT_FILE = 'scripts/drug_synonyms.json'

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

def split_ingredients(active_str: str):
    if not active_str:
        return []
    ingredients = INGREDIENT_SEPARATORS.split(active_str)
    return [i.strip() for i in ingredients if i.strip() and len(i.strip()) > 2]

print("🔍 Building Comprehensive Drug Synonym Dictionary\n")
print("=" * 80)

# Load DDInter drugs
conn = sqlite3.connect(DDINTER_DB)
cursor = conn.execute("SELECT drug_name FROM drugs")
ddinter_drugs = {}
for row in cursor.fetchall():
    normalized = normalize_ingredient(row[0])
    if normalized:
        ddinter_drugs[normalized] = row[0]
conn.close()

print(f"✅ Loaded {len(ddinter_drugs):,} DDInter drugs\n")

# Known pharmaceutical synonyms (curated list)
KNOWN_SYNONYMS = {
    # Common paracetamol variants
    'paracetamol': 'acetaminophen',
    'paracetamol(acetaminophen)': 'acetaminophen',
    
    # Antibiotics
    'cephradine': 'cefradine',
    'cefadroxyl': 'cefadroxil',
    'amoxycillin': 'amoxicillin',
    'ampicillin trihydrate': 'ampicillin',
    
    # Cardiovascular
    'amlodipine besylate': 'amlodipine',
    'atenolol': 'atenolol',
    
    # Diabetes
    'metformin hcl': 'metformin',
    'glimepiride': 'glimepiride',
    
    # Pain/Anti-inflammatory
    'ibuprofen': 'ibuprofen',
    'diclofenac sodium': 'diclofenac',
    'diclofenac potassium': 'diclofenac',
    
    # Vitamins
    'cholecalciferol': 'vitamin d3',
    'cyanocobalamin': 'vitamin b12',
    'pyridoxine': 'vitamin b6',
    'thiamine': 'vitamin b1',
    'riboflavin': 'vitamin b2',
    'ascorbic acid': 'vitamin c',
    'tocopherol': 'vitamin e',
    'phytomenadione': 'vitamin k1',
    'menadione': 'vitamin k',
    
    # Specialty drugs
    'levocarnitine': 'l carnitine',
    'acetylcysteine': 'n acetylcysteine',
    'methylcobalamin': 'mecobalamin',
    
    # Antihistamines
    'cetirizine hcl': 'cetirizine',
    'loratadine': 'loratadine',
    
    # GI drugs
    'omeprazole': 'omeprazole',
    'pantoprazole sodium': 'pantoprazole',
    'esomeprazole': 'esomeprazole',
}

# Load all local ingredients
local_ingredients = set()
with open(LOCAL_MEDS_CSV, 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        active = row.get('active', '').strip()
        if active:
            ingredients = split_ingredients(active)
            for ing in ingredients:
                normalized = normalize_ingredient(ing)
                if normalized and len(normalized) > 2:
                    local_ingredients.add((ing, normalized))

print(f"✅ Loaded {len(local_ingredients):,} unique local ingredients\n")

# Build synonym dictionary
print("🔄 Generating synonyms with fuzzy matching...\n")

synonym_dict = {}
fuzzy_matches = 0
exact_matches = 0
no_matches = 0

# First, add known synonyms
for local_norm, ddinter_name in KNOWN_SYNONYMS.items():
    local_norm_clean = normalize_ingredient(local_norm)
    ddinter_norm = normalize_ingredient(ddinter_name)
    
    if ddinter_norm in ddinter_drugs:
        synonym_dict[local_norm_clean] = ddinter_drugs[ddinter_norm]

print(f"   Added {len(KNOWN_SYNONYMS)} known synonyms\n")

# Process each local ingredient
for original_ing, normalized_ing in local_ingredients:
    if not normalized_ing:
        continue
    
    # Skip if already mapped
    if normalized_ing in synonym_dict:
        continue
    
    # Check exact match
    if normalized_ing in ddinter_drugs:
        synonym_dict[normalized_ing] = ddinter_drugs[normalized_ing]
        exact_matches += 1
        continue
    
    # Fuzzy matching
    best_match = None
    best_score = 0
    
    for dd_normalized, dd_original in ddinter_drugs.items():
        # Skip very different lengths
        len_diff = abs(len(normalized_ing) - len(dd_normalized))
        if len_diff > 5:
            continue
        
        score = SequenceMatcher(None, normalized_ing, dd_normalized).ratio()
        
        if score > best_score:
            best_score = score
            best_match = dd_original
    
    # Accept matches with 75%+ similarity
    if best_match and best_score >= 0.75:
        synonym_dict[normalized_ing] = best_match
        fuzzy_matches += 1
        
        # Log interesting matches
        if best_score < 0.90:
            print(f"   🔶 Fuzzy: '{original_ing}' → '{best_match}' ({best_score:.1%})")
    else:
        no_matches += 1

print(f"\n📊 Results:")
print(f"   Exact Matches: {exact_matches:,}")
print(f"   Fuzzy Matches (75%+): {fuzzy_matches:,}")
print(f"   No Match: {no_matches:,}")
print(f"   Total Synonyms in Dictionary: {len(synonym_dict):,}\n")

# Save synonym dictionary
with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
    json.dump(synonym_dict, f, ensure_ascii=False, indent=2)

print(f"✅ Synonym dictionary saved to: {OUTPUT_FILE}\n")
print("=" * 80)
