#!/usr/bin/env python3
"""
Hybrid Data Injector V2: Full Coverage
Iterates through ALL DB ingredients to match NCBI data.
"""

import sqlite3
import json
import zlib
import re
import csv
from pathlib import Path

# Paths
DB_PATH = Path(__file__).parents[1] / "assets/database/mediswitch.db"
WIKEM_DATA_DIR = Path(__file__).parent / "wikem_scraper/scraped_data/drugs"
NCBI_DATA_DIR = Path(__file__).parent / "statpearls_scraper/scraped_data"

# Dose pattern
DOSE_PATTERN = re.compile(
    r'(\d+(?:\.\d+)?)\s*(?:-\s*(\d+(?:\.\d+)?))?\s*(mg|mcg|g|mg/kg|mcg/kg|units|mEq|mmol)',
    re.IGNORECASE
)

def clean_name(name):
    """Normalize name for file matching"""
    # Remove dosage info (e.g. "Amoxicillin 500mg" -> "Amoxicillin")
    name = re.sub(r'\s*\d+[\w%]*', '', name)
    # Replace special chars
    name = name.replace('/', '_').replace(' ', '_').lower()
    return name


def inject_all_data():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    print("🚀 Starting Hybrid Injection V3 (WikEM Priority + Full Coverage)...")
    
    # 1. Load WikEM Matches from CSV (Priority Mapping)
    # Maps normalized DB ingredient -> WikEM Filename/Path
    wikem_map = {} 
    wikem_matches_path = Path(__file__).parent / "wikem_scraper/wikem_matches.csv"
    
    if wikem_matches_path.exists():
        print("📋 Loading WikEM matches from CSV...")
        with open(wikem_matches_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                db_ing = row.get('DB_Ingredient_Name')
                file_path = row.get('File_Path')
                match_type = row.get('Match_Type')
                
                if db_ing and file_path and match_type in ['Exact', 'Fuzzy (>0.85)', 'Match']:
                    # Normalize db_ing to match our iteration key
                    key = clean_name(db_ing)
                    # Resolve absolute path
                    # generated path was relative to project root in some versions, or absolute. 
                    # Let's check if it exists relative to project or is just a name.
                    # The CSV sample showed: scripts/wikem_scraper/scraped_data/drugs/Cyclophosphamide.json
                    # We are in scripts/hybrid_injector.py
                    # So we need to go up one level to project root to find 'scripts/...'
                    
                    # Safer: just take basename and look in WIKEM_DATA_DIR
                    filename = Path(file_path).name
                    full_path = WIKEM_DATA_DIR / filename
                    if full_path.exists():
                        wikem_map[key] = full_path

    print(f"🔗 Loaded {len(wikem_map)} explicit WikEM matches")

    # 2. Get all active ingredients
    cursor.execute("SELECT DISTINCT med_id, ingredient FROM med_ingredients WHERE ingredient IS NOT NULL")
    all_ingredients = cursor.fetchall()
    print(f"📋 Processing {len(all_ingredients)} ingredient-med pairs...")
    
    stats = {'wikem': 0, 'ncbi': 0, 'hybrid': 0, 'none': 0}
    
    for med_id, ingredient in all_ingredients:
        # Prepare Keys
        clean_ing = clean_name(ingredient)
        if not clean_ing: continue
        if len(clean_ing) > 150: clean_ing = clean_ing[:150]

        # A. Find WikEM Data
        # Strategy 1: Check Explicit Map (Priority)
        wikem_file = wikem_map.get(clean_ing)
        
        # Strategy 2: Direct Name Match (Fallback)
        if not wikem_file:
            potential_file = WIKEM_DATA_DIR / f"{clean_ing.title()}.json"
            if potential_file.exists():
                wikem_file = potential_file

        # B. Find NCBI Data
        # Smart NCBI Finder (Subfolders)
        first_char = clean_ing[0].upper() if clean_ing[0].isalpha() else '#'
        ncbi_file = NCBI_DATA_DIR / first_char / f"{clean_ing}.json"
        
        # Load Data
        wikem_data = None
        if wikem_file:
            try:
                with open(wikem_file) as f: wikem_data = json.load(f)
            except Exception: pass
            
        ncbi_data = None
        if ncbi_file.exists():
            try:
                with open(ncbi_file) as f: ncbi_data = json.load(f)
            except Exception: pass
            
        if not ncbi_data and not wikem_data:
            stats['none'] += 1
            continue

        # Determine Source
        source = 'Hybrid' if (wikem_data and ncbi_data) else ('WikEM' if wikem_data else 'NCBI')
        stats[source.lower()] += 1
        
        # Prepare Blobs
        wikem_blob = zlib.compress(json.dumps(wikem_data).encode()) if wikem_data else None
        
        ncbi_blob = None
        ncbi_sections = {}
        if ncbi_data:
            ncbi_sections = ncbi_data.get('sections', {})
            ncbi_blob = zlib.compress(json.dumps(ncbi_data).encode())

        # Check for existing to avoid duplicates if re-running without clean
        # But for this run, we assume we might be running fresh or merging.
        # Let's do a quick check to prevent primary key errors if not cleaning.
        # cursor.execute("SELECT 1 FROM dosage_guidelines WHERE med_id = ? AND source = ?", (med_id, source))
        # if cursor.fetchone(): continue

        # Insert
        cursor.execute('''
            INSERT INTO dosage_guidelines (
                med_id,
                wikem_json_blob,
                ncbi_indications, ncbi_administration, ncbi_adverse_effects,
                ncbi_contraindications, ncbi_monitoring, ncbi_mechanism, ncbi_toxicity,
                ncbi_json_blob,
                source
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            med_id,
            wikem_blob,
            ncbi_sections.get('indications'),
            ncbi_sections.get('administration'),
            ncbi_sections.get('adverse_effects'),
            ncbi_sections.get('contraindications'),
            ncbi_sections.get('monitoring'),
            ncbi_sections.get('mechanism'),
            ncbi_sections.get('toxicity'),
            ncbi_blob,
            source
        ))
            
    conn.commit()
    print(f"🏁 Finished! Stats: {stats}")
    conn.close()


if __name__ == "__main__":
    inject_all_data()
