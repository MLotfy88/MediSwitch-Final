#!/usr/bin/env python3
"""
Advanced Dosage Purification Script
Parses structured data from clinical text and cleans up instructions.
"""
import json
import re
import sys

DOSAGE_JSON = 'assets/data/dosage_guidelines.json'

# --- REGEX PATTERNS ---

# Routes (English & Arabic)
ROUTE_PATTERNS = {
    'Oral': r'\b(oral|mouth|ingestion|swallow|chew|sublingual|buccal|po|p\.o\.|فم|بالفم|عن طريق الفم)\b',
    'Intravenous': r'\b(intravenous|iv|i\.v\.|infusion|حقن وريدي|بالوريد|وريد)\b',
    'Intramuscular': r'\b(intramuscular|im|i\.m\.|حقن عضلي|بالعضل|عضل)\b',
    'Subcutaneous': r'\b(subcutaneous|sc|s\.c\.|injection|حقن تحت الجلد|تحت الجلد)\b',
    'Topical': r'\b(topical|apply|skin|cream|ointment|gel|lotion|موضعي|دهان|كريم|مرهم)\b',
    'Inhalation': r'\b(inhalation|inhale|nebulizer|inhaler|استنشاق|بخاخ)\b',
    'Ophthalmic': r'\b(ophthalmic|eye|ocular|عين|قطرة عين)\b',
    'Nasal': r'\b(nasal|nose|spray|أنف|بخاخ أنف)\b',
    'Rectal': r'\b(rectal|suppository|شرج|تحاميل|لبوس)\b',
    'Vaginal': r'\b(vaginal|مهبل|تحاميل مهبلية)\b',
}

# WHO Code Mapping
WHO_ROUTE_MAP = {
    'O': 'Oral',
    'P': 'Parenteral', # Broad category, could be IV/IM
    'R': 'Rectal',
    'SL': 'Sublingual',
    'TD': 'Transdermal',
    'V': 'Vaginal',
    'Inhal': 'Inhalation',
}

# Frequencies (Hours)
FREQ_MAP = {
    r'\b(once daily|q\.?d\.?|q24h|every 24 hours)\b': 24,
    r'\b(twice daily|b\.?i\.?d\.?|q12h|every 12 hours)\b': 12,
    r'\b(three times daily|t\.?i\.?d\.?|q8h|every 8 hours)\b': 8,
    r'\b(four times daily|q\.?i\.?d\.?|q6h|every 6 hours)\b': 6,
    r'\b(every 4 hours|q4h)\b': 4,
}

# Durations (Days) - Heuristic
DURATION_PATTERN = re.compile(r'\b(?:for|x)\s*(\d+)\s*(days|weeks)', re.IGNORECASE)

# Boilerplate Removal
BOILERPLATE_PATTERNS = [
    r'PATIENTS SHOULD BE ADVISED TO.*',
    r'See full prescribing information.*',
    r'Please refer to the full.*',
    r'Section \d+\.\d+.*',
]

def clean_text(text):
    if not text: return ""
    
    # 1. Remove Headers (e.g., "2.1 Adult Dosage")
    text = re.sub(r'^\d+(\.\d+)*\s+[A-Z][a-z]+.*?\n', '', text, flags=re.MULTILINE)
    
    # 2. Remove Boilerplate
    for pattern in BOILERPLATE_PATTERNS:
        text = re.sub(pattern, '', text, flags=re.IGNORECASE)
        
    # 3. Collapse whitespace
    text = re.sub(r'\s+', ' ', text).strip()
    
    return text

def extract_structured_data(rec):
    instructions = rec.get('instructions', '') or rec.get('package_label', '')
    
    # 0. WHO Code Mapping (High Priority & Accuracy)
    route_code = rec.get('route_code')
    if route_code and not rec.get('route'):
        # Clean route code (remove extra spaces)
        rc = str(route_code).strip().upper()
        if rc in WHO_ROUTE_MAP:
            rec['route'] = WHO_ROUTE_MAP[rc]
    
    if not instructions: return rec
    
    # 1. Extract Route (Regex)
    if not rec.get('route'):
        for route, pattern in ROUTE_PATTERNS.items():
            if re.search(pattern, instructions, re.IGNORECASE):
                rec['route'] = route
                break
                
    # 2. Extract Frequency (if missing)
    if not rec.get('frequency'):
        for pattern, freq in FREQ_MAP.items():
            if re.search(pattern, instructions, re.IGNORECASE):
                rec['frequency'] = freq
                break
                
    # 3. Extract Duration (if missing)
    if not rec.get('duration'):
        match = DURATION_PATTERN.search(instructions)
        if match:
            val = int(match.group(1))
            unit = match.group(2).lower()
            if 'week' in unit: val *= 7
            rec['duration'] = val
            
    # 4. Clean Instructions
    clean_instr = clean_text(instructions)
    if clean_instr and len(clean_instr) < len(instructions):
        rec['instructions'] = clean_instr
        
    return rec

def main():
    print("🧹 Purifying dosage data...")
    try:
        with open(DOSAGE_JSON, 'r') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"❌ File not found: {DOSAGE_JSON}")
        return 1

    processed_count = 0
    enriched_count = 0
    
    cleaned_data = []
    
    for rec in data:
        original = rec.copy()
        processed = extract_structured_data(rec)
        cleaned_data.append(processed)
        
        processed_count += 1
        if processed != original:
            enriched_count += 1
            
    print(f"✅ Processed {processed_count:,} records")
    print(f"✨ Enriched/Cleaned {enriched_count:,} records")
    
    # Save
    with open(DOSAGE_JSON, 'w') as f:
        json.dump(cleaned_data, f, ensure_ascii=False, separators=(',', ':'))
        
    return 0

if __name__ == '__main__':
    sys.exit(main())
