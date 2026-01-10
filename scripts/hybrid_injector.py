#!/usr/bin/env python3
"""
Hybrid Data Injector: WikEM + NCBI StatPearls
Populates the new clean dosage_guidelines table
"""

import sqlite3
import json
import zlib
from pathlib import Path
import re

# Paths
DB_PATH = Path(__file__).parents[1] / "assets/database/mediswitch.db"
WIKEM_DATA_DIR = Path(__file__).parent / "wikem_scraper/scraped_data/drugs"
NCBI_DATA_DIR = Path(__file__).parent / "statpearls_scraper/scraped_data"
WIKEM_MATCHES = Path(__file__).parent / "wikem_scraper/wikem_matches.csv"

# Dose extraction pattern (from wikem_parser.py)
DOSE_PATTERN = re.compile(
    r'(\d+(?:\.\d+)?)\s*(?:-\s*(\d+(?:\.\d+)?))?\s*(mg|mcg|g|mg/kg|mcg/kg|units|mEq|mmol)',
    re.IGNORECASE
)


def parse_wikem_dosage_line(text):
    """Extract numeric dosage from WikEM text"""
    match = DOSE_PATTERN.search(text)
    if not match:
        return None, None, None
    
    min_dose = float(match.group(1))
    max_dose = float(match.group(2)) if match.group(2) else min_dose
    dose_unit = match.group(3).lower()
    
    return min_dose, max_dose, dose_unit


def determine_category(text):
    """Determine patient category from text"""
    text_lower = text.lower()
    if any(kw in text_lower for kw in ['pediatric', 'child', 'infant', 'newborn', 'pals']):
        return 'Pediatric'
    elif any(kw in text_lower for kw in ['geriatric', 'elderly', 'older']):
        return 'Geriatric'
    return 'Adult'


def extract_route(text):
    """Extract route from text"""
    routes = ['IV', 'PO', 'IM', 'SC', 'IO', 'PR', 'SL', 'TD']
    for route in routes:
        if route in text.upper():
            return route
    return None


