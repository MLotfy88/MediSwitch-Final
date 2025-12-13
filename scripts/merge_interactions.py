#!/usr/bin/env python3
"""
Merge Interactions from Multiple Sources
Combines DailyMed and OpenFDA interactions with deduplication
"""

import json
import os
from collections import defaultdict

DAILYMED_FILE = 'dailymed-interactions/dailymed_interactions_clean.json'
OPENFDA_FILE = 'openfda-interactions/drug_interactions_clean.json'
OUTPUT_FILE = 'production_data/interactions_merged.json'

def load_interactions(file_path):
    """Load interactions from JSON file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"⚠️  File not found: {file_path}")
        return []
    except Exception as e:
        print(f"❌ Error loading {file_path}: {e}")
        return []

def merge_interactions(dailymed_data, openfda_data):
    """
    Merge interactions with intelligent deduplication
    Priority: DailyMed > OpenFDA (DailyMed is more structured)
    """
    merged = {}
    
    # Add DailyMed first (higher priority)
    for interaction in dailymed_data:
        key = (
            interaction['ingredient1'].lower(),
            interaction['ingredient2'].lower()
        )
        merged[key] = interaction
    
    print(f"📊 Added {len(dailymed_data):,} DailyMed interactions")
    
    # Add OpenFDA (only if not already present)
    added_from_openfda = 0
    for interaction in openfda_data:
        key = (
            interaction['ingredient1'].lower(),
            interaction['ingredient2'].lower()
        )
        
        if key not in merged:
            merged[key] = interaction
            added_from_openfda += 1
    
    print(f"📊 Added {added_from_openfda:,} unique OpenFDA interactions")
    
    return list(merged.values())

def main():
    print("="*80)
    print("Merging Drug Interactions from Multiple Sources")
    print("="*80)
    
    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
    
    # Load both sources
    dailymed = load_interactions(DAILYMED_FILE)
    openfda = load_interactions(OPENFDA_FILE)
    
    print(f"\n📥 Loaded interactions:")
    print(f"  DailyMed: {len(dailymed):,}")
    print(f"  OpenFDA: {len(openfda):,}")
    
    # Merge
    merged = merge_interactions(dailymed, openfda)
    
    # Save
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(merged, f, indent=2, ensure_ascii=False)
    
    # Summary
    print("\n" + "="*80)
    print("✅ MERGE COMPLETE")
    print("="*80)
    print(f"Total unique interactions: {len(merged):,}")
    print(f"Output: {OUTPUT_FILE}")
    print(f"Size: {os.path.getsize(OUTPUT_FILE) / 1024:.1f} KB")
    
    # Distribution
    from collections import Counter
    severities = Counter(i['severity'] for i in merged)
    sources = Counter(i['source'] for i in merged)
    
    print(f"\nSeverity Distribution:")
    for severity, count in severities.most_common():
        print(f"  {severity}: {count:,} ({count/len(merged)*100:.1f}%)")
    
    print(f"\nSource Distribution:")
    for source, count in sources.most_common():
        print(f"  {source}: {count:,} ({count/len(merged)*100:.1f}%)")

if __name__ == '__main__':
    main()
