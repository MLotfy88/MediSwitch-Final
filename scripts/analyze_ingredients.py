#!/usr/bin/env python3
"""
Ingredient Matching Analysis Script
Analyzes compatibility between meds.csv and drug_interactions_structured_data.json
"""

import json
import csv
from collections import defaultdict
import re

def normalize_ingredient(ing):
    """Normalize ingredient name for comparison"""
    return ing.strip().lower()

def main():
    # Load interactions JSON
    print("Loading interactions JSON...")
    with open('/home/adminlotfy/project/assets/drug_interactions_structured_data.json', 'r') as f:
        interactions = json.load(f)

    # Extract interaction ingredients
    interaction_ingredients = set()
    for entry in interactions:
        ingredient = normalize_ingredient(entry.get('active_ingredient', ''))
        if ingredient:
            interaction_ingredients.add(ingredient)

    # Load meds.csv
    print("Loading meds.csv...")
    drugs_ingredients = set()
    drug_ingredient_map = defaultdict(list)
    
    with open('/home/adminlotfy/project/assets/meds.csv', 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            trade_name = row.get('trade_name', '').strip()
            active = row.get('active', '').strip()
            
            if active:
                # Split ingredients
                parts = re.split(r'[+,]', active)
                for part in parts:
                    ingredient = normalize_ingredient(part)
                    if ingredient:
                        drugs_ingredients.add(ingredient)
                        drug_ingredient_map[trade_name].append(ingredient)

    # Analysis
    print("\n" + "="*80)
    print("INGREDIENT MATCHING ANALYSIS REPORT")
    print("="*80)
    
    print(f"\nDatabase Statistics:")
    print(f"  - Interactions JSON: {len(interaction_ingredients)} unique ingredients")
    print(f"  - Meds.csv: {len(drugs_ingredients)} unique ingredients")
    print(f"  - Total drugs in CSV: {len(drug_ingredient_map)}")
    
    # Find matches
    matches = interaction_ingredients.intersection(drugs_ingredients)
    only_in_json = interaction_ingredients - drugs_ingredients
    only_in_csv = drugs_ingredients - interaction_ingredients
    
    match_rate = (len(matches) / len(drugs_ingredients) * 100) if drugs_ingredients else 0
    
    print(f"\nMatching Results:")
    print(f"  - Matching: {len(matches)} ({match_rate:.1f}%)")
    print(f"  - Only in JSON: {len(only_in_json)}")
    print(f"  - Only in CSV: {len(only_in_csv)}")
    
    # Sample matches
    print(f"\n{'='*80}")
    print("SAMPLE MATCHES (first 10):")
    print("="*80)
    for i, ing in enumerate(sorted(matches)[:10], 1):
        print(f"{i}. {ing}")
    
    # Potential issues
    print(f"\n{'='*80}")
    print("POTENTIAL NAME VARIATIONS (first 20):")
    print("="*80)
    for i, ing in enumerate(sorted(only_in_csv)[:20], 1):
        # Find similar names in JSON
        similar = [j for j in only_in_json if ing[:5] in j or j[:5] in ing]
        if similar:
            print(f"{i}. CSV: '{ing}' might match JSON: {similar[:2]}")
        else:
            print(f"{i}. CSV: '{ing}' (no match)")
    
    # Save detailed report
    report_path = '/home/adminlotfy/project/ingredient_matching_report.txt'
    with open(report_path, 'w', encoding='utf-8') as f:
        f.write("INGREDIENT MATCHING REPORT\\n")
        f.write("="*80 + "\\n\\n")
        f.write(f"Match Rate: {match_rate:.1f}%\\n")
        f.write(f"Matched: {len(matches)}\\n")
        f.write(f"Only in JSON: {len(only_in_json)}\\n")
        f.write(f"Only in CSV: {len(only_in_csv)}\\n\\n")
        
        f.write("MATCHED INGREDIENTS:\\n")
        for ing in sorted(matches):
            f.write(f"  - {ing}\\n")
        
        f.write("\\nONLY IN CSV:\\n")
        for ing in sorted(only_in_csv):
            f.write(f"  - {ing}\\n")
        
        f.write("\\nONLY IN JSON:\\n")
        for ing in sorted(only_in_json):
            f.write(f"  - {ing}\\n")
    
    print(f"\\n✅ Detailed report saved to: {report_path}")

if __name__ == "__main__":
    main()
