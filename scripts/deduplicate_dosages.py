#!/usr/bin/env python3
"""
Deduplication and Quality Check Script for Dosage Guidelines
Removes duplicates and generates quality metrics
"""
import json
from collections import defaultdict
import sys

import gzip
import os

DOSAGE_JSON = 'assets/data/dosage_guidelines.json.gz'

def main():
    # Load raw data
    if not os.path.exists(DOSAGE_JSON):
        print(f"File not found: {DOSAGE_JSON}")
        return 1

    print(f"Loading {DOSAGE_JSON}...")
    with gzip.open(DOSAGE_JSON, 'rt', encoding='utf-8') as f:
        data = json.load(f)

    original_count = len(data)
    print(f"Original records: {original_count:,}")

    # Deduplication Strategy: Keep LAST (Newest) record for each (med_id, source)
    # This ensures refined/enriched records replace legacy ones.
    
    unique_map = {}
    duplicates = 0
    legacy_removed = 0
    garbage_dropped = 0
    
    import re
    def is_garbage(r):
        # Allow confirmed sources
        src = r.get('source', '')
        if src in ['WHO ATC/DDD 2024', 'DailyMed', 'OpenFDA']:
            return False
            
        # For legacy/unknown sources, require quality
        text = r.get('instructions', '')
        has_nums = bool(re.search(r'\d+', text))
        has_freq = bool(r.get('frequency'))
        
        # If no numbers in text, and no freq -> It's garbage dosage info
        if not has_nums and not has_freq:
            return True
        return False

    for rec in data:
        if is_garbage(rec):
            garbage_dropped += 1
            continue

        med_id = rec.get('med_id')
        source = rec.get('source')
        
        # Primary Key: (med_id, source)
        if med_id:
            key = (str(med_id), source)
            
            if key in unique_map:
                duplicates += 1
                old_rec = unique_map[key]
                if not old_rec.get('route') and rec.get('route'):
                    legacy_removed += 1
            
            unique_map[key] = rec
            
        else:
            # Fallback per ingredient for legacy/OpenFDA
            ing = rec.get('active_ingredient')
            if ing:
                # If we already have a record for this ingredient from a GOOD source, skip this one?
                # This is complex. Stick to content hash for now but filter garbage first.
                key = (ing, rec.get('instructions'), source)
                if key not in unique_map:
                     unique_map[key] = rec
                else:
                     duplicates += 1

    unique = list(unique_map.values())

    print(f"Duplicates removed: {duplicates:,}")
    print(f"Garbage records dropped: {garbage_dropped:,}")
    print(f"Legacy records upgraded: {legacy_removed:,}")
    print(f"Unique records: {len(unique):,}")

    # Quality metrics
    truncated = sum(1 for r in unique if (r.get('instructions') or '').endswith('...'))
    who_count = sum(1 for r in unique if r.get('source') == 'WHO ATC/DDD 2024')
    dailymed_count = sum(1 for r in unique if r.get('source') == 'DailyMed')
    local_count = sum(1 for r in unique if r.get('source') == 'Local_Scraper' or not r.get('source'))

    print(f"\n📈 Quality Metrics:")
    print(f"  WHO entries: {who_count:,}")
    print(f"  DailyMed entries: {dailymed_count:,}")
    print(f"  Local entries: {local_count:,}")
    print(f"  Still truncated: {truncated:,}")

    # Save deduplicated
    # Save deduplicated
    with gzip.open(DOSAGE_JSON, 'wt', encoding='utf-8') as f:
        json.dump(unique, f, ensure_ascii=False, separators=(',', ':'))

    # Write metrics for GitHub Actions
    with open('quality_report.txt', 'w') as f:
        f.write(f"final_count={len(unique)}\n")
        f.write(f"who_count={who_count}\n")
        f.write(f"dailymed_count={dailymed_count}\n")
        f.write(f"truncated_remaining={truncated}\n")

    print("✅ Deduplication complete")
    return 0

if __name__ == '__main__':
    sys.exit(main())
