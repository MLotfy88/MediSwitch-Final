#!/usr/bin/env python3
"""
OpenFDA Dosage Guidelines Extractor - OPTIMIZED VERSION
استخراج محسّن لبيانات الجرعات من OpenFDA

التحسينات الرئيسية:
1. استخدام brand_name كبديل للـ substance_name
2. استخراج ذكي للمعرّفات من SPL elements
3. معايير قبول أوسع للسجلات
4. أنماط regex محسّنة لاستخراج الجرعات
"""

import json
import os
import zipfile
import re
import sys
from typing import List, Dict, Optional

# Configuration
DOWNLOAD_DIR = 'External_source/drug_interaction/drug-label/downloaded'
OUTPUT_FILE = 'assets/data/dosage_guidelines.json'

def extract_identifier_from_spl(spl_text: str) -> Optional[str]:
    """
    استخراج اسم الدواء من SPL elements
    مثال: "Acetaminophen 500 mg Tablet" -> "Acetaminophen"
    """
    if not spl_text:
        return None
    
    # Clean up the text
    text = spl_text.strip()
    
    # First word before numbers/dosage info is usually the drug name
    # Pattern: Word(s) before number+unit
    match = re.search(r'^([A-Za-z\s]+?)(?:\s+\d+|\s+ALCOHOL|\s+WATER|$)', text)
    if match:
        name = match.group(1).strip()
        # Filter out common non-drug words
        excluded = ['TABLET', 'CAPSULE', 'LIQUID', 'SOLUTION', 'SUSPENSION', 
                   'CREAM', 'OINTMENT', 'GEL', 'LOTION', 'SPRAY']
        if name.upper() not in excluded and len(name) > 2:
            return name
    
    return None

def extract_strength(text: str) -> Optional[str]:
    """
    استخراج التركيز من النص
    محسّن لالتقاط أنماط متعددة
    """
    if not text:
        return None
    
    text = text.lower().strip()
    
    # Clean up common noise
    text = text.replace('equivalent to', '')
    
    # Comprehensive pattern for strength
    # Matches: 500mg, 500 mg, 10mg/ml, 0.5%, etc.
    pattern = r'\b(\d+(?:\.\d+)?)\s*(mg|mcg|g|ml|%|meq|units?|iu)(?:\s*/\s*(\d+(?:\.\d+)?)\s*(mg|mcg|ml|g))?\b'
    match = re.search(pattern, text)
    
    if match:
        # Construct strength string
        value1 = match.group(1)
        unit1 = match.group(2)
        
        # Check for ratio (e.g., 5mg/ml)
        if match.group(3):
            value2 = match.group(3)
            unit2 = match.group(4)
            return f"{value1}{unit1}/{value2}{unit2}"
        else:
            return f"{value1}{unit1}"
    
    return None

