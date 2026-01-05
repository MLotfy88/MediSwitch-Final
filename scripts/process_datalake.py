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

# --- REGEX PATTERNS ---
# Matches: 500mg, 1%, 20 mcg/ml, 2000 i.u., 50 mg/5ml
STRENGTH_PATTERN = re.compile(r'\b\d+(\.\d+)?\s*(mg|ml|gm|g|mcg|iu|i\.u\.|%|u)(\s*/\s*\d*(\.\d+)?\s*(mg|ml|gm|g|mcg|iu|i\.u\.|%|u))?\b', re.IGNORECASE)

# Matches common forms to remove
FORMS_PATTERN = re.compile(
    r'\b(tablet|tabs|tab|capsule|caps|cap|syrup|suspension|susp|cream|ointment|oint|gel|lotion|spray|drops|solution|sol|injection|inj|vial|ampoule|amp|suppository|supp|sachet|effervescent|chewable|scored|coated|f\.c\.|s\.r\.|x\.r\.|e\.c\.|topical|top\.|oral|nasal|vaginal|rectal|eye|ear|mouth|wash|sugar|free)\b', 
    re.IGNORECASE
)

# Salts to ignore for Generic Matching (Support Plurals)
SALT_PATTERN = re.compile(
    r'\b(hydrochloride|hcl|sodium|potassium|calcium|magnesium|maleate|tartrate|succinate|phosphate|sulfate|sulphate|acetate|citrate|nitrate|bromide|fumarate|mesylate|dihydrate|monohydrate|anhydrous|trihydrate|zinc|aluminum|besylate|estolate|ethylsuccinate|gluconate|lithium|pamoate|propionate|hydrate|oxide|peroxide|hydroxide|carbonate|bicarbonate|chloride|lactate|valerate)s?\b',
    re.IGNORECASE
)

def normalize_active_ingredient(raw_active: str, strip_salts: bool = True) -> str:
    """
    Tiered normalization.
    If strip_salts=False, we keep the salt (e.g. "diclofenac sodium").
    If strip_salts=True, we remove it (e.g. "diclofenac").
    Always applies synonym mapping and punctuation cleanup.
    """
    if not isinstance(raw_active, str): return ""
    name = raw_active.lower().strip()
    
    # 0. Basic Cleanup
    name = re.sub(r'[+,]', ' ', name) # Split multi-ingredients
    
    # Specific Normalization for 'Type B' drugs where local DB omits 'B'
    name = name.replace('polymyxin b', 'polymyxin')
    name = name.replace('amphotericin b', 'amphotericin')
    name = name.replace('vitamin b12', 'cyanocobalamin') # Common
    name = name.replace('vitamin b', 'vitamin') 
    
    # 1. Tokenize
    parts = name.split()
    clean_parts = []
    
    # Common Stop Words in Drug Names
    STOP_WORDS = {'and', 'with', 'in', 'of', 'to', 'for', 'oral', 'topical', 'injection'}
    
    for part in parts:
        # Remove punctuation
        part = re.sub(r'[^\w]', '', part)
        if not part: continue
        
        # Skip Stop Words
        if part in STOP_WORDS:
            continue
        
        # Synonym Map
        if part in SYNONYM_MAP:
            part = SYNONYM_MAP[part]
            
        # Skip Salts (ONLY if requested)
        if strip_salts and SALT_PATTERN.fullmatch(part):
            continue
            
        clean_parts.append(part)
        
    # Sort to handle order "Caffeine Paracetamol" == "Paracetamol Caffeine"
    if not clean_parts: return ""
    return " ".join(sorted(clean_parts))

