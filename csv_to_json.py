#!/usr/bin/env python3
"""
Convert enriched CSV data to JSON array for Cloudflare Worker API
"""

import pandas as pd
import json
import sys

def csv_to_json(input_csv, output_json):
    """Convert CSV to JSON array for Cloudflare Worker"""
    print(f"Reading {input_csv}...")
    df = pd.read_csv(input_csv, encoding='utf-8-sig')
    
    # Convert to list of dicts
    drugs = df.to_dict('records')
    
    # Clean data (replace NaN with empty strings/zeros)
    for drug in drugs:
        for key, value in drug.items():
            if pd.isna(value):
                if key in ['price', 'old_price', 'visits']:
                    drug[key] = 0
                else:
                    drug[key] = ''
    
    print(f"Converting {len(drugs)} drugs to JSON...")
    with open(output_json, 'w', encoding='utf-8') as f:
        json.dump(drugs, f, ensure_ascii=False, indent=2)
    
    print(f"✓ Successfully saved to {output_json}")
    print(f"  Total drugs: {len(drugs)}")
    print(f"  File size: {len(json.dumps(drugs)) / 1024:.2f} KB")

if __name__ == '__main__':
    input_file = sys.argv[1] if len(sys.argv) > 1 else 'meds_enriched.csv'
    output_file = sys.argv[2] if len(sys.argv) > 2 else 'drugs.json'
    
    csv_to_json(input_file, output_file)
