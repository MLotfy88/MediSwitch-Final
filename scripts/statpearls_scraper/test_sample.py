#!/usr/bin/env python3
"""
Deep Analysis: Test NCBI matching on random sample
"""
import sys
import time
sys.path.insert(0, '/home/adminlotfy/project/scripts/statpearls_scraper')

from generate_targets import search_ncbi, clean_name

def analyze_sample(filename):
    with open(filename, 'r') as f:
        ingredients = [line.strip() for line in f if line.strip()]
    
    print(f"🔬 Testing {len(ingredients)} random ingredients from database\n")
    print("="*70)
    
    results = {'success': [], 'failed': []}
    
    for idx, ing in enumerate(ingredients, 1):
        cleaned = clean_name(ing)
        print(f"\n[{idx}/{len(ingredients)}] Testing: {ing}")
        if cleaned != ing:
            print(f"           Cleaned: {cleaned}")
        
        result = search_ncbi(ing)
        
        if result:
            print(f"           ✅ MATCH: {result}")
            results['success'].append((ing, result))
        else:
            print(f"           ❌ NO MATCH")
            results['failed'].append(ing)
        
        # Progress
        if idx < len(ingredients):
            time.sleep(0.5)  # Small delay between tests
    
    print("\n" + "="*70)
    print(f"\n📊 RESULTS:")
    print(f"   ✅ Success: {len(results['success'])}/{len(ingredients)} ({len(results['success'])/len(ingredients)*100:.1f}%)")
    print(f"   ❌ Failed:  {len(results['failed'])}/{len(ingredients)} ({len(results['failed'])/len(ingredients)*100:.1f}%)")
    
    if results['failed']:
        print(f"\n🔍 Failed Ingredients Analysis:")
        for ing in results['failed']:
            print(f"   - {ing}")
            # Check if it's likely NOT a drug
            lower = ing.lower()
            if any(x in lower for x in ['extract', 'oil', 'powder', 'formula', 'complex']):
                print(f"     → Likely NOT a standard drug (supplement/cosmetic)")
            elif len(ing.split()) > 3:
                print(f"     → Too descriptive (likely product description, not ingredient)")
    
    return results

if __name__ == "__main__":
    analyze_sample('/tmp/sample_ingredients.txt')
