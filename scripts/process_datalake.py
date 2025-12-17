#!/usr/bin/env python3
"""
DailyMed Data Lake Processor & Integrator
Filters the raw Data Lake JSON and enriches it with:
1. Structured Dosages (re-parsed from text)
2. Concentrations (XML + Regex Strategy)
3. Safety Sections (Boxed Warnings, etc.)
4. Linkage to dwaprices data (if available)
"""

import json
import re
import os
import pandas as pd
from typing import List, Dict, Optional
import traceback
import gzip

# --- CONFIGURATION ---
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# Try GZIP first, then JSONL, then JSON
DATALAKE_FILE = os.path.join(BASE_DIR, 'production_data', 'dailymed_full_database.jsonl.gz') 
if not os.path.exists(DATALAKE_FILE):
    DATALAKE_FILE = os.path.join(BASE_DIR, 'production_data', 'dailymed_full_database.jsonl')
if not os.path.exists(DATALAKE_FILE):
    DATALAKE_FILE = os.path.join(BASE_DIR, 'production_data', 'dailymed_full_database.json')
PRODUCTION_OUTPUT = os.path.join(BASE_DIR, 'production_data', 'production_dosages.jsonl')
OUTPUT_FILE = os.path.join(BASE_DIR, 'production_data', 'production_debug.json')
MEDS_CSV = os.path.join(BASE_DIR, 'assets', 'meds.csv')

# ... (Regex patterns unchanged) ...

# ... (Helper functions unchanged) ...

