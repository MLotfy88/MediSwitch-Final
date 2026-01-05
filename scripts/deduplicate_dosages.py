#!/usr/bin/env python3
"""
Deduplication and Quality Check Script for Dosage Guidelines
Removes duplicates and generates quality metrics
"""
import json
from collections import defaultdict
import sys

DOSAGE_JSON = 'assets/data/dosage_guidelines.json'

def main():
    print("📊 Loading data...")
    with open(DOSAGE_JSON, 'r') as f:
        data = json.load(f)

    original_count = len(data)
    print(f"Original records: {original_count:,}")

    # Deduplication by (med_id, source, active_ingredient, instructions)
    # Include active_ingredient to handle OpenFDA records (which have None for med_id)
    seen = set()
    unique = []
    duplicates = 0

    for rec in data:
        key = (
            rec.get('med_id'),
            rec.get('source'),
            rec.get('active_ingredient'),
            rec.get('instructions')
        )
        if key not in seen:
            seen.add(key)
            unique.append(rec)
        else:
            duplicates += 1

    print(f"Duplicates removed: {duplicates:,}")
    print(f"Unique records: {len(unique):,}")

    # Quality metrics
    truncated = sum(1 for r in unique if r.get('instructions', '').endswith('...'))
    who_count = sum(1 for r in unique if r.get('source') == 'WHO ATC/DDD 2024')
    dailymed_count = sum(1 for r in unique if r.get('source') == 'DailyMed')
    local_count = sum(1 for r in unique if r.get('source') == 'Local_Scraper')

    print(f"\n📈 Quality Metrics:")
    print(f"  WHO entries: {who_count:,}")
    print(f"  DailyMed entries: {dailymed_count:,}")
    print(f"  Local entries: {local_count:,}")
    print(f"  Still truncated: {truncated:,}")

    # Save deduplicated
    with open(DOSAGE_JSON, 'w') as f:
        json.dump(unique, f, indent=2, ensure_ascii=False)

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
