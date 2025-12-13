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

# File Paths
DATALAKE_FILE = 'production_data/dailymed_full_database.json'
MEDS_CSV = 'meds_updated.csv'  # Existing app database
OUTPUT_FILE = 'production_data/dosages_final.json'

# Reuse Dosage Parser Logic (from extract_dosages_production.py)
class DosageParser:
    def __init__(self):
        self.mg_kg_pattern = re.compile(r'(\d+(?:\.\d+)?)\s*(?:mg|mcg|g)/kg', re.IGNORECASE)
        self.frequency_map = {
            'once daily': 24, 'daily': 24, 'q24h': 24, 'every 24 hours': 24,
            'twice daily': 12, 'bid': 12, 'q12h': 12, 'every 12 hours': 12,
            'three times': 8, 'tid': 8, 'q8h': 8, 'every 8 hours': 8,
            'four times': 6, 'qid': 6, 'q6h': 6, 'every 6 hours': 6
        }

    def extract_structured_dose(self, text: str) -> Dict:
        if not text: return {}
        data = {'dose_mg_kg': None, 'frequency_hours': None, 'max_dose_mg': None, 'is_pediatric': False}
        
        match = self.mg_kg_pattern.search(text)
        if match:
            data['dose_mg_kg'] = float(match.group(1))
            data['is_pediatric'] = True
            
        text_lower = text.lower()
        for key, hours in self.frequency_map.items():
            if key in text_lower:
                data['frequency_hours'] = hours
                break
                
        max_pattern = re.search(r'max(?:imum)?\s*(?:dose)?\s*(?:of)?\s*(\d+(?:\.\d+)?)\s*mg', text_lower)
        if max_pattern:
            data['max_dose_mg'] = float(max_pattern.group(1))
            
        return data

# Regex from scraper.py (User's Logic)
CONCENTRATION_REGEX = re.compile(
    r"""(\d+(?:[.,]\d+)?\s*(?:mg|mcg|g|kg|ml|l|iu|%)(?:\s*/\s*(?:ml|mg|g|kg|l))?)""",
    re.IGNORECASE | re.VERBOSE
)

def extract_regex_concentration(name: str) -> Optional[str]:
    if not isinstance(name, str): return None
    match = CONCENTRATION_REGEX.search(name)
    return match.group(1).strip() if match else None

def load_app_data() -> Dict[str, Dict]:
    """Load meds_updated.csv to get existing app trade names and IDs"""
    if not os.path.exists(MEDS_CSV):
        print("⚠️ meds_updated.csv not found. Skipping linkage.")
        return {}
    
    try:
        df = pd.read_csv(MEDS_CSV, dtype=str)
        # Create map: Trade Name (lower) -> Data
        app_map = {}
        for _, row in df.iterrows():
            name = str(row.get('trade_name', '')).lower().strip()
            if name:
                app_map[name] = row.to_dict()
        print(f"✅ Loaded {len(app_map)} records from app database.")
        return app_map
    except Exception as e:
        print(f"❌ Error loading CSV: {e}")
        return {}

def process_datalake():
    print("="*80)
    print("Processing DailyMed Data Lake")
    print("="*80)
    
    # 1. Load Data (Streaming)
    # Note: Extractor now produces .jsonl
    DATALAKE_FILE_L = DATALAKE_FILE + 'l' # .jsonl
    
    if not os.path.exists(DATALAKE_FILE_L):
        print(f"❌ Data Lake file not found: {DATALAKE_FILE_L}")
        # Try fallback to .json if old version ran
        if os.path.exists(DATALAKE_FILE):
             print(f"⚠️ Found legacy .json file, using that...")
             DATALAKE_FILE_L = DATALAKE_FILE
        else:
             print("❌ No data file found. Exiting.")
             return

    print(f"Processing {DATALAKE_FILE_L}...")
    
    # Init Parsers
    dosage_parser = DosageParser()
    app_data_map = load_app_data()
    final_records = []
    
    processed_count = 0
    
    try:
        with open(DATALAKE_FILE_L, 'r', encoding='utf-8') as f_in:
            for line in f_in:
                if not line.strip(): continue
                try:
                    entry = json.loads(line)
                except json.JSONDecodeError:
                    if "[" in line and "]" in line: # Fallback for reading array JSON line by line (rare)
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
                    if ing.get('concentration_string'):
                        concentration = ing['concentration_string']
                        source_concentration = "XML_Structured"
                if not concentration and drug_name:
                    regex_conc = extract_regex_concentration(drug_name)
                    if regex_conc:
                        concentration = regex_conc
                        source_concentration = "Name_Regex"
                        
                # Link
                app_info = app_data_map.get(drug_name.lower().strip())
                app_id = app_info.get('id') if app_info else None
                
                # Dosage
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

                record = {
                    'id': entry.get('set_id'),
                    'app_id': app_id,
                    'drug_name': drug_name,
                    'generic_name': generic_name,
                    'concentration': concentration,
                    'concentration_source': source_concentration,
                    'dosages': {
                        'structured': structured_dose,
                        'text_dosage': dosage_text[:3000] if dosage_text else None,
                        'text_pediatric': pediatric_text[:3000] if pediatric_text else None,
                        'text_pregnancy': clinical.get('pregnancy'),
                        'text_boxed_warning': clinical.get('boxed_warning'),
                    },
                    'metadata': {
                        'source': 'DailyMed',
                        'title': entry.get('title')
                    }
                }
                final_records.append(record)
                
    except Exception as e:
        print(f"Error during processing: {e}")
        # Don't return, save what we have

    # 7. Save
    print(f"\nProcessing complete. Scanned {processed_count:,} records.")
    print(f"Generated {len(final_records):,} enriched records.")
    
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(final_records, f, indent=2, ensure_ascii=False)
    print(f"✅ Saved to {OUTPUT_FILE}")

if __name__ == '__main__':
    process_datalake()
