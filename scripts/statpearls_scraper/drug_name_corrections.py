"""
Drug Name Correction Dictionary
Maps incorrect/incomplete ingredient names to their correct pharmaceutical names
"""

# Common misspellings in the database
SPELLING_CORRECTIONS = {
    # Electrolytes
    'soduim': 'sodium',
    'sodiumm': 'sodium',
    'potassuim': 'potassium',
    'potasium': 'potassium',
    'magnesiun': 'magnesium',
    'magnesuim': 'magnesium',
    'calcuim': 'calcium',
    'calicum': 'calcium',
    
    # Common drugs
    'chondrotin': 'chondroitin',
    'chondritin': 'chondroitin',
    'bromalin': 'bromelain',
    'bromelin': 'bromelain',
    'camomil': 'chamomile',
    'chamomil': 'chamomile',
    'gingenol': 'gingerol',
    'paracetamol': 'acetaminophen',  # International name
    'salycilate': 'salicylate',
    'salicylic': 'salicylate',
    'hyaluronate': 'hyaluronic acid',
    
    # Vitamins
    'vitamine': 'vitamin',
    'vit ': 'vitamin ',
    
    # Minerals & salts - Generic forms
    'ferrous bisglycinate': 'iron',
    'ferrous glycine': 'iron',
    'ferrous sulphate': 'iron',
    'ferrous fumarate': 'iron',
    'ferric': 'iron',
    
    # B-vitamin specific names → generic
    'cobalamin': 'cobalamin',  # Keep as is, will be handled in precomputed
    'cyanocobalamin': 'cobalamin',
    'methylcobalamin': 'cobalamin',
    'pyridoxine': 'pyridoxine',  # Keep specific name
    'thiamine': 'thiamine',
    'riboflavin': 'riboflavin',
    'niacin': 'niacin',
    'nicotinamide': 'niacin',
    'pantothenic acid': 'pantothenic acid',  # Keep as is
    'biotin': 'biotin',
    'folic acid': 'folate',
    'folate': 'folate',
    'tocopherol': 'tocopherol',
    'retinol': 'retinol',
    'ascorbic acid': 'ascorbic acid',
    'calciferol': 'calciferol',
    
    # Abbreviated/incomplete
    'hcl': 'hydrochloride',
    'sulph': 'sulfate',
    'phos': 'phosphate',
    'bicarb': 'bicarbonate',
}

# Complete name mappings for common abbreviations
ABBREVIATION_EXPANSIONS = {
    'nsaid': 'nonsteroidal anti-inflammatory',
    'ace': 'angiotensin converting enzyme',
    'arb': 'angiotensin receptor blocker',
    'ssri': 'selective serotonin reuptake inhibitor',
    'ppi': 'proton pump inhibitor',
}

# Known incomplete/malformed entries to skip
SKIP_PATTERNS = [
    'lysi',  # Incomplete
    'vit (',  # Malformed
    'e k)',   # Malformed
    ')',      # Just parenthesis
    '(',      # Just parenthesis
]

def normalize_drug_name(name):
    """
    Normalize drug name by:
    1. Fixing spelling errors
    2. Expanding abbreviations
    3. Removing doses/concentrations
    4. Cleaning special characters
    """
    if not name:
        return ""
    
    # Skip known bad entries
    for pattern in SKIP_PATTERNS:
        if pattern in name.lower():
            return ""
    
    original = name
    normalized = name.lower().strip()
    
    # Remove doses and concentrations (CRITICAL!)
    # Patterns: 10mg, 500 mg, 0.5%, 100mcg, 2.5 iu, etc.
    import re
    normalized = re.sub(r'\s*\d+\.?\d*\s*(mg|mcg|gm|ml|iu|%|units?)\s*', ' ', normalized, flags=re.IGNORECASE)
    
    # Remove parenthetical content (usually salt forms or additional info)
    normalized = re.sub(r'\([^)]*\)', '', normalized)
    
    # Apply spelling corrections
    for wrong, correct in SPELLING_CORRECTIONS.items():
        if wrong in normalized:
            normalized = normalized.replace(wrong, correct)
    
    # Expand abbreviations
    for abbr, expansion in ABBREVIATION_EXPANSIONS.items():
        if abbr in normalized.split():
            normalized = normalized.replace(abbr, expansion)
    
    # Clean up extra spaces
    normalized = ' '.join(normalized.split())
    
    # Capitalize first letter (StatPearls uses title case)
    if normalized:
        normalized = normalized[0].upper() + normalized[1:]
    
    return normalized.strip()


# Pre-computed corrections for common database entries
# This speeds up processing by avoiding regex on every call
PRECOMPUTED_CORRECTIONS = {
    # B-Vitamins
    'cyanocobalamin': 'Cobalamin',
    'methylcobalamin': 'Cobalamin',
    'hydroxocobalamin': 'Cobalamin',
    'pyridoxine': 'Pyridoxine',
    'pyridoxine hcl': 'Pyridoxine',
    'pyridoxine hydrochloride': 'Pyridoxine',
    'thiamine': 'Thiamine',
    'riboflavin': 'Riboflavin',
    'niacin': 'Niacin',
    'nicotinamide': 'Niacin',
    'pantothenic acid': 'Pantothenic acid',
    'biotin': 'Biotin',
    'folic acid': 'Folate',
    'folate': 'Folate',
    
    # Other vitamins
    'ascorbic acid': 'Ascorbic acid',
    'tocopherol': 'Tocopherol',
    'retinol': 'Retinol',
    'calciferol': 'Calciferol',
    'cholecalciferol': 'Cholecalciferol',
    
    # Iron forms
    'ferrous bisglycinate': 'Iron',
    'ferrous sulphate': 'Iron',
    'ferrous sulfate': 'Iron',
    'ferrous fumarate': 'Iron',
    'ferrous gluconate': 'Iron',
    'ferric': 'Iron',
    
    # Common drugs with salt forms
    'amoxicillin trihydrate': 'Amoxicillin',
    'metformin hcl': 'Metformin',
    'metformin hydrochloride': 'Metformin',
    'ranitidine hcl': 'Ranitidine',
    'ciprofloxacin hcl': 'Ciprofloxacin',
    'omeprazole magnesium': 'Omeprazole',
    
    # Misspellings from database
    'soduim hyaluronate': 'Sodium hyaluronate',
    'paracetamol': 'Acetaminophen',
    'chondrotin': 'Chondroitin',
    'bromalin': 'Bromelain',
}