# Synonyms (Local -> US Standard)
SYNONYM_MAP = {
    'paracetamol': 'acetaminophen',
    'glibenclamide': 'glyburide',
    'adrenaline': 'epinephrine',
    'noradrenaline': 'norepinephrine',
    'salbutamol': 'albuterol',
    'frusemide': 'furosemide',
    'pethidine': 'meperidine',
    'amoxycillin': 'amoxicillin',
    'sulphamethoxazole': 'sulfamethoxazole',
    'lignocaine': 'lidocaine',
    'thyroxine': 'levothyroxine',
    'oestrogen': 'estrogen',
    'omberacetam': 'piracetam', 
    'isoprenaline': 'isoproterenol',
    'orciprenaline': 'metaproterenol',
    'bendrofluazide': 'bendroflumethiazide',
    'dothiepin': 'dosulepin',
    'chlorpheniramine': 'chlorphenamine',
    'dicyclomine': 'dicycloverine',
    'procaine benzylpenicillin': 'penicillin g procaine',
    'benzylpenicillin': 'penicillin g',
    'clomiphene': 'clomifene',
    'dosulepin': 'dothiepin',
    'hydroxycarbamide': 'hydroxyurea',
    'mitozantrone': 'mitoxantrone',
    'mustine': 'mechlorethamine',
    'nicoumalone': 'acenocoumarol',
    'phenobarbitone': 'phenobarbital',
    'quinalbarbitone': 'secobarbital',
    'riboflavine': 'riboflavin',
    'sodium cromoglycate': 'cromolyn sodium',
    'stilboestrol': 'diethylstilbestrol',
    'thiopentone': 'thiopental',
    'trimethoprim sulfamethoxazole': 'sulfamethoxazole trimethoprim',
    'co-trimoxazole': 'sulfamethoxazole trimethoprim',
    'valproate sodium': 'valproic acid',
    'cefalexin': 'cephalexin',
    'cefaclor': 'cefaclor',
    'cefadroxil': 'cefadroxil',
    'cefazolin': 'cephazolin',
    'cefixime': 'cefixime',
    'cefotaxime': 'cefotaxime',
    'ceftriaxone': 'ceftriaxone',
    'aciclovir': 'acyclovir',
    'ciclosporin': 'cyclosporine',
    'dimetindene': 'dimethindene',
    'fexofenadine': 'fexofenadine',
    'guaifenesin': 'guaiphenesin',
}

# Reuse Dosage Parser Logic (from extract_dosages_production.py)
class DosageParser:
    def __init__(self):
        # Precise Pediatric Pattern
        self.mg_kg_pattern = re.compile(r'(\d+(?:\.\d+)?)\s*(?:mg|mcg|g)/kg', re.IGNORECASE)
        # Adult/Fixed Dose Pattern
        self.simple_dose_pattern = re.compile(r'\b(\d+(?:\.\d+)?)\s*(mg|mcg|g|ml)\b(?!\s*/\s*kg)', re.IGNORECASE)
        
        self.frequency_map = {
            'once daily': 24, 'daily': 24, 'q24h': 24, 'every 24 hours': 24, 'once a day': 24,
            'twice daily': 12, 'bid': 12, 'q12h': 12, 'every 12 hours': 12, '2 times a day': 12,
            'three times': 8, 'tid': 8, 'q8h': 8, 'every 8 hours': 8, '3 times a day': 8,
            'four times': 6, 'qid': 6, 'q6h': 6, 'every 6 hours': 6, '4 times a day': 6
        }

    def extract_structured_dose(self, text: str) -> Dict:
        if not text: return {}
        data = {
            'dose_mg_kg': None, 
            'adult_dose_mg': None,
            'frequency_hours': None, 
            'max_dose_mg': None, 
            'is_pediatric': False
        }
        
        # Pediatric mg/kg
        match_ped = self.mg_kg_pattern.search(text)
        if match_ped:
            data['dose_mg_kg'] = float(match_ped.group(1))
            data['is_pediatric'] = True
            
        # Adult/Fixed Dose
        rec_match = re.search(r'recommended\s*(?:dose|dosage)\s*(?:is)?\s*(\d+(?:\.\d+)?)\s*mg', text, re.IGNORECASE)
        if rec_match:
             data['adult_dose_mg'] = float(rec_match.group(1))
        else:
             # Fallback: Find simple mg occurrences
             matches = self.simple_dose_pattern.findall(text)
             # Filter out year-like numbers (1990-2030) or huge numbers
             valid_doses = [float(x[0]) for x in matches if float(x[0]) < 2000]
             if valid_doses:
                 data['adult_dose_mg'] = valid_doses[0]

        text_lower = text.lower()
        for key, hours in self.frequency_map.items():
            if key in text_lower:
                data['frequency_hours'] = hours
                break
                
        max_pattern = re.search(r'max(?:imum)?\s*(?:dose)?\s*(?:of)?\s*(\d+(?:\.\d+)?)\s*mg', text_lower)
        if max_pattern:
            data['max_dose_mg'] = float(max_pattern.group(1))
            
        return data

