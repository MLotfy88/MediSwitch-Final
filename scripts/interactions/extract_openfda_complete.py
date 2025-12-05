#!/usr/bin/env python3
"""
Complete OpenFDA Drug Interactions Extractor
Extracts ALL drug-drug interactions from all 13 OpenFDA JSON files
"""

import json
import os
import glob
from typing import List, Dict
import re

def clean_text(text):
    """Clean and normalize text"""
    if not text:
        return ""
    # Remove extra whitespace
    text = re.sub(r'\s+', ' ', text)
    return text.strip()

def estimate_severity(text: str) -> str:
    """Estimate interaction severity"""
    text_lower = text.lower()
    if any(w in text_lower for w in ['contraindicated', 'do not use', 'life-threatening']):
        return 'contraindicated'
    elif any(w in text_lower for w in ['severe', 'serious']):
        return 'severe'
    elif any(w in text_lower for w in ['major', 'significant']):
        return 'major'
    elif any(w in text_lower for w in ['moderate', 'caution', 'monitor']):
        return 'moderate'
    else:
        return 'minor'

def extract_interactions_from_file(file_path: str) -> List[Dict]:
    """Extract all drug interactions from a single OpenFDA JSON file"""
    interactions = []
    
    print(f"\nProcessing: {os.path.basename(file_path)}")
    
    try:
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            data = json.load(f)
        
        results = data.get('results', [])
        print(f"  Found {len(results)} drug records")
        
        for idx, record in enumerate(results):
            # Get drug name
            openfda = record.get('openfda', {})
            brand_names = openfda.get('brand_name', [])
            generic_names = openfda.get('generic_name', [])
            
            drug_name = None
            if brand_names:
                drug_name = brand_names[0]
            elif generic_names:
                drug_name = generic_names[0]
            
            if not drug_name:
                continue
            
            # Look for drug_interactions in various fields
            interaction_texts = []
            
            # Check direct field
            if 'drug_interactions' in record:
                interaction_texts.extend(record['drug_interactions'])
            
            # Check within other sections
            for section_key in ['warnings', 'precautions', 'drug_and_or_laboratory_test_interactions']:
                if section_key in record:
                    sections = record[section_key]
                    if isinstance(sections, list):
                        for section in sections:
                            if isinstance(section, str) and 'interaction' in section.lower():
                                interaction_texts.append(section)
            
            # Process each interaction text
            for interaction_text in interaction_texts:
                if not interaction_text or len(interaction_text) < 20:
                    continue
                
                # Split into paragraphs/sentences
                paragraphs = re.split(r'\n\n+', clean_text(interaction_text))
                
                for para in paragraphs:
                    if len(para) < 30:
                        continue
                    
                    interaction = {
                        'ingredient1': drug_name.lower().strip(),
                        'ingredient2': 'multiple',  # Will be refined if specific drug mentioned
                        'severity': estimate_severity(para),
                        'type': 'pharmacodynamic' if 'effect' in para.lower() else 'pharmacokinetic',
                        'effect': para[:800],  # Limit length
                        'arabic_effect': '',
                        'recommendation': '',
                        'arabic_recommendation': '',
                        'source': 'OpenFDA'
                    }
                    interactions.append(interaction)
            
            if (idx + 1) % 1000 == 0:
                print(f"  Processed {idx + 1}/{len(results)} records, extracted {len(interactions)} interactions so far...")
        
        print(f"  ✅ Total from this file: {len(interactions)} interactions")
        
    except Exception as e:
        print(f"  ❌ Error processing file: {e}")
    
    return interactions

def main():
    data_dir = 'External_source/drug_interaction/drug-label/data-from-source'
    output_file = 'assets/data/drug_interactions_complete.json'
    
    # Find all OpenFDA JSON files
    json_files = sorted(glob.glob(os.path.join(data_dir, 'drug-label-*.json')))
    
    print(f"Found {len(json_files)} OpenFDA files to process")
    print("=" * 60)
    
    all_interactions = []
    
    for file_path in json_files:
        file_interactions = extract_interactions_from_file(file_path)
        all_interactions.extend(file_interactions)
    
    print("\n" + "=" * 60)
    print(f"Total interactions extracted: {len(all_interactions):,}")
    
    # Remove duplicates
    unique_interactions = []
    seen = set()
    
    for interaction in all_interactions:
        key = (
            interaction['ingredient1'],
            interaction['effect'][:100]
        )
        if key not in seen:
            seen.add(key)
            unique_interactions.append(interaction)
    
    print(f"Unique interactions: {len(unique_interactions):,}")
    
    # Save to JSON
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(unique_interactions, f, indent=2, ensure_ascii=False)
    
    print(f"\n✅ Complete dataset saved to: {output_file}")
    print(f"   File size: {os.path.getsize(output_file) / 1024 / 1024:.1f} MB")

if __name__ == '__main__':
    main()
