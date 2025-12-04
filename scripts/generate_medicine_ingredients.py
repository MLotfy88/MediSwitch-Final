#!/usr/bin/env python3
"""
Generate medicine_ingredients.json from SQLite
"""

import sqlite3
import json
import re

def normalize_ingredient(ing):
    """Normalize ingredient name"""
    cleaned = re.sub(r'\b\d+(\.\d+)?\s*(mg|mcg|g|ml|%|iu|units?|u)\b', '', ing, flags=re.IGNORECASE)
    cleaned = re.sub(r'\b\d+(\.\d+)?\b', '', cleaned)
    cleaned = re.sub(r'[()\[\]]', '', cleaned)
    return cleaned.strip().lower()

def extract_ingredients(active_text):
    if not active_text:
        return []
    parts = re.split(r'[+,/|&]|\s+and\s+', active_text)
    ingredients = []
    for part in parts:
        cleaned = normalize_ingredient(part)
        if cleaned and len(cleaned) > 1:
            ingredients.append(cleaned)
    return ingredients

print("Connecting to database...")
conn = sqlite3.connect('/home/adminlotfy/project/assets/medications.db')
cursor = conn.cursor()

print("Fetching drugs...")
cursor.execute("SELECT trade_name, active FROM medications WHERE active IS NOT NULL AND active != ''")
drugs = cursor.fetchall()
conn.close()

medicine_ingredients = {}
all_ingredients = set()

print(f"Processing {len(drugs)} drugs...")
for trade_name, active in drugs:
    ingredients = extract_ingredients(active)
    if ingredients:
        medicine_ingredients[trade_name] = ingredients
        for ing in ingredients:
            all_ingredients.add(ing)

# Save medicine_ingredients.json
output_path = '/home/adminlotfy/project/assets/data/medicine_ingredients.json'
print(f"Saving to {output_path}...")
with open(output_path, 'w', encoding='utf-8') as f:
    json.dump(medicine_ingredients, f, ensure_ascii=False, indent=2)

# Save active_ingredients.json (list of unique ingredients)
ingredients_list = [{"name": ing} for ing in sorted(list(all_ingredients))]
ingredients_path = '/home/adminlotfy/project/assets/data/active_ingredients.json'
print(f"Saving to {ingredients_path}...")
with open(ingredients_path, 'w', encoding='utf-8') as f:
    json.dump(ingredients_list, f, ensure_ascii=False, indent=2)

print("Done!")
print(f"Mapped {len(medicine_ingredients)} drugs.")
print(f"Found {len(all_ingredients)} unique ingredients.")