def clean_drug_name(raw_name: str) -> str:
    """Removes strength and form from name to create a matching key"""
    if not isinstance(raw_name, str): return ""
    name = raw_name.lower().strip()
    
    # 1. Remove Strengths (500mg, 1%...)
    name = STRENGTH_PATTERN.sub(' ', name)
    
    # 2. Remove Forms
    name = FORMS_PATTERN.sub(' ', name)
    
    # 3. Cleanup Punctuation and Whitespace
    name = re.sub(r'[^\w\s]', ' ', name)
    name = re.sub(r'\s+', ' ', name).strip()
    
    return name

# Regex from scraper.py (User's Logic)
CONCENTRATION_REGEX = re.compile(
    r"""(\d+(?:[.,]\d+)?\s*(?:mg|mcg|g|kg|ml|l|iu|%)(?:\s*/\s*(?:ml|mg|g|kg|l))?)""",
    re.IGNORECASE | re.VERBOSE
)

def extract_regex_concentration(name: str) -> Optional[str]:
    if not isinstance(name, str): return None
    match = CONCENTRATION_REGEX.search(name)
    return match.group(1).strip() if match else None

import sqlite3
import os # Assuming os is needed for file operations

def assemble_db():
    """Assembles the database from split parts."""
    print("  🧩 Assembling database from parts...")
    parts_dir = os.path.join(BASE_DIR, 'assets', 'database', 'parts')
    temp_db_path = os.path.join(BASE_DIR, 'temp_mediswitch.db')
    
    if os.path.exists(temp_db_path):
        os.remove(temp_db_path)
        
    parts = sorted([f for f in os.listdir(parts_dir) if f.startswith('mediswitch.db.part-')])
    
    with open(temp_db_path, 'wb') as outfile:
        for part in parts:
            part_path = os.path.join(parts_dir, part)
            with open(part_path, 'rb') as infile:
                outfile.write(infile.read())
                
    print(f"  ✅ Database assembled at {temp_db_path}")
    return temp_db_path

def load_ingredients_from_db():
    """Matches DailyMed to App using med_ingredients table."""
    try:
        db_path = assemble_db()
    except Exception as e:
        print(f"❌ Failed to assemble DB: {e}")
        return {}, {}, {}

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Check if table exists
    try:
        cursor.execute("SELECT count(*) FROM med_ingredients")
        count = cursor.fetchone()[0]
        print(f"  🔍 Found {count} ingredient links in med_ingredients table.")
    except sqlite3.OperationalError:
        print("❌ med_ingredients table NOT FOUND in assembled DB.")
        conn.close()
        return {}, {}, {}

    # Map: Normalized Ingredient -> List of (med_id, trade_name)
    # We join with 'drugs' table (as defined in DatabaseHelper) to get trade name
    query = """
    SELECT m.id, m.trade_name, mi.ingredient 
    FROM med_ingredients mi
    JOIN drugs m ON mi.med_id = m.id
    """
    
    active_map_exact = {}
    active_map_stripped = {}
    
    cursor.execute(query)
    rows = cursor.fetchall()
    
    for med_id, trade_name, ingredient in rows:
        if not ingredient: continue
        
        record = {'id': med_id, 'trade_name': trade_name, 'original_active': ingredient}
        
        # Tier 1: Exact
        norm_exact = normalize_active_ingredient(ingredient, strip_salts=False)
        if norm_exact:
            if norm_exact not in active_map_exact: active_map_exact[norm_exact] = []
            active_map_exact[norm_exact].append(record)
            
        # Tier 2: Stripped
        norm_stripped = normalize_active_ingredient(ingredient, strip_salts=True)
        if norm_stripped:
             if norm_stripped not in active_map_stripped: active_map_stripped[norm_stripped] = []
             active_map_stripped[norm_stripped].append(record)

    conn.close()
    if os.path.exists(db_path):
        os.remove(db_path)
        
    print(f"✅ Loaded Ingredient Maps from DB:")
    print(f"  - Exact Keys: {len(active_map_exact)}")
    print(f"  - Stripped Keys: {len(active_map_stripped)}")
    
    return {}, active_map_exact, active_map_stripped

def load_app_data() -> Dict[str, list]:
    """Wrapper to switch between CSV and DB mode."""
    # Priority: DB (med_ingredients)
    return load_ingredients_from_db()