def extract_dosage_info(dosage_text: str) -> tuple:
    """
    استخراج الجرعة القياسية والقصوى من النص
    محسّن بأنماط أكثر شمولاً
    """
    standard_dose = ""
    max_dose = ""
    
    if not dosage_text:
        return standard_dose, max_dose
        
    text_lower = dosage_text.lower()
    
    # === Max Dose Patterns ===
    max_patterns = [
        # "maximum 4000 mg", "maximum dose 400mg"
        r'max(?:imum)?\s*(?:daily)?\s*(?:dose)?\s*(?:is|of)?\s*:?\s*(\d+(?:\.\d+)?)\s*(mg|mcg|g|tablet|capsule)s?',
        # "not more than 6 tablets"
        r'not\s*(?:to)?\s*(?:take|use|exceed)?\s*more\s*than\s*(\d+(?:\.\d+)?)\s*(mg|mcg|g|tablet|capsule|dose)s?',
        # "do not exceed 3000 mg"
        r'do\s*not\s*exceed\s*(\d+(?:\.\d+)?)\s*(mg|mcg|g|tablet|capsule)s?',
        # "up to 400 mg", "no more than 8 tablets"
        r'(?:up|no\s*more)\s*(?:to|than)\s*(\d+(?:\.\d+)?)\s*(mg|mcg|g|tablet|capsule|dose)s?',
    ]
    
    for pattern in max_patterns:
        match = re.search(pattern, text_lower)
        if match:
            max_dose = f"{match.group(1)} {match.group(2)}"
            break
    
    # === Standard Dose Patterns ===
    standard_patterns = [
        # "recommended dose is 50 mg", "usual dose 100mg"
        r'(?:recommended|usual|starting|initial)\s+(?:adult|pediatric)?\s*dose\s*(?:is|of)?\s*:?\s*(\d+(?:\.\d+)?)\s*(mg|mcg|g|ml|tablet|capsule)s?',
        # "take 1 tablet", "take 2 capsules"
        r'take\s*(\d+(?:\.\d+)?)\s*(tablet|capsule|pill|caplet)s?',
        # "1 to 2 tablets every", "2-4 capsules daily"
        r'(\d+)\s*(?:to|-)\s*(\d+)\s*(tablet|capsule|pill|caplet)s?\s*(?:every|daily|per\s*day)',
        # "50 mg every 6 hours", "100mg once daily", "20mg twice daily"
        r'(\d+(?:\.\d+)?)\s*(mg|mcg|g|ml)\s+(?:every|once|twice|three\s*times|q\d+h?|daily)',
        # "dose: 250 mg", "dosage: 10mg"
        r'dose(?:age)?:\s*(\d+(?:\.\d+)?)\s*(mg|mcg|g|ml|tablet|capsule)s?',
        # "apply 2 times", "use 3 times daily"
        r'(?:apply|use)\s*(?:.*?)?\s*(\d+)\s*times?\s*(?:daily|per\s*day)?',
        # "one 500mg tablet"
        r'(?:one|two|three)\s+(\d+)\s*(mg|mcg)\s+(?:tablet|capsule)',
    ]
    
    for pattern in standard_patterns:
        match = re.search(pattern, text_lower)
        if match:
            if len(match.groups()) >= 2:
                if match.group(2):  # Has unit
                    standard_dose = f"{match.group(1)} {match.group(2)}"
                else:
                    standard_dose = match.group(1)
            else:
                standard_dose = match.group(0)
            break
    
    # Fallback: frequency-based "3 times daily"
    if not standard_dose:
        freq_match = re.search(r'(\d+)\s*times\s*(?:daily|per\s*day|a\s*day)', text_lower)
        if freq_match:
            standard_dose = f"{freq_match.group(1)} times daily"
    
    return standard_dose, max_dose

