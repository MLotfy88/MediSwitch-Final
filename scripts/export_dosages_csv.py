#!/usr/bin/env python3
"""
Export Dosage Guidelines to CSV for Inspection
Generates both full export and sample file
"""
import json
import csv
import random
import sys
import gzip

DOSAGE_JSON = 'assets/data/dosage_guidelines.json.gz'
FULL_CSV = 'exports/dosage_guidelines_full.csv'
SAMPLE_CSV = 'exports/dosage_guidelines_sample.csv'
SAMPLE_SIZE = 500

def main():
    import os
    os.makedirs('exports', exist_ok=True)
    
    print("📖 Loading dosage data...")
    with gzip.open(DOSAGE_JSON, 'rt', encoding='utf-8') as f:
        data = json.load(f)
    
    print(f"Total records: {len(data):,}")
    
    # Define CSV fields
    fieldnames = [
        'id', 'med_id', 'dailymed_setid', 'min_dose', 'max_dose',
        'frequency', 'duration', 'instructions', 'condition', 'source',
        'is_pediatric', 'atc_code', 'route_code', 'route'
    ]
    
    # Write full CSV
    print(f"Writing full CSV to {FULL_CSV}...")
    with open(FULL_CSV, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction='ignore')
        writer.writeheader()
        writer.writerows(data)
    
    print(f"✅ Full CSV exported: {len(data):,} records")
    
    # Create sample
    sample = random.sample(data, min(SAMPLE_SIZE, len(data)))
    
    print(f"Writing sample CSV to {SAMPLE_CSV}...")
    with open(SAMPLE_CSV, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction='ignore')
        writer.writeheader()
        writer.writerows(sample)
    
    print(f"✅ Sample CSV exported: {len(sample):,} records")
    
    # Generate summary
    print(f"\n📊 Export Summary:")
    print(f"  Full CSV: {FULL_CSV}")
    print(f"  Sample CSV: {SAMPLE_CSV}")
    
    # Source distribution in sample
    from collections import Counter
    sources = Counter(r.get('source') for r in sample)
    print(f"\n  Sample Distribution:")
    for source, count in sources.most_common():
        print(f"    {source}: {count}")
    
    return 0

if __name__ == '__main__':
    sys.exit(main())
