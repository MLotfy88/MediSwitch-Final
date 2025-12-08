#!/usr/bin/env python3
"""
OpenFDA Dosage Guidelines Extractor
Extracts dosage information (Strength, Standard Dose, Max Dose, Instructions)
from OpenFDA drug label data and saves it to a JSON file.
"""

import json
import os
import zipfile
import re
import sys
from typing import List, Dict

# Configuration
DOWNLOAD_DIR = 'External_source/drug_interaction/drug-label/downloaded'
OUTPUT_FILE = 'assets/data/dosage_guidelines.json'
INGREDIENTS_FILE = 'assets/data/medicine_ingredients.json'

def load_known_ingredients(json_path: str) -> set:
    """Load known ingredients for better matching/normalization"""
    ingredients = set()
    if not os.path.exists(json_path):
        return ingredients
    try:
        with open(json_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            for ing_list in data.values():
                for ing in ing_list:
                    ingredients.add(ing.lower().strip())
    except Exception as e:
        print(f"⚠️ Warning: Could not load ingredients file: {e}")
    return ingredients

def extract_strength(text: str) -> str:
    """
    Extracts strength string from text.
    Handles '500 mg', '10 mg/mL', '0.5 %', '5 grains', etc.
    """
    if not text:
        return None
    
    text = text.lower().strip()
    
    # 1. Clean up common noise
    text = text.replace('equivalent to', '')
    
    # 2. Pattern: Number + Unit
    # Units: mg, mcg, g, ml, %, mg/ml, mcg/ml, meq, units, usp units, iu
    pattern = r'\b(\d+(?:\.\d+)?\s*(?:mg|mcg|g|ml|%|meq|units|iu|mg\/ml|mcg\/ml))\b'
    match = re.search(pattern, text)
    if match:
        return match.group(1).replace(" ", "") # Normalize: 500mg
    
    return None

def extract_start_max_dose(dosage_text: str):
    """
    Attempts to parse standard and max dose from unstructured text.
    """
    standard_dose = ""
    max_dose = ""
    
    if not dosage_text:
        return standard_dose, max_dose
        
    text_lower = dosage_text.lower()
    
    # --- Max Dose ---
    max_patterns = [
        r'max(?:imum)?\s*(?:daily)?\s*(?:dose)?\s*(?:is)?\s*(\d+(?:\.\d+)?\s*(?:mg|mcg|g|tablets?|capsules?))',
        r'not\s*more\s*than\s*(\d+(?:\.\d+)?\s*(?:mg|mcg|g|tablets?|capsules?))',
        r'do\s*not\s*exceed\s*(\d+(?:\.\d+)?\s*(?:mg|mcg|g|tablets?|capsules?))',
        r'up\s*to\s*(\d+(?:\.\d+)?\s*(?:mg|mcg|g|tablets?|capsules?))'
    ]
    
    for pattern in max_patterns:
        match = re.search(pattern, text_lower)
        if match:
            max_dose = match.group(1) # e.g. "4000 mg"
            break

    # --- Standard Dose ---
    # Prioritize specific "recommended" patterns
    rec_patterns = [
        # "Recommended dose is 50 mg"
        r'(?:recommended|usual|starting)\s*(?:adult|pediatric)?\s*dose\s*(?:is)?\s*(\d+(?:\.\d+)?\s*(?:mg|mcg|g|tablets?|capsules?|ml))',
        # "Take 1 tablet"
        r'take\s*(\d+(?:\.\d+)?\s*(?:tablets?|capsules?|pills?))',
        # "1 to 2 tablets"
        r'(\d+(?:\s*to\s*\d+)?\s*(?:tablets?|capsules?))\s*(?:every|per|daily)',
        # "50 mg every 6 hours"
        r'(\d+(?:\.\d+)?\s*(?:mg|mcg|g|ml))\s+(?:every|q\d|once|twice|three)',
        # "Apply X times"
        r'(apply\s.*?\d+\s*times)'
    ]
    
    for pattern in rec_patterns:
        match = re.search(pattern, text_lower)
        if match:
            standard_dose = match.group(0 if 'group' not in dir(match) else 1) # Capture group 1 if possible, else full match
            # Cleanup: remove 'take ' if captured
            standard_dose = standard_dose.replace('take ', '')
            break
            
    # Fallback: simple frequency "3 times daily"
    if not standard_dose:
        freq_match = re.search(r'(\d+\s*(?:to\s*\d+)?)\s*times\s*daily', text_lower)
        if freq_match:
             standard_dose = freq_match.group(0)

    return standard_dose, max_dose

def process_file(zip_path: str, known_ingredients: set) -> List[Dict]:
    file_guidelines = []
    
    if not os.path.exists(zip_path):
        return []

    print(f"Processing: {os.path.basename(zip_path)}")
    try:
        with zipfile.ZipFile(zip_path, 'r') as z:
            json_files = [f for f in z.namelist() if f.endswith('.json')]
            if not json_files: return []
            
            with z.open(json_files[0]) as f:
                data = json.load(f)
                results = data.get('results', [])
                
                for record in results:
                    openfda = record.get('openfda', {})
                    
                    # 1. Identify Active Ingredient
                    # Expanded lookup: substance -> generic -> brand
                    substances = openfda.get('substance_name', [])
                    generics = openfda.get('generic_name', [])
                    brands = openfda.get('brand_name', [])
                    
                    active_ingredient = None
                    if substances: active_ingredient = substances[0]
                    elif generics: active_ingredient = generics[0]
                    # elif brands: active_ingredient = brands[0] # Brand maps poorly to generic structure
                    
                    if not active_ingredient: continue
                    
                    active_ingredient = active_ingredient.lower().strip()
                    
                    # 2. Extract Strength
                    # Look in SPL first, then dosage_forms_and_strengths, then maybe openfda fields
                    strength = None
                    spl_elements = record.get('spl_product_data_elements', [])
                    if spl_elements: strength = extract_strength(spl_elements[0])
                    
                    if not strength:
                        dfs = record.get('dosage_forms_and_strengths', [])
                        if dfs: strength = extract_strength(dfs[0])
                    
                    if not strength:
                        # Try to extract from active ingredient name if it contains numbers?
                        # e.g. "Acetaminophen 500mg"
                        strength = extract_strength(active_ingredient)

                    if not strength:
                        strength = "general" # Keep record even without strength for general lookup

                    # 3. Extract Dose Info
                    dosage_text_list = record.get('dosage_and_administration', [])
                    dosage_text = dosage_text_list[0] if dosage_text_list else ""
                    
                    standard_dose, max_dose = extract_start_max_dose(dosage_text)
                    
                    # 4. Instructions
                    instructions_list = record.get('instructions_for_use', []) or record.get('patient_medication_information', [])
                    package_label = instructions_list[0] if instructions_list else ""
                    
                    if not package_label and dosage_text:
                         # Use a clean slice of dosage text
                         package_label = dosage_text[:500].replace('\n', ' ')
                    
                    package_label = package_label.strip()

                    # Relaxed inclusion criteria:
                    # If we have standard dose OR max dose OR (Strength AND Package Label)
                    if not standard_dose and not max_dose and not (strength != 'general' and package_label):
                        # Still skip empty records to avoid noise
                        continue

                    guideline = {
                        'active_ingredient': active_ingredient,
                        'strength': strength,
                        'standard_dose': standard_dose if standard_dose else None,
                        'max_dose': max_dose if max_dose else None,
                        'package_label': package_label if package_label else None
                    }
                    
                    file_guidelines.append(guideline)

    except Exception as e:
        print(f"Error processing {zip_path}: {e}")
        
    return file_guidelines

def main():
    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
    
    known_ingredients = load_known_ingredients(INGREDIENTS_FILE)
    
    all_guidelines = {} # Key by (active, strength) to dedup
    
    # Process all zip files in download dir
    if not os.path.exists(DOWNLOAD_DIR):
        print(f"Download directory {DOWNLOAD_DIR} does not exist.")
        return

    files = sorted([f for f in os.listdir(DOWNLOAD_DIR) if f.endswith('.zip')])
    
    for filename in files:
        path = os.path.join(DOWNLOAD_DIR, filename)
        guidelines = process_file(path, known_ingredients)
        
        for g in guidelines:
            key = (g['active_ingredient'], g['strength'])
            
            # Simple dedup logic: prefer records with more content
            if key in all_guidelines:
                existing = all_guidelines[key]
                score_existing = (1 if existing['standard_dose'] else 0) + (1 if existing['max_dose'] else 0) + (1 if len(existing['package_label']) > 50 else 0)
                score_new = (1 if g['standard_dose'] else 0) + (1 if g['max_dose'] else 0) + (1 if len(g['package_label']) > 50 else 0)
                
                if score_new > score_existing:
                    all_guidelines[key] = g
            else:
                all_guidelines[key] = g
                
        print(f"  Aggregated {len(all_guidelines)} unique guidelines so far...")

    # Convert to list
    final_list = list(all_guidelines.values())
    
    print(f"\nTotal unique dosage guidelines extracted: {len(final_list)}")
    
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(final_list, f, indent=2)
        
    print(f"Saved to {OUTPUT_FILE}")

if __name__ == "__main__":
    main()
