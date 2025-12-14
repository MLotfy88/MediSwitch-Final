#!/usr/bin/env python3
"""
Hybrid Data Merger
Combines:
1. DailyMed Linked Data (High Quality, FDA, Dosage Parsed) - Priority 1
2. Local Scraper Data (Full Coverage, Text based) - Priority 2

Outputs: production_hybrid.jsonl (Target >90% coverage)
"""

import json
import os
import pandas as pd
from typing import Dict, Set

# --- Paths ---
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MEDS_CSV = os.path.join(BASE_DIR, 'assets', 'meds.csv')
DAILYMED_DB = os.path.join(BASE_DIR, 'production_data', 'production_dosages.jsonl')
SCRAPER_DB = os.path.join(BASE_DIR, 'assets', 'meds_scraped_new.jsonl')
OUTPUT_DB = os.path.join(BASE_DIR, 'production_data', 'production_hybrid.jsonl')

def load_ids_from_meds() -> Set[str]:
    print(f"📂 Loading Local IDs from {MEDS_CSV}...")
    if not os.path.exists(MEDS_CSV):
        print("❌ meds.csv not found!")
        return set()
    df = pd.read_csv(MEDS_CSV, dtype=str)
    # Filter valid IDs
    valid_ids = set()
    for x in df['id'].unique():
        s = str(x).strip()
        if s and s.isdigit():
             valid_ids.add(s)
    print(f"✅ Found {len(valid_ids):,} Unique Local IDs.")
    return valid_ids

def load_dailymed_data() -> Dict[str, dict]:
    print(f"📂 Loading DailyMed Data from {DAILYMED_DB}...")
    data = {}
    if not os.path.exists(DAILYMED_DB):
        print("⚠️ DailyMed DB not found (Skipping Tier 1).")
        return data
        
    with open(DAILYMED_DB, 'r', encoding='utf-8') as f:
        for line in f:
            if not line.strip(): continue
            try:
                rec = json.loads(line)
                mid = str(rec.get('med_id', ''))
                if mid:
                    rec['data_source'] = 'DailyMed'
                    # Ensure quality score exists
                    if 'quality_score' not in rec:
                        rec['quality_score'] = 50 # Default baseline
                    data[mid] = rec
            except Exception as e:
                pass
    print(f"✅ Loaded {len(data):,} DailyMed Records.")
    return data

def load_scraped_data() -> Dict[str, dict]:
    print(f"📂 Loading Scraped Data from {SCRAPER_DB}...")
    data = {}
    if not os.path.exists(SCRAPER_DB):
        print("⚠️ Scraped DB not found (Skipping Tier 2).")
        return data
        
    with open(SCRAPER_DB, 'r', encoding='utf-8') as f:
        for line in f:
            if not line.strip(): continue
            try:
                rec = json.loads(line)
                mid = str(rec.get('id', ''))
                if mid:
                    # Transform to Hybrid Schema immediately
                    hybrid_rec = transform_scraper_record(rec)
                    data[mid] = hybrid_rec
            except Exception as e:
                pass
    print(f"✅ Loaded {len(data):,} Scraped Records.")
    return data

def transform_scraper_record(scrap: Dict) -> Dict:
    """Converts a raw scraper record into the Production JSONL Schema."""
    
    # 1. Dosage Form Parsing
    form = scrap.get('dosage_form', 'Unknown')
    units = scrap.get('units', '')
    
    # 2. Clinical Text (Usage + Pharmacology)
    usage = scrap.get('usage', '').strip()
    pharma = scrap.get('pharmacology', '').strip()
    
    # 3. Construct Record
    return {
        'med_id': str(scrap['id']),
        'trade_name': scrap.get('trade_name', 'Unknown'),
        'dailymed_name': scrap.get('active', 'Unknown (Targeted Linkage Failed)'), # Label it clearly
        'concentration': scrap.get('concentration'),
        'concentration_source': 'Scraped_Regex',
        'linkage_method': 'Local_Scraper_Fallback',
        'data_source': 'Local_Scraper',
        'quality_score': 10, # Low assurance mark
        
        'dosages': {
            'is_pediatric': False, # Safe default
            'dose_mg_kg': None,
            'adult_dose_mg': None,
            'form': form,
            'pack_size': units
        },
        
        'clinical_text': {
            'dosage': usage if usage else None,
            'interactions': None,
            'contraindications': None,
            'pediatric_use': None,
            'pregnancy': None,
            'boxed_warning': None,
            'pharmacology': pharma if pharma else None
        },
        
        'metadata': {
            'company': scrap.get('company'),
            'price_egp': scrap.get('price'),
            'old_price_egp': scrap.get('old_price'),
            'barcode': scrap.get('barcode'),
            'category': scrap.get('category'),
            'last_update': scrap.get('last_update')
        }
    }

