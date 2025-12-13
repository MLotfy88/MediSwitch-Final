#!/usr/bin/env python3
"""
Merge and Clean Dosage Data
Deduplicates dosage information and prepares final JSON for the app.
"""

import json
import os
from collections import defaultdict

# Inputs
DAILYMED_DOSAGES_FILE = 'production_data/dosages_clean.json'
# Future: OPENFDA_DOSAGES_FILE = 'openfda-dosages/dosages.json'

OUTPUT_FILE = 'production_data/dosages_merged.json'

def load_json(path):
    try:
        with open(path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except:
        return []

def merge_dosages(dailymed_data):
    """
    Deduplicates dosages.
    Strategy: Group by Drug -> Group (Pediatric/Adult) -> Keep longest/most structured
    """
    merged = defaultdict(dict)
    
    for entry in dailymed_data:
        drug = entry['drug_name']
        group = entry['group']
        
        # Key for uniqueness
        key = (drug, group)
        
        if key not in merged:
            merged[key] = entry
        else:
            # Compare and keep the better one
            current = merged[key]
            
            # Criteria 1: Prefer structured data
            curr_struct = current.get('structured', {})
            new_struct = entry.get('structured', {})
            
            curr_score = 0
            if curr_struct.get('dose_mg_kg'): curr_score += 1
            if curr_struct.get('frequency_hours'): curr_score += 1
            
            new_score = 0
            if new_struct.get('dose_mg_kg'): new_score += 1
            if new_struct.get('frequency_hours'): new_score += 1
            
            if new_score > curr_score:
                merged[key] = entry
            elif new_score == curr_score:
                # Criteria 2: Prefer longer raw text (more context)
                if len(entry.get('raw_text', '')) > len(current.get('raw_text', '')):
                    merged[key] = entry
                    
    return list(merged.values())

def main():
    print("="*80)
    print("Merging Dosage Data")
    print("="*80)
    
    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
    
    dailymed = load_json(DAILYMED_DOSAGES_FILE)
    print(f"📥 Loaded {len(dailymed):,} DailyMed dosage records")
    
    merged = merge_dosages(dailymed)
    
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(merged, f, indent=2, ensure_ascii=False)
        
    print(f"\n✅ Merge Complete")
    print(f"Total unique dosage records: {len(merged):,}")
    print(f"Output: {OUTPUT_FILE}")
    
    # Stats
    pd_count = sum(1 for d in merged if d.get('structured', {}).get('is_pediatric'))
    print(f"Pediatric records with mg/kg: {pd_count:,}")

if __name__ == '__main__':
    main()
