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
    
    # Write Split CSVs (Chunks of 50k records ~= 50MB)
    CHUNK_SIZE = 50000
    total_parts = (len(data) + CHUNK_SIZE - 1) // CHUNK_SIZE
    
    print(f"Splitting into {total_parts} parts (max {CHUNK_SIZE} records/file)...")
    
    for i in range(total_parts):
        start_idx = i * CHUNK_SIZE
        end_idx = start_idx + CHUNK_SIZE
        chunk = data[start_idx:end_idx]
        
        part_filename = f"exports/dosage_guidelines_part_{i+1}.csv"
        print(f"  Writing {part_filename} ({len(chunk):,} records)...")
        
        with open(part_filename, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction='ignore')
            writer.writeheader()
            writer.writerows(chunk)
            
    # Remove full file if it exists to prevent git errors
    if os.path.exists(FULL_CSV):
        os.remove(FULL_CSV)
        print(f"🗑️ Removed oversize file: {FULL_CSV}")

    print(f"✅ Exported {len(data):,} records across {total_parts} files.")
    
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
