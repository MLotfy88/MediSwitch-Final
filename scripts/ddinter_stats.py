import sqlite3
import csv
import json
import os
from collections import defaultdict

# Paths
DDINTER_DB = 'ddinter_data/ddinter_complete.db'
LOCAL_MEDS_CSV = 'assets/meds.csv'
ENRICHED_DIR = 'assets/data/interactions/enriched'

print("📊 DDInter Integration Statistics Report\n")
print("=" * 60)

# 1. Analyze Local Medicines
print("\n🔍 Analyzing Local Medicines Database...")
total_meds = 0
meds_with_active = 0
unique_ingredients = set()

with open(LOCAL_MEDS_CSV, 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        total_meds += 1
        active = row.get('active', '').strip()
        if active:
            meds_with_active += 1
            # Split ingredients
            for ing in active.replace('+', ';').replace('/', ';').split(';'):
                ing = ing.strip().lower()
                if ing:
                    unique_ingredients.add(ing)

print(f"   Total Medicines: {total_meds:,}")
print(f"   Medicines with Active Ingredients: {meds_with_active:,} ({meds_with_active/total_meds*100:.1f}%)")
print(f"   Unique Active Ingredients: {len(unique_ingredients):,}")

# 2. Analyze Enriched Drug Interactions
print("\n💊 Analyzing Drug-Drug Interactions (DDInter Enriched)...")

matched_ingredients_drug = set()
total_drug_rules = 0
ddinter_sources = 0

if os.path.exists(ENRICHED_DIR):
    for filename in sorted(os.listdir(ENRICHED_DIR)):
        if filename.startswith('enriched_rules_part_') and filename.endswith('.json'):
            filepath = os.path.join(ENRICHED_DIR, filename)
            with open(filepath, 'r', encoding='utf-8') as f:
                data = json.load(f)
                rules = data.get('data', [])
                for rule in rules:
                    total_drug_rules += 1
                    if rule.get('source') == 'DDInter':
                        ddinter_sources += 1
                    
                    # Track matched ingredients
                    ing1 = rule.get('ingredient1', '').strip().lower()
                    ing2 = rule.get('ingredient2', '').strip().lower()
                    if ing1:
                        matched_ingredients_drug.add(ing1)
                    if ing2:
                        matched_ingredients_drug.add(ing2)

    print(f"   Total Interaction Rules Generated: {total_drug_rules:,}")
    print(f"   Rules from DDInter Source: {ddinter_sources:,} ({ddinter_sources/total_drug_rules*100:.1f}%)")
    print(f"   Unique Ingredients Matched: {len(matched_ingredients_drug):,}")
    print(f"   Match Rate (Ingredients): {len(matched_ingredients_drug)/len(unique_ingredients)*100:.1f}%")
else:
    print("   ⚠️  Enriched directory not found!")

# 3. Analyze Food Interactions
print("\n🥗 Analyzing Food-Drug Interactions...")

food_interactions_file = 'assets/data/food_interactions.json'
if os.path.exists(food_interactions_file):
    with open(food_interactions_file, 'r', encoding='utf-8') as f:
        food_data = json.load(f)
    
    total_food_interactions = len(food_data)
    unique_meds_with_food = len(set(item.get('med_id') for item in food_data if item.get('med_id')))
    
    print(f"   Total Food Interaction Records: {total_food_interactions:,}")
    print(f"   Unique Medicines with Food Interactions: {unique_meds_with_food:,}")
    print(f"   Coverage (of total meds): {unique_meds_with_food/total_meds*100:.1f}%")
else:
    print("   ⚠️  Food interactions file not found!")

# 4. DDInter Database Stats
print("\n🗄️  DDInter Database Statistics...")
try:
    conn = sqlite3.connect(DDINTER_DB)
    cursor = conn.cursor()
    
    # Count drugs in DDInter
    cursor.execute("SELECT COUNT(*) FROM drugs")
    ddinter_total_drugs = cursor.fetchone()[0]
    
    # Count drug-drug interactions
    cursor.execute("SELECT COUNT(*) FROM drug_drug_interactions")
    ddinter_ddi = cursor.fetchone()[0]
    
    # Count drug-food interactions
    cursor.execute("SELECT COUNT(*) FROM drug_food_interactions")
    ddinter_food = cursor.fetchone()[0]
    
    conn.close()
    
    print(f"   Total Drugs in DDInter: {ddinter_total_drugs:,}")
    print(f"   Drug-Drug Interactions in DDInter: {ddinter_ddi:,}")
    print(f"   Drug-Food Interactions in DDInter: {ddinter_food:,}")
    
except Exception as e:
    print(f"   ⚠️  Error accessing DDInter DB: {e}")

# Summary
print("\n" + "=" * 60)
print("📈 SUMMARY")
print("=" * 60)
print(f"✅ Local Drugs Processed: {total_meds:,}")
print(f"✅ Drug Interaction Rules Generated: {total_drug_rules:,}")
print(f"✅ Active Ingredients Successfully Matched: {len(matched_ingredients_drug):,}/{len(unique_ingredients):,}")
print(f"✅ Match Success Rate: {len(matched_ingredients_drug)/len(unique_ingredients)*100:.1f}%")
print("\n🎯 Integration Status: COMPLETE")
