#!/usr/bin/env python3
"""
Advanced Dosage Purification Script
Parses structured data from clinical text and cleans up instructions.
"""
import gzip
import json
import re
import sys

DOSAGE_JSON = 'assets/data/dosage_guidelines.json.gz'

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

# Enhanced Boilerplate Removal
BOILERPLATE_PATTERNS = [
    r'PATIENTS? SHOULD BE (ADVISED|INSTRUCTED|INFORMED).*?(\.|$)',
    r'See (full|complete) prescrib(ing|tion) information.*?(\.|$)',
    r'Please (refer to|consult) the (full|package insert).*?(\.|$)',
    r'Section \d+(\.\d+)?:?\s*',
    r'Table \d+:?\s*',
    r'Figure \d+:?\s*',
    r'\(?see (section|table|figure) \d+.*?\)?',
    r'For (complete|full|additional) information.*?(\.|$)',
    r'The following is a summary.*?(\.|$)',
    r'This [a-z]+ contains.*?(\.|$)',
    r'CLINICAL PHARMACOLOGY.*',
    r'INDICATIONS AND USAGE.*',
    r'Always (consult|check|follow).*physician.*?(\.|$)',
    r'As directed by.*physician.*?(\.|$)',
]

# Actionable Sentence Starters (Clinical)
CLINICAL_VERBS = [
    r'\bThe recommended (dose|dosage) (is|for)',
    r'\b(Take|Administer|Give|Apply|Inject|Swallow)',
    r'\b(Initial|Starting|Usual|Typical) (dose|dosage)',
    r'\b(Maintenance|Daily|Maximum|Minimum) (dose|dosage)',
    r'\b(\d+\s*(?:mg|mcg|g|ml|units?))',  # Contains numeric dosage
]

def clean_text(text):
    """Advanced clinical text purification"""
    if not text: return ""
    
    # Pre-cleaning: remove artifacts seen in screenshots
    text = re.sub(r'Standard Dose:\s*\d+(\.\d+)?\s*(mg|g|mcg|ml)\.?', '', text, flags=re.IGNORECASE)
    text = re.sub(r'Pediatric Dose:.*?(?=\.|$)', '', text, flags=re.IGNORECASE) # Remove separate pediatric section if mixed

    # Step 1: Remove specific section headers (Robust)
    # Matches: "2 DOSAGE AND ADMINISTRATION", "2.1 Adults", "DOSAGE AND ADMINISTRATION"
    text = re.sub(r'^\s*\d+(\.\d+)*\s*[A-Z\s]+\s+', '', text)
    text = re.sub(r'DOSAGE AND ADMINISTRATION', '', text, flags=re.IGNORECASE)
    text = re.sub(r'INDICATIONS AND USAGE', '', text, flags=re.IGNORECASE)

    # Step 2: Remove boilerplate (Legal disclaimers, references)
    for pattern in BOILERPLATE_PATTERNS:
        text = re.sub(pattern, '', text, flags=re.IGNORECASE | re.DOTALL)
    
    # Step 3: Extract only clinically actionable sentences
    sentences = re.split(r'(?<=[.!])\s+', text) # Split after punctuation
    if len(sentences) == 1 and len(text) > 100: # Fallback for bad punctuation
         sentences = re.split(r'\.\s+', text)

    useful_sentences = []
    seen_hashes = set()
    
    for sent in sentences:
        sent = sent.strip()
        if len(sent) < 10: continue
        
        # Remove partial header residues
        if re.match(r'^[A-Z\s]+$', sent): continue # All caps sentence usually header
        
        # Deduplication (Simple Hash)
        sent_hash = hash(sent.lower())
        if sent_hash in seen_hashes: continue
        
        # Must match at least one clinical pattern
        is_clinical = any(re.search(pattern, sent, re.IGNORECASE) for pattern in CLINICAL_VERBS)
        
        # Special Case: If it starts with a number (Dosage), keep it
        if re.match(r'^\d+(\.\d+)?\s*(mg|g|mcg|ml|tablet|capsule)', sent, re.IGNORECASE):
            is_clinical = True

        if is_clinical:
            useful_sentences.append(sent)
            seen_hashes.add(sent_hash)
    
    # Step 4: Reconstruct text
    cleaned = '. '.join(useful_sentences)
    if cleaned and not cleaned.endswith('.'): 
        cleaned += '.'
    
    # Step 5: Collapse whitespace
    cleaned = re.sub(r'\s+', ' ', cleaned).strip()
    
    # Safety: If result is empty or just punctuation, return original (truncated) or None?
    # Better to return original cleaned of gross headers than nothing
    if len(cleaned) < 5: 
        # Fallback: simple strip
        return text.strip()
        
    return cleaned

def extract_frequency_advanced(text):
    """Parses complex frequency patterns"""
    # 1. "Every X to Y days" -> Take avg or min? Take Min (Conservative)
    match = re.search(r'every\s+(\d+)\s*(?:[-to]\s*(\d+))?\s*days?', text, re.IGNORECASE)
    if match:
        days = int(match.group(1))
        return days * 24
        
    # 2. "Every X to Y hours"
    match = re.search(r'every\s+(\d+)\s*(?:[-to]\s*(\d+))?\s*hours?', text, re.IGNORECASE)
    if match:
        hours = int(match.group(1))
        return hours
        
    return None

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
        
        # Try advanced patterns if still missing
        if not rec.get('frequency'):
            rec['frequency'] = extract_frequency_advanced(instructions)
                
    # 3. Extract Duration (if missing)
    if not rec.get('duration'):
        match = DURATION_PATTERN.search(instructions)
        if match:
            val = int(match.group(1))
            unit = match.group(2).lower()
            if 'week' in unit: val *= 7
            rec['duration'] = val
            
    # 4. Clean Instructions - ALWAYS APPLY or Fallback to Reconstruction
    clean_instr = clean_text(instructions)
    rec['instructions'] = clean_instr
        
    # 5. Reconstruct Instruction if Empty/Bad but Data Exists
    # This rescues "Low Quality" records by creating a synthetic "High Quality" instruction
    if (not rec.get('instructions') or len(rec['instructions']) < 10) and (rec.get('route') or rec.get('frequency') or rec.get('min_dose')):
        parts = []
        if rec.get('min_dose'): parts.append(f"Take {rec['min_dose']}") # Unit often in min_dose string or missing, safely append
        elif rec.get('max_dose'): parts.append(f"Take up to {rec['max_dose']}")
        else: parts.append("Take")

        if rec.get('route'): parts.append(str(rec['route']))
        
        if rec.get('frequency'): 
            parts.append(f"every {rec['frequency']} hours")
        
        if len(parts) > 1:
            rec['instructions'] = " ".join(parts) + "."

    return rec


def main():
    print("🧹 Purifying dosage data...")
    try:
        with gzip.open(DOSAGE_JSON, 'rt', encoding='utf-8') as f:
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
    with gzip.open(DOSAGE_JSON, 'wt', encoding='utf-8') as f:
        json.dump(cleaned_data, f, ensure_ascii=False, separators=(',', ':'))
        
    return 0

if __name__ == '__main__':
    sys.exit(main())