def main():
    print("🚀 Starting Hybrid Merge Process...")
    
    # 1. Load Sources
    all_target_ids = load_ids_from_meds()
    dm_data = load_dailymed_data()
    scraped_data = load_scraped_data()
    
    # 1.5 Build Barcode Index for DailyMed
    print("  - Building Barcode Index...")
    dm_barcode_map = {}
    for dm_rec in dm_data.values():
        p_codes = dm_rec.get('product_codes', [])
        for code in p_codes:
            if code:
                # Normalize: Remove hyphens for broader matching
                clean_code = code.replace('-', '').strip()
                dm_barcode_map[clean_code] = dm_rec
                
    # 2. Merge Strategy
    hybrid_db = []
    
    stats = {
        'total_targets': len(all_target_ids),
        'dailymed_linked': 0,
        'barcode_rescue': 0,
        'scraped_fallback': 0,
        'missing': 0
    }
    
    for mid in all_target_ids:
        record = None
        
        # Priority 1: DailyMed (Exact Trade/Active Linkage)
        if mid in dm_data:
            record = dm_data[mid]
            stats['dailymed_linked'] += 1

        # Priority 0 (Tier 0): Barcode Rescue!
        # Check if Scraper found a barcode that matches DailyMed
        elif mid in scraped_data:
             scrap_rec = scraped_data[mid]
             local_bc = str(scrap_rec.get('barcode', '')).strip()
             
             if local_bc and local_bc in dm_barcode_map:
                 # MATCH FOUND via Barcode!
                 record = dm_barcode_map[local_bc]
                 # Enrich with local metadata
                 record['med_id'] = mid # Reassign ID
                 record['linkage_method'] = 'Barcode_Match'
                 record['quality_score'] += 30 # Bonus
                 stats['barcode_rescue'] += 1
             else:
                 # Priority 2: Scraped Fallback
                 record = scrap_rec
                 stats['scraped_fallback'] += 1
            
        else:
            stats['missing'] += 1
            
        if record:
            hybrid_db.append(record)
            
    # 3. Save
    print(f"\n💾 Saving Hybrid Linkage to {OUTPUT_DB}...")
    with open(OUTPUT_DB, 'w', encoding='utf-8') as f:
        for rec in hybrid_db:
            f.write(json.dumps(rec, ensure_ascii=False) + '\n')
            
    # 4. Report
    print("\n📊 Hybrid Linkage Statistics:")
    print(f"  - Total Target Drugs: {stats['total_targets']:,}")
    print(f"  - ✅ Tier 1 (DailyMed Name/Active): {stats['dailymed_linked']:,}")
    print(f"  - 💎 Tier 0 (DailyMed Barcode Match): {stats['barcode_rescue']:,} (New!)")
    print(f"  - ⚠️ Tier 2 (Local Scraper Fallback): {stats['scraped_fallback']:,}")
    print(f"  - ❌ Missing: {stats['missing']:,}")
    
    filled = stats['dailymed_linked'] + stats['scraped_fallback']
    print(f"\n🚀 Final Hybrid Coverage: {filled:,} / {stats['total_targets']:,} ({(filled/stats['total_targets'])*100:.1f}%)")
    
if __name__ == "__main__":
    main()
