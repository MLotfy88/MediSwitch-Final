#!/usr/bin/env python3
"""
Generate Known Ingredients List
Extracts unique active ingredients from scraped data for use in Interaction Extraction.
"""

import json
import os
import pandas as pd

import re

INPUT_FILE = 'assets/meds.csv'
OUTPUT_FILE = 'production_data/known_ingredients.json'

# Salts to ignore for Generic Matching (Support Plurals)
SALT_PATTERN = re.compile(
    r'\b(hydrochloride|hcl|sodium|potassium|calcium|magnesium|maleate|tartrate|succinate|phosphate|sulfate|sulphate|acetate|citrate|nitrate|bromide|fumarate|mesylate|dihydrate|monohydrate|anhydrous|trihydrate|zinc|aluminum|besylate|estolate|ethylsuccinate|gluconate|lithium|pamoate|propionate|hydrate|oxide|peroxide|hydroxide|carbonate|bicarbonate|chloride|lactate|valerate)s?\b',
    re.IGNORECASE
)

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

def normalize_active_ingredient(raw_active: str, strip_salts: bool = True) -> str:
    """Standard clinical normalization logic."""
    if not isinstance(raw_active, str): return ""
    name = raw_active.lower().strip()
    
    # Basic Cleanup
    name = re.sub(r'[+,]', ' ', name)
    name = name.replace('polymyxin b', 'polymyxin')
    name = name.replace('amphotericin b', 'amphotericin')
    name = name.replace('vitamin b12', 'cyanocobalamin')
    name = name.replace('vitamin b', 'vitamin') 
    
    parts = name.split()
    clean_parts = []
    STOP_WORDS = {'and', 'with', 'in', 'of', 'to', 'for', 'oral', 'topical', 'injection'}
    
    for part in parts:
        # Remove punctuation
        part = re.sub(r'[^\w]', '', part)
        if not part: continue
        if part in STOP_WORDS: continue
        
        # Synonym Map
        if part in SYNONYM_MAP:
            part = SYNONYM_MAP[part]
            
        # Strip Salts
        if strip_salts and SALT_PATTERN.fullmatch(part):
            continue
            
        clean_parts.append(part)
        
    if not clean_parts: return ""
    return " ".join(sorted(clean_parts))

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
            # 1. Split by '+'
            parts = [p.strip().lower() for p in str(val).split('+')]
            for part in parts:
                # 2. Strip concentration patterns (10mg, 5%, etc)
                cleaned_part = re.sub(r'\b\d+(?:\.\d+)?\s*(?:mg|mcg|g|ml|%|iu|units?|u)\b', '', part, flags=re.IGNORECASE).strip()
                # 3. Normalize
                normalized = normalize_active_ingredient(cleaned_part)
                if normalized:
                    ingredients.add(normalized)
            
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
