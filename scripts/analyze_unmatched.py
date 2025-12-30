import sqlite3
import csv
import re
from difflib import SequenceMatcher
from collections import Counter

DDINTER_DB = 'ddinter_data/ddinter_complete.db'
LOCAL_MEDS_CSV = 'assets/meds.csv'

INGREDIENT_SEPARATORS = re.compile(r'[+;/,]|\s+and\s+|\s+with\s+', re.IGNORECASE)

def normalize_ingredient(text: str) -> str:
    if not text:
        return ""
    text = text.lower().strip()
    text = re.sub(r'\d+\s*(mg|mcg|g|ml|iu|i\.u\.|%)', '', text, flags=re.IGNORECASE)
    text = re.sub(r'\([^)]*\)', '', text)
    suffixes = [
        ' hydrochloride', ' hcl', ' sulfate', ' sodium', ' calcium',
        ' magnesium', ' potassium', ' acetate', ' chloride', ' maleate',
        ' citrate', ' phosphate', ' succinate', ' tartrate', ' mesylate',
        ' besylate', ' fumarate', ' gluconate', ' lactate'
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
    return [i.strip() for i in ingredients if i.strip() and len(i.strip()) > 1]

# Load DDInter drugs
conn = sqlite3.connect(DDINTER_DB)
cursor = conn.execute("SELECT drug_name FROM drugs")
ddinter_drugs = {normalize_ingredient(row[0]): row[0] for row in cursor.fetchall()}
ddinter_originals = set(row.lower().strip() for row in ddinter_drugs.values())
conn.close()

print("🔍 Deep Analysis: Why 46% Didn't Match\n")
print("=" * 80)

# Categories
unmatched_meds = []
category_counts = Counter()

with open(LOCAL_MEDS_CSV, 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    
    for row in reader:
        trade = row.get('trade_name', '').strip()
        active = row.get('active', '').strip()
        
        if not active:
            category_counts['empty_active'] += 1
            continue
        
        ingredients = split_ingredients(active)
        matched = False
        
        for ing in ingredients:
            normalized = normalize_ingredient(ing)
            if normalized in ddinter_drugs or ing.lower().strip() in ddinter_originals:
                matched = True
                break
        
        if not matched:
            unmatched_meds.append({
                'trade': trade,
                'active': active,
                'ingredients': ingredients
            })

print(f"Total Unmatched: {len(unmatched_meds):,}\n")

# Analyze patterns
print("=" * 80)
print("📊 Pattern Analysis of Unmatched Medicines:\n")

# Categories
cosmetics_keywords = ['cream', 'lotion', 'shampoo', 'gel', 'spray', 'oil', 'cleanser', 
                      'freshener', 'wash', 'soap', 'douche', 'suncare', 'sunscreen']
supplement_keywords = ['vitamin', 'formula', 'supplement', 'multivitamin', 'omega', 
                       'probiotic', 'protein', 'iron', 'zinc', 'calcium']

cosmetics = 0
supplements = 0
potential_synonyms = []

for med in unmatched_meds:
    trade_lower = med['trade'].lower()
    active_lower = med['active'].lower()
    
    # Check if cosmetic
    if any(kw in trade_lower for kw in cosmetics_keywords):
        cosmetics += 1
    # Check if supplement
    elif any(kw in active_lower for kw in supplement_keywords):
        supplements += 1
    else:
        # Potential real drugs - might be synonyms
        if len(med['ingredients']) <= 2:  # Simple formulas
            potential_synonyms.append(med)

print(f"Cosmetics/Topical Products: {cosmetics:,} ({cosmetics/len(unmatched_meds)*100:.1f}%)")
print(f"Supplements/Vitamins: {supplements:,} ({supplements/len(unmatched_meds)*100:.1f}%)")
print(f"Potential Synonym Issues: {len(potential_synonyms):,} ({len(potential_synonyms)/len(unmatched_meds)*100:.1f}%)\n")

# Show samples
print("=" * 80)
print("📋 Sample Unmatched - Potential Synonyms (first 50):\n")

for i, med in enumerate(potential_synonyms[:50], 1):
    print(f"{i:2d}. {med['active']:<40} | Trade: {med['trade'][:40]}")
    
    # Try to find closest DDInter match
    best_match = None
    best_ratio = 0
    
    for ing in med['ingredients']:
        normalized_ing = normalize_ingredient(ing)
        for dd_norm, dd_orig in ddinter_drugs.items():
            ratio = SequenceMatcher(None, normalized_ing, dd_norm).ratio()
            if ratio > best_ratio:
                best_ratio = ratio
                best_match = dd_orig
    
    if best_match and best_ratio > 0.6:
        print(f"    🔶 Closest DDInter: {best_match} (similarity: {best_ratio:.2%})")

print("\n" + "=" * 80)
print("📋 Sample Unmatched - Supplements (first 20):\n")

supplement_samples = [m for m in unmatched_meds 
                     if any(kw in m['active'].lower() for kw in supplement_keywords)][:20]
for i, med in enumerate(supplement_samples, 1):
    print(f"{i:2d}. {med['active'][:60]}")

print("\n" + "=" * 80)
print("📋 Sample Unmatched - Cosmetics (first 20):\n")

cosmetic_samples = [m for m in unmatched_meds 
                   if any(kw in m['trade'].lower() for kw in cosmetics_keywords)][:20]
for i, med in enumerate(cosmetic_samples, 1):
    print(f"{i:2d}. {med['trade'][:60]} | {med['active'][:40]}")

print("\n" + "=" * 80)
print("💡 RECOMMENDATIONS:\n")
print(f"1. Cosmetics/Topicals ({cosmetics:,}): These likely don't need DDInter interactions")
print(f"2. Supplements ({supplements:,}): Limited interaction data in DDInter")
print(f"3. Synonyms ({len(potential_synonyms):,}): Need fuzzy matching or synonym mapping")
print(f"\n🎯 If we exclude cosmetics+supplements: Match rate would be ~{(13742/(25506-cosmetics-supplements))*100:.1f}%")
