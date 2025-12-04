#!/usr/bin/env python3
"""
Correct Ingredient Matching Analysis - Using SQLite Database
"""

import json
import sqlite3
import re
from collections import defaultdict

def normalize_ingredient(ing):
    """Normalize ingredient name"""
    return ing.strip().lower()

def extract_ingredients_from_compound(active_text):
    """Extract individual ingredients from compound formula"""
    # Split by + or ,
    parts = re.split(r'[+,]', active_text)
    ingredients = []
    for part in parts:
        # Remove dosage info (numbers, mg, mcg, etc.)
        cleaned = re.sub(r'\d+(\.\d+)?\s*(mg|mcg|g|ml|%|iu|units?)?', '', part, flags=re.IGNORECASE)
        cleaned = normalize_ingredient(cleaned)
        if cleaned and len(cleaned) > 2:  # Ignore very short strings
            ingredients.append(cleaned)
    return ingredients

# Load interactions JSON
print("Loading interactions JSON...")
with open('/home/adminlotfy/project/assets/drug_interactions_structured_data.json', 'r') as f:
    interactions_data = json.load(f)

interaction_ingredients = set()
for entry in interactions_data:
    ing = normalize_ingredient(entry.get('active_ingredient', ''))
    if ing:
        interaction_ingredients.add(ing)

# Load from SQLite database
print("Loading medications from SQLite database...")
conn = sqlite3.connect('/home/adminlotfy/project/assets/medications.db')
cursor = conn.cursor()

cursor.execute("SELECT COUNT(*) FROM medications")
total_drugs = cursor.fetchone()[0]

cursor.execute("SELECT trade_name, active FROM medications WHERE active IS NOT NULL AND active != ''")
drugs = cursor.fetchall()

db_ingredients = set()
drug_ingredient_map = defaultdict(list)

for trade_name, active in drugs:
    if active:
        ingredients = extract_ingredients_from_compound(active)
        for ing in ingredients:
            db_ingredients.add(ing)
            drug_ingredient_map[trade_name].append(ing)

conn.close()

# Analysis
print("\n" + "="*80)
print("CORRECTED INGREDIENT MATCHING ANALYSIS")
print("="*80)
print(f"\nDatabase Statistics:")
print(f"  - Total drugs in database: {total_drugs:,}")
print(f"  - Drugs with active ingredients: {len(drug_ingredient_map):,}")
print(f"  - Unique ingredients in database: {len(db_ingredients):,}")
print(f"  - Unique ingredients in interactions JSON: {len(interaction_ingredients):,}")

# Matching
matches = interaction_ingredients.intersection(db_ingredients)
only_in_json = interaction_ingredients - db_ingredients
only_in_db = db_ingredients - interaction_ingredients

match_rate = (len(matches) / len(db_ingredients) * 100) if db_ingredients else 0

print(f"\nMatching Results:")
print(f"  - Exact matches: {len(matches)} ({match_rate:.1f}% of DB ingredients)")
print(f"  - Only in JSON: {len(only_in_json):,}")
print(f"  - Only in database: {len(only_in_db):,}")

# Samples
print(f"\n{'='*80}")
print("EXACT MATCHES (first 20):")
for i, ing in enumerate(sorted(matches)[:20], 1):
    print(f"{i}. {ing}")

print(f"\n{'='*80}")
print("DB INGREDIENTS WITHOUT MATCH (first 20):")
for i, ing in enumerate(sorted(only_in_db)[:20], 1):
    # Try to find partial matches
    partial = [j for j in interaction_ingredients if ing in j or j in ing]
    if partial:
        print(f"{i}. '{ing}' → Possible: {partial[:2]}")
    else:
        print(f"{i}. '{ing}'")

# Save report
with open('/home/adminlotfy/project/ingredient_matching_report.txt', 'w', encoding='utf-8') as f:
    f.write(f"INGREDIENT MATCHING REPORT\n")
    f.write(f"{'='*80}\n\n")
    f.write(f"Total drugs: {total_drugs:,}\n")
    f.write(f"Unique DB ingredients: {len(db_ingredients):,}\n")
    f.write(f"Unique JSON ingredients: {len(interaction_ingredients):,}\n")
    f.write(f"Match rate: {match_rate:.1f}%\n")
    f.write(f"Exact matches: {len(matches)}\n\n")
    
    f.write(f"MATCHED INGREDIENTS:\n")
    for ing in sorted(matches):
        f.write(f"  - {ing}\n")

print(f"\n✅ Report saved to: ingredient_matching_report.txt")
