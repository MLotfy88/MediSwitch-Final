import sqlite3
import csv
from difflib import SequenceMatcher

# Paths
DDINTER_DB = 'ddinter_data/ddinter_complete.db'
LOCAL_MEDS_CSV = 'assets/meds.csv'

def normalize(text):
    """Aggressive normalization"""
    if not text:
        return ""
    text = text.lower().strip()
    # Remove common suffixes
    for suffix in [' hcl', ' hydrochloride', ' sulfate', ' sodium', ' calcium', 
                   ' magnesium', ' potassium', ' acetate', ' chloride']:
        text = text.replace(suffix, '')
    return text

print("🔬 Deep Dive: Ingredient Matching Analysis\n")
print("=" * 80)

# Load DDInter ingredients
conn = sqlite3.connect(DDINTER_DB)
cursor = conn.cursor()
cursor.execute("SELECT drug_name FROM drugs")
ddinter_drugs = {normalize(row[0]): row[0] for row in cursor.fetchall()}
conn.close()

print(f"DDInter Drugs: {len(ddinter_drugs):,}\n")

# Sample analysis
with open(LOCAL_MEDS_CSV, 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    
    print("=" * 80)
    print("📋 First 20 Local Medicines - Active Ingredient Analysis:\n")
    
    for i, row in enumerate(reader):
        if i >= 20:
            break
        
        trade = row.get('trade_name', '').strip()
        active = row.get('active', '').strip()
        
        print(f"\n{i+1}. Trade Name: {trade}")
        print(f"   Active: {active}")
        
        # Try to match
        active_normalized = normalize(active)
        
        if active_normalized in ddinter_drugs:
            print(f"   ✅ EXACT MATCH: {ddinter_drugs[active_normalized]}")
        else:
            # Try partial match
            best_match = None
            best_ratio = 0
            for dd_norm, dd_orig in ddinter_drugs.items():
                ratio = SequenceMatcher(None, active_normalized, dd_norm).ratio()
                if ratio > best_ratio and ratio > 0.7:
                    best_ratio = ratio
                    best_match = dd_orig
            
            if best_match:
                print(f"   🔶 FUZZY MATCH ({best_ratio:.2%}): {best_match}")
            else:
                print(f"   ❌ NO MATCH")

print("\n" + "=" * 80)
print("🔍 Detailed Comparison:\n")

# Re-read for full analysis
exact_matches = 0
fuzzy_matches = 0
no_matches = 0
total = 0

with open(LOCAL_MEDS_CSV, 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    
    for row in reader:
        total += 1
        active = row.get('active', '').strip()
        if not active:
            continue
            
        active_normalized = normalize(active)
        
        if active_normalized in ddinter_drugs:
            exact_matches += 1
        else:
            found_fuzzy = False
            for dd_norm in ddinter_drugs.keys():
                ratio = SequenceMatcher(None, active_normalized, dd_norm).ratio()
                if ratio > 0.85:
                    fuzzy_matches += 1
                    found_fuzzy = True
                    break
            if not found_fuzzy:
                no_matches += 1

print(f"Total Medicines: {total:,}")
print(f"Exact Matches: {exact_matches:,} ({exact_matches/total*100:.1f}%)")
print(f"Fuzzy Matches (>85%): {fuzzy_matches:,} ({fuzzy_matches/total*100:.1f}%)")
print(f"No Matches: {no_matches:,} ({no_matches/total*100:.1f}%)")
print(f"\nCombined Match Rate: {(exact_matches + fuzzy_matches)/total*100:.1f}%")