def process_file(zip_path: str) -> List[Dict]:
    """معالجة ملف ZIP واستخراج بيانات الجرعات"""
    file_guidelines = []
    
    if not os.path.exists(zip_path):
        return []

    print(f"Processing: {os.path.basename(zip_path)}")
    
    try:
        with zipfile.ZipFile(zip_path, 'r') as z:
            json_files = [f for f in z.namelist() if f.endswith('.json')]
            if not json_files:
                return []
            
            with z.open(json_files[0]) as f:
                data = json.load(f)
                results = data.get('results', [])
                
                for record in results:
                    openfda = record.get('openfda', {})
                    
                    # === 1. Identify Active Ingredient (OPTIMIZED) ===
                    # Priority: substance_name → generic_name → brand_name → extract from SPL
                    substances = openfda.get('substance_name', [])
                    generics = openfda.get('generic_name', [])
                    brands = openfda.get('brand_name', [])
                    
                    active_ingredient = None
                    
                    if substances:
                        active_ingredient = substances[0]
                    elif generics:
                        active_ingredient = generics[0]
                    elif brands:
                        # NEW: Use brand name as identifier
                        active_ingredient = brands[0]
                    else:
                        # NEW: Try to extract from SPL
                        spl_elements = record.get('spl_product_data_elements', [])
                        if spl_elements:
                            active_ingredient = extract_identifier_from_spl(spl_elements[0])
                    
                    # Skip if no identifier found
                    if not active_ingredient:
                        continue
                    
                    active_ingredient = active_ingredient.lower().strip()
                    
                    # === 2. Extract Strength (OPTIMIZED) ===
                    strength = None
                    
                    # Try SPL elements first
                    spl_elements = record.get('spl_product_data_elements', [])
                    if spl_elements:
                        strength = extract_strength(spl_elements[0])
                    
                    # Try dosage_forms_and_strengths
                    if not strength:
                        dfs = record.get('dosage_forms_and_strengths', [])
                        if dfs:
                            strength = extract_strength(dfs[0])
                    
                    # Try to extract from active ingredient itself
                    if not strength and active_ingredient:
                        strength = extract_strength(active_ingredient)
                    
                    # Default to "general" if no strength found
                    if not strength:
                        strength = "general"
                    
                    # === 3. Extract Dosage Info (OPTIMIZED) ===
                    dosage_text_list = record.get('dosage_and_administration', [])
                    dosage_text = dosage_text_list[0] if dosage_text_list else ""
                    
                    standard_dose, max_dose = extract_dosage_info(dosage_text)
                    
                    # === 4. Extract Instructions ===
                    # Try multiple sources for instructions
                    instructions_list = (record.get('instructions_for_use', []) or 
                                       record.get('patient_medication_information', []))
                    package_label = instructions_list[0] if instructions_list else ""
                    
                    # Fallback to dosage text snippet
                    if not package_label and dosage_text:
                        package_label = dosage_text.replace('\n', ' ')
                    
                    package_label = package_label.strip()
                    
                    # === 5. Relaxed Inclusion Criteria ===
                    # Accept if:
                    # - Has standard_dose OR max_dose, OR
                    # - Has good strength (not "general") AND package_label, OR  
                    # - Has dosage_text longer than 100 chars
                    
                    has_meaningful_dose = bool(standard_dose or max_dose)
                    has_good_metadata = (strength != "general" and len(package_label) > 50)
                    has_substantial_text = len(dosage_text) > 100
                    
                    if not (has_meaningful_dose or has_good_metadata or has_substantial_text):
                        continue
                    
                    # === 6. Create Guideline Record ===
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
    """Main extraction process"""
    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
    
    all_guidelines = {}  # Dedup by (active, strength)
    
    # Process all ZIP files
    if not os.path.exists(DOWNLOAD_DIR):
        print(f"Error: Download directory {DOWNLOAD_DIR} does not exist.")
        return
    
    files = sorted([f for f in os.listdir(DOWNLOAD_DIR) if f.endswith('.zip')])
    
    print(f"Found {len(files)} ZIP files to process\n")
    
    for filename in files:
        path = os.path.join(DOWNLOAD_DIR, filename)
        guidelines = process_file(path)
        
        for g in guidelines:
            key = (g['active_ingredient'], g['strength'])
            
            # Dedup: prefer records with more content
            if key in all_guidelines:
                existing = all_guidelines[key]
                
                # Score based on content completeness
                score_existing = (
                    (1 if existing['standard_dose'] else 0) +
                    (1 if existing['max_dose'] else 0) +
                    (1 if existing['package_label'] and len(existing['package_label']) > 100 else 0)
                )
                score_new = (
                    (1 if g['standard_dose'] else 0) +
                    (1 if g['max_dose'] else 0) +
                    (1 if g['package_label'] and len(g['package_label']) > 100 else 0)
                )
                
                if score_new > score_existing:
                    all_guidelines[key] = g
            else:
                all_guidelines[key] = g
        
        print(f"  Aggregated {len(all_guidelines):,} unique guidelines so far...")
    
    # Convert to list
    final_list = list(all_guidelines.values())
    
    print(f"\n{'='*80}")
    print(f"✅ EXTRACTION COMPLETE!")
    print(f"{'='*80}")
    print(f"Total unique dosage guidelines extracted: {len(final_list):,}")
    
    # Statistics
    with_standard = sum(1 for g in final_list if g['standard_dose'])
    with_max = sum(1 for g in final_list if g['max_dose'])
    with_label = sum(1 for g in final_list if g['package_label'])
    
    print(f"\nBreakdown:")
    print(f"  • With standard_dose: {with_standard:,} ({with_standard/len(final_list)*100:.1f}%)")
    print(f"  • With max_dose: {with_max:,} ({with_max/len(final_list)*100:.1f}%)")
    print(f"  • With package_label: {with_label:,} ({with_label/len(final_list)*100:.1f}%)")
    
    # Save to JSON
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(final_list, f, indent=2)
    
    print(f"\n💾 Saved to: {OUTPUT_FILE}")
    print(f"{'='*80}\n")

if __name__ == "__main__":
    main()
