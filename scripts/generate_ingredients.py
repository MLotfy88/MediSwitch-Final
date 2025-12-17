#!/usr/bin/env python3
"""
Generate Known Ingredients List
Extracts unique active ingredients from scraped data for use in Interaction Extraction.
"""

import json
import os
import pandas as pd

INPUT_FILE = 'assets/meds.csv'
OUTPUT_FILE = 'production_data/known_ingredients.json'

def generate_ingredients():
    os.makedirs('production_data', exist_ok=True)
    
    if not os.path.exists(INPUT_FILE):
        print(f"❌ Input file {INPUT_FILE} not found.")
        return

    print(f"📖 Reading {INPUT_FILE}...")
    df = pd.read_csv(INPUT_FILE, dtype=str)
    
    ingredients = set()
    
    # Extract from 'active' column
    if 'active' in df.columns:
        for val in df['active'].dropna():
            parts = [p.strip().lower() for p in str(val).split('+')]
            ingredients.update(parts)
            
    # Extract from 'trade_name' (fallback, maybe risky but useful for simple names)
    # Better to stick to 'active' if available.
    
    final_list = sorted(list(ingredients))
    
    data = {
        'ingredients': final_list,
        'count': len(final_list),
        'source': INPUT_FILE
    }
    
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        
    print(f"✅ Generated {OUTPUT_FILE} with {len(final_list)} ingredients.")

if __name__ == "__main__":
    generate_ingredients()
