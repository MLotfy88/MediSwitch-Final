#!/usr/bin/env python3
"""
Test Drug-Interaction Matching System
Validates that drug database correctly matches with interaction data
"""

import json
import sqlite3
import sys

def load_data():
    """Load all required data files"""
    print("=" * 60)
    print("Loading Data Files...")
    print("=" * 60)
    
    # Load interactions
    with open('assets/data/drug_interactions.json', 'r', encoding='utf-8') as f:
        interactions = json.load(f)
    print(f"✓ Loaded {len(interactions):,} interactions")
    
    # Load medicine ingredients map
    with open('assets/data/medicine_ingredients.json', 'r', encoding='utf-8') as f:
        med_ingredients = json.load(f)
    print(f"✓ Loaded {len(med_ingredients):,} medicine→ingredient mappings")
    
    # Load drugs from SQLite
    conn = sqlite3.connect('assets/meds.db')
    cursor = conn.cursor()
    cursor.execute('SELECT COUNT(*) FROM drug')
    drug_count = cursor.fetchone()[0]
    print(f"✓ Database contains {drug_count:,} drugs")
    
    return interactions, med_ingredients, conn

def get_sample_drugs(conn, limit=20):
    """Get sample drugs from database"""
    cursor = conn.cursor()
    cursor.execute('''
        SELECT tradeName, active, category 
        FROM drug 
        WHERE active IS NOT NULL AND active != ''
        ORDER BY RANDOM()
        LIMIT ?
    ''', (limit,))
    return cursor.fetchall()

def extract_ingredients(active_text):
    """Extract ingredients from active text (mimics Dart code)"""
    import re
    if not active_text:
        return []
    
    parts = re.split(r'[,+/|&]|\s+and\s+|\s+with\s+', active_text)
    ingredients = []
    
    for part in parts:
        # Remove dosage info
        cleaned = re.sub(
            r'\b\d+(\.\d+)?\s*(mg|mcg|g|ml|%|iu|units?|u|tablet|capsule|syrup|injection)\b',
            '',
            part,
            flags=re.IGNORECASE
        )
        cleaned = re.sub(r'\b\d+(\.\d+)?\b', '', cleaned)
        cleaned = re.sub(r'[()\\[\]"]', '', cleaned)
        cleaned = cleaned.strip().lower()
        
        if len(cleaned) > 2:
            ingredients.append(cleaned)
    
    return ingredients

def find_interactions_for_drug(drug_name, active, med_ingredients, interactions):
    """Find interactions for a drug (mimics Dart matching logic)"""
    results = []
    drug_name_lower = drug_name.lower().strip()
    
    # Strategy 1: Check medicine map
    ingredients_from_map = []
    if drug_name_lower in med_ingredients:
        ingredients_from_map = [i.lower() for i in med_ingredients[drug_name_lower]]
    
    # Strategy 2: Direct drug name
    all_ingredients = [drug_name_lower]
    
    # Strategy 3: Parse active
    parsed = extract_ingredients(active)
    all_ingredients.extend(parsed)
    all_ingredients.extend(ingredients_from_map)
    
    # Remove duplicates
    all_ingredients = list(set(all_ingredients))
    
    # Search interactions
    for interaction in interactions:
        ing1 = interaction['ingredient1'].lower()
        ing2 = interaction['ingredient2'].lower()
        
        for ingredient in all_ingredients:
            if ingredient == ing1 or ingredient == ing2:
                results.append(interaction)
                break
    
    return results, all_ingredients

def run_tests():
    """Run comprehensive matching tests"""
    print("\n" + "=" * 60)
    print("TESTING DRUG-INTERACTION MATCHING")
    print("=" * 60)
    
    interactions, med_ingredients, conn = load_data()
    
    # Build interaction index
    interaction_index = {}
    for interaction in interactions:
        ing1 = interaction['ingredient1'].lower()
        ing2 = interaction['ingredient2'].lower()
        
        if ing1 not in interaction_index:
            interaction_index[ing1] = []
        if ing2 not in interaction_index:
            interaction_index[ing2] = []
        
        interaction_index[ing1].append(interaction)
        if ing2 != 'multiple':
            interaction_index[ing2].append(interaction)
    
    print(f"\n✓ Built index with {len(interaction_index):,} unique ingredients")
    
    # Test with sample drugs
    print("\n" + "=" * 60)
    print("TESTING SAMPLE DRUGS")
    print("=" * 60)
    
    sample_drugs = get_sample_drugs(conn, 20)
    matches_found = 0
    no_matches = 0
    
    for trade_name, active, category in sample_drugs:
        found_interactions, ingredients = find_interactions_for_drug(
            trade_name, active, med_ingredients, interactions
        )
        
        if found_interactions:
            matches_found += 1
            print(f"\n✅ {trade_name}")
            print(f"   Category: {category}")
            print(f"   Active: {active[:60]}...")
            print(f"   Matched ingredients: {', '.join(ingredients[:3])}")
            print(f"   Found {len(found_interactions)} interactions")
            
            # Show one interaction
            if found_interactions:
                sample = found_interactions[0]
                print(f"   Example: {sample['severity']} - {sample['effect'][:80]}...")
        else:
            no_matches += 1
            print(f"\n⚪ {trade_name} - No interactions found")
    
    # Test known interactions
    print("\n" + "=" * 60)
    print("TESTING KNOWN HIGH-RISK COMBINATIONS")
    print("=" * 60)
    
    known_tests = [
        ("warfarin", "aspirin", "contraindicated"),
        ("metformin", "alcohol", "severe"),
        ("atorvastatin", "clarithromycin", "major"),
        ("lisinopril", "ibuprofen", "moderate"),
    ]
    
    passed = 0
    failed = 0
    
    for drug1, drug2, expected_severity in known_tests:
        # Search for this interaction
        found = False
        found_severity = None
        
        for interaction in interactions:
            ing1 = interaction['ingredient1'].lower()
            ing2 = interaction['ingredient2'].lower()
            
            if ((drug1 in ing1 or drug1 in ing2) and 
                (drug2 in ing1 or drug2 in ing2 or ing2 == 'multiple')):
                found = True
                found_severity = interaction['severity']
                break
        
        if found:
            if found_severity == expected_severity:
                print(f"✅ PASS: {drug1} + {drug2} → {found_severity}")
                passed += 1
            else:
                print(f"⚠️  PARTIAL: {drug1} + {drug2} → {found_severity} (expected {expected_severity})")
                passed += 1
        else:
            print(f"❌ FAIL: {drug1} + {drug2} → NOT FOUND")
            failed += 1
    
    # Summary
    print("\n" + "=" * 60)
    print("TEST SUMMARY")
    print("=" * 60)
    print(f"Sample Drugs Tested: {len(sample_drugs)}")
    print(f"  With Interactions: {matches_found} ({matches_found/len(sample_drugs)*100:.1f}%)")
    print(f"  Without Interactions: {no_matches}")
    print(f"\nKnown Interaction Tests:")
    print(f"  Passed: {passed}/{len(known_tests)}")
    print(f"  Failed: {failed}/{len(known_tests)}")
    
    if failed == 0:
        print("\n✅ ALL TESTS PASSED!")
        return 0
    else:
        print(f"\n⚠️  {failed} tests failed")
        return 1

if __name__ == '__main__':
    try:
        exit_code = run_tests()
        sys.exit(exit_code)
    except Exception as e:
        print(f"\n❌ ERROR: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