# Legacy med.csv loader removed/bypassed

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
                
                # --- MATCHING LOGIC ---
                matched_app_records = []
                
                # --- MATCHING LOGIC ---
                matched_app_records = []
                
                # Strategy 1: Active ingredient matching (PRIORITY)
                # DailyMed often lists generic name. We match against our 'Active' column.
                if generic_name:
                    # Tier 1: Exact (with salts)
                    norm_exact = normalize_active_ingredient(generic_name, strip_salts=False)
                    if norm_exact in app_active_exact:
                        for rec in app_active_exact[norm_exact]:
                            rec['linkage_type'] = 'Active_Exact'
                            matched_app_records.append(rec)
                    
                    # Tier 2: Stripped (without salts)
                    if not matched_app_records:
                        norm_stripped = normalize_active_ingredient(generic_name, strip_salts=True)
                        if norm_stripped in app_active_stripped:
                            for rec in app_active_stripped[norm_stripped]:
                                rec['linkage_type'] = 'Active_Stripped'
                                matched_app_records.append(rec)

                # Strategy 2: Clean trade name matching (FALLBACK)
                if not matched_app_records:
                    cleaned_dailymed_name = clean_drug_name(drug_name)
                    if cleaned_dailymed_name in app_data_map:
                        for rec in app_data_map[cleaned_dailymed_name]:
                            rec['linkage_type'] = 'Trade_Name'
                            matched_app_records.append(rec)
                
                # Skip if no match found
                if not matched_app_records:
                    continue
                        
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
                        'source': 'DailyMed',  # ADD SOURCE FIELD
                        'dosages': structured_dose,
                        'clinical_text': {
                            'dosage': dosage_text[:10000] if dosage_text else None,
                            'interactions': clinical.get('drug_interactions', '')[:10000] if clinical.get('drug_interactions') else None,
                            'contraindications': clinical.get('contraindications', '')[:10000] if clinical.get('contraindications') else None,
                            'pediatric_use': pediatric_text[:10000] if pediatric_text else None,
                            'pregnancy': clinical.get('pregnancy')[:5000] if clinical.get('pregnancy') else None,
                            'boxed_warning': clinical.get('boxed_warning')[:5000] if clinical.get('boxed_warning') else None,
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

    # === MERGE WITH EXISTING DATA (WHO) ===
    DOSAGE_JSON = os.path.join(BASE_DIR, 'assets', 'data', 'dosage_guidelines.json')
    existing_data = []
    
    if os.path.exists(DOSAGE_JSON):
        try:
            with open(DOSAGE_JSON, 'r', encoding='utf-8') as f:
                existing_data = json.load(f)
            print(f"📂 Loaded {len(existing_data):,} existing records (WHO, etc.) from {DOSAGE_JSON}")
        except:
            print(f"⚠️ Could not load existing file, starting fresh.")
    
    # Convert DailyMed records to dosage_guidelines format
    dailymed_for_merge = []
    for rec in final_records:
        # Extract structured dosage info if available
        dosages = rec.get('dosages', {})
        clinical = rec.get('clinical_text', {})
        
        guideline = {
            'med_id': rec.get('med_id'),
            'dailymed_setid': rec.get('dailymed_setid'),
            'source': 'DailyMed',
            'instructions': clinical.get('dosage', ''),
            'min_dose': dosages.get('adult_dose_mg'),
            'max_dose': dosages.get('max_dose_mg'),
            'frequency': dosages.get('frequency_hours'),
            'is_pediatric': dosages.get('is_pediatric', 0)
        }
        dailymed_for_merge.append(guideline)
    
    # Check for duplicates before adding
    existing_keys = set()
    for rec in existing_data:
        key = (rec.get('med_id'), rec.get('source'), rec.get('instructions'))
        existing_keys.add(key)
    
    added_count = 0
    for dm_rec in dailymed_for_merge:
        key = (dm_rec.get('med_id'), dm_rec.get('source'), dm_rec.get('instructions'))
        if key not in existing_keys:
            existing_data.append(dm_rec)
            added_count += 1
    
    print(f"➕ Added {added_count:,} new DailyMed records (skipped {len(dailymed_for_merge) - added_count:,} duplicates)")
    
    # 7. Save MERGED data to main file
    print(f"\nProcessing complete. Scanned {processed_count:,} DailyMed records.")
    print(f"Generated {len(final_records):,} enriched DailyMed records unique by ID.")
    print(f"Total records after merge: {len(existing_data):,}")
    
    # Save to main dosage guidelines file
    with open(DOSAGE_JSON, 'w', encoding='utf-8') as f:
        json.dump(existing_data, f, indent=2, ensure_ascii=False)
    
    print(f"💾 Saved {len(existing_data):,} total records to {DOSAGE_JSON}")
    
    # Also save production output for reference (keep the detailed format)
    print(f"\nWriting detailed production DB to {PRODUCTION_OUTPUT}...")
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