def process_datalake():
    print("="*80)
    print("Processing DailyMed Data Lake")
    print("="*80)
    
    # 1. Load Data (Streaming)
    DATALAKE_FILE_L = DATALAKE_FILE # Use the detected path directly
    # Check explicitly for .jsonl output from extractor if the .gz isn't found?
    # The logic above already sets DATALAKE_FILE to exist or fallbacks.
    
    if not os.path.exists(DATALAKE_FILE_L):
        print(f"❌ Data Lake file not found: {DATALAKE_FILE_L}")
        return

    print(f"Processing {DATALAKE_FILE_L}...")
    
    # Init Parsers
    dosage_parser = DosageParser()
    app_data_map, app_active_exact, app_active_stripped = load_app_data()
    best_matches = {} # med_id -> {score, record}
    
    processed_count = 0
    
    try:
        # Smart Open (GZIP vs Text)
        if DATALAKE_FILE_L.endswith('.gz'):
            open_func = gzip.open
        else:
            open_func = open
            
        with open_func(DATALAKE_FILE_L, 'rt', encoding='utf-8') as f_in:
            for line in f_in:
                if not line.strip(): continue
                try:
                    entry = json.loads(line)
                except json.JSONDecodeError:
                    if "[" in line or "]" in line: # Skip array brackets
                        continue
                    continue # Skip invalid line
                
                processed_count += 1
                if processed_count % 5000 == 0:
                    print(f"  Processed {processed_count:,} records...")

                # --- Core Logic ---
                # Skip incomplete records
                if not entry.get('products') and not entry.get('clinical_data'):
                    continue
                    
                # Extract basic info
                clinical = entry.get('clinical_data', {})
                products = entry.get('products', [])
                
                # Primary Drug Name
                drug_name = "Unknown"
                generic_name = "Unknown"
                if products:
                    drug_name = products[0].get('proprietary_name') or products[0].get('non_proprietary_name')
                    generic_name = products[0].get('non_proprietary_name')
                if not drug_name: continue
                
                # Enrich Concentration
                concentration = None
                source_concentration = "None"
                if products and products[0].get('ingredients'):
                    ing = products[0]['ingredients'][0]
                    # Strategy A: Explicit String
                    if ing.get('concentration_string'):
                        concentration = ing['concentration_string']
                        source_concentration = "XML_Structured"
                    # Strategy B: Construct from Value/Unit
                    elif ing.get('strength_value') and ing.get('strength_unit'):
                        s_val = ing['strength_value']
                        s_unit = ing['strength_unit']
                        # Check denominator
                        if ing.get('denominator_value') and ing.get('denominator_unit'):
                           d_val = ing['denominator_value']
                           d_unit = ing['denominator_unit']
                
                for prod in products:
                    # Try regex extraction first (pre-computed in extract_full_dailymed)
                        if prod.get('regex_concentration'):
                            concentration = prod.get('regex_concentration')
                            source_concentration = "DailyMed_Regex"
                            break
                        
                # Loop through matched App IDs and create candidates
                for app_rec in matched_app_records:
                    med_id = app_rec.get('id')
                    if not med_id: continue
                    
                    # --- CONCENTRATION MERGE ---
                    final_conc = None
                    conc_source = "None"
                    
                    # 1. App Regex
                    if app_rec.get('original_name'):
                         app_conc_match = STRENGTH_PATTERN.search(app_rec['original_name'])
                         if app_conc_match:
                             final_conc = app_conc_match.group(0).strip()
                             conc_source = "App_Name_Regex"
                    
                    # 2. DailyMed Fallback
                    if (not final_conc or final_conc == "None") and concentration:
                        final_conc = concentration
                        conc_source = source_concentration
                        
                    # --- DOSAGE PARSING ---
                    dosage_text = clinical.get('dosage_and_administration', '')
                    pediatric_text = clinical.get('pediatric_use', '')
                    structured_dose = {}
                    if dosage_text:
                        structured_dose = dosage_parser.extract_structured_dose(dosage_text)
                    if pediatric_text and not structured_dose.get('is_pediatric'):
                         peds_struct = dosage_parser.extract_structured_dose(pediatric_text)
                         if peds_struct.get('dose_mg_kg'):
                             structured_dose = peds_struct
                             structured_dose['is_pediatric'] = True

                    # Pack Record
                    candidate_record = {
                        'med_id': med_id,
                        'dailymed_setid': entry.get('set_id'),
                        'dailymed_product_name': drug_name or generic_name,
                        'trade_name': app_rec.get('trade_name'),
                        'dailymed_name': drug_name or generic_name,
                        'concentration': final_conc,
                        'concentration_source': conc_source,
                        'linkage_method': app_rec.get('linkage_type'),
                        'dosages': structured_dose,
                        'clinical_text': {
                            'dosage': dosage_text[:2000] if dosage_text else None,
                            'interactions': clinical.get('drug_interactions', '')[:1000] if clinical.get('drug_interactions') else None,
                            'contraindications': clinical.get('contraindications', '')[:1000] if clinical.get('contraindications') else None,
                            'pediatric_use': pediatric_text[:2000] if pediatric_text else None,
                            'pregnancy': clinical.get('pregnancy')[:500] if clinical.get('pregnancy') else None,
                            'boxed_warning': clinical.get('boxed_warning')[:500] if clinical.get('boxed_warning') else None,
                        },
                         'set_id': entry.get('set_id'),
                         'product_codes': [p.get('product_code') for p in products if p.get('product_code')],
                         'matching_confidence': 0.0
                    }
                    
                    # --- SCORING LOGIC ---
                    score = 0
                    if structured_dose.get('adult_dose_mg'): score += 30
                    if app_rec.get('linkage_type') == 'Trade_Name': score += 20
                    elif app_rec.get('linkage_type') == 'Active_Exact': score += 10
                    
                    # Filter out candidates with NO data at all
                    if score == 0 and not dosage_text:
                         continue
                         
                    # Best Match Selection
                    if med_id not in best_matches or score > best_matches[med_id]['score']:
                        candidate_record['quality_score'] = score
                        best_matches[med_id] = {
                            'score': score,
                            'record': candidate_record
                        }
                
    except Exception as e:
        print(f"❌ Error during processing: {e}")
        import traceback
        traceback.print_exc()

    # Flatten best matches
    final_records = [v['record'] for v in best_matches.values()]

    # 7. Save
    print(f"\nProcessing complete. Scanned {processed_count:,} records.")
    print(f"Generated {len(final_records):,} enriched records unique by ID.")
    
    # Save Production Output (JSONL)
    print(f"Writing production DB to {PRODUCTION_OUTPUT}...")
    with open(PRODUCTION_OUTPUT, 'w', encoding='utf-8') as f:
        for rec in final_records:
            f.write(json.dumps(rec, ensure_ascii=False) + '\n')
            
    # Save Debug Condensed Output (First 2000 records)
    print(f"Writing debug sample to {OUTPUT_FILE}...")
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(final_records[:2000], f, indent=2, ensure_ascii=False)
        
    print(f"✅ Success.")

if __name__ == '__main__':
    process_datalake()