def inject_hybrid_data():
    """Main injection function"""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    print("🚀 Starting Hybrid Injection (WikEM + NCBI)...")
    
    # Load WikEM matches (ingredient names only)
    wikem_ingredients = {}  # {drug_name: ingredient_name}
    with open(WIKEM_MATCHES, 'r', encoding='utf-8') as f:
        for idx, line in enumerate(f):
            if idx == 0:  # Skip header row
                continue
            parts = line.strip().split(',')
            if len(parts) >= 3 and parts[1].strip():
                drug_name, ingredient_name, match_type = parts[0], parts[1], parts[2]
                if match_type in ['Exact', 'Fuzzy (>0.85)']:  # Only matched drugs
                    wikem_ingredients[drug_name.lower()] = ingredient_name.lower()
    
    print(f"📋 Loaded {len(wikem_ingredients)} WikEM ingredient matches")
    
    # Get all med_ids for these ingredients
    drug_to_med_ids = {}  # {drug_name: [med_id1, med_id2, ...]}
    for drug_name, ingredient in wikem_ingredients.items():
        cursor.execute('SELECT med_id FROM med_ingredients WHERE LOWER(ingredient) = ?', (ingredient,))
        med_ids = [row[0] for row in cursor.fetchall()]
        if med_ids:
            drug_to_med_ids[drug_name] = med_ids
    
    print(f"🔗 Found med_ids for {len(drug_to_med_ids)} drugs")
    
    total_inserted = 0
    
    # Process each drug
    for drug_name, med_ids in drug_to_med_ids.items():
        # 1. Load WikEM data
        wikem_file = WIKEM_DATA_DIR / f"{drug_name.title()}.json"
        wikem_data = None
        if wikem_file.exists():
            with open(wikem_file, 'r', encoding='utf-8') as f:
                wikem_data = json.load(f)
        
        # 2. Load NCBI data (if exists)
        ncbi_file = NCBI_DATA_DIR / f"{drug_name.replace('_', ' ').title().replace(' ', '_')}.json"
        ncbi_data = None
        if ncbi_file.exists():
            with open(ncbi_file, 'r', encoding='utf-8') as f:
                ncbi_data = json.load(f)
        
        # Skip if no data from either source
        if not wikem_data and not ncbi_data:
            continue
        
        # 3. Parse WikEM dosages
        wikem_rows = []
        if wikem_data:
            sections = wikem_data.get('sections', {})
            for section_name, section_data in sections.items():
                if 'dosing' not in section_name.lower() and 'dosage' not in section_name.lower():
                    continue
                
                text_content = section_data.get('text', '')
                subsections = section_data.get('subsections', {})
                
                # Process main text
                if text_content:
                    for line in text_content.split('\n'):
                        min_d, max_d, unit = parse_wikem_dosage_line(line)
                        if min_d:
                            wikem_rows.append({
                                'min_dose': min_d,
                                'max_dose': max_d,
                                'unit': unit,
                                'route': extract_route(line),
                                'category': determine_category(line),
                                'instructions': line.strip()
                            })
                
                # Process subsections
                for sub_name, sub_data in subsections.items():
                    sub_text = sub_data.get('text', '')
                    for line in sub_text.split('\n'):
                        min_d, max_d, unit = parse_wikem_dosage_line(line)
                        if min_d:
                            wikem_rows.append({
                                'min_dose': min_d,
                                'max_dose': max_d,
                                'unit': unit,
                                'route': extract_route(line),
                                'category': determine_category(line),
                                'instructions': line.strip()
                            })
        
        # 4. Compress JSON blobs
        wikem_blob = None
        if wikem_data:
            wikem_json = json.dumps(wikem_data, ensure_ascii=False)
            wikem_blob = zlib.compress(wikem_json.encode('utf-8'))
        
        ncbi_blob = None
        ncbi_sections = {}
        if ncbi_data:
            ncbi_sections = ncbi_data.get('sections', {})
            ncbi_json = json.dumps(ncbi_data, ensure_ascii=False)
            ncbi_blob = zlib.compress(ncbi_json.encode('utf-8'))
        
        # 5. Insert rows - Loop through each med_id for this drug
        for med_id in med_ids:
            if wikem_rows or ncbi_data:
                # If we have WikEM rows, create one row per dosage per med_id
                if wikem_rows:
                    for row in wikem_rows:
                        cursor.execute('''
                            INSERT INTO dosage_guidelines (
                                med_id,
                                wikem_min_dose, wikem_max_dose, wikem_dose_unit,
                                wikem_route, wikem_patient_category, wikem_instructions,
                                wikem_json_blob,
                                ncbi_indications, ncbi_administration, ncbi_adverse_effects,
                                ncbi_contraindications, ncbi_monitoring, ncbi_mechanism, ncbi_toxicity,
                                ncbi_json_blob,
                                source
                            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                        ''', (
                            med_id,
                            row['min_dose'], row['max_dose'], row['unit'],
                            row['route'], row['category'], row['instructions'],
                            wikem_blob,
                            ncbi_sections.get('indications'),
                            ncbi_sections.get('administration'),
                            ncbi_sections.get('adverse_effects'),
                            ncbi_sections.get('contraindications'),
                            ncbi_sections.get('monitoring'),
                            ncbi_sections.get('mechanism'),
                            ncbi_sections.get('toxicity'),
                            ncbi_blob,
                            'Hybrid' if ncbi_data else 'WikEM'
                        ))
                        total_inserted += 1
                else:
                    # NCBI only (no numeric dosing from WikEM)
                    cursor.execute('''
                        INSERT INTO dosage_guidelines (
                            med_id,
                            ncbi_indications, ncbi_administration, ncbi_adverse_effects,
                            ncbi_contraindications, ncbi_monitoring, ncbi_mechanism, ncbi_toxicity,
                            ncbi_json_blob,
                            source
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    ''', (
                        med_id,
                        ncbi_sections.get('indications'),
                        ncbi_sections.get('administration'),
                        ncbi_sections.get('adverse_effects'),
                        ncbi_sections.get('contraindications'),
                        ncbi_sections.get('monitoring'),
                        ncbi_sections.get('mechanism'),
                        ncbi_sections.get('toxicity'),
                        ncbi_blob,
                        'NCBI'
                    ))
                    total_inserted += 1
    
    conn.commit()
    conn.close()
    
    print("="*50)
    print(f"✅ HYBRID INJECTION COMPLETE")
    print(f"💉 Total Rows Inserted: {total_inserted}")
    print("="*50)


if __name__ == "__main__":
    inject_hybrid_data()
