#!/usr/bin/env python3
"""
Enhanced Drug Interactions Extraction Script
Extracts all drug-drug interactions from drug-interactions.md
"""

import json
import re
from typing import List, Dict, Optional

def estimate_severity(text: str) -> str:
    """Estimate severity based on keywords"""
    text_lower = text.lower()
    
    if any(word in text_lower for word in ['contraindicated', 'life-threatening', 'do not use', 'avoid']):
        return 'contraindicated'
    elif any(word in text_lower for word in ['severe', 'serious', 'significant risk']):
        return 'severe'
    elif any(word in text_lower for word in ['major', 'significant', 'important']):
        return 'major'
    elif any(word in text_lower for word in ['moderate', 'caution', 'monitor', 'careful']):
        return 'moderate'
    elif any(word in text_lower for word in ['minor', 'may', 'potential', 'possible']):
        return 'minor'
    else:
        return 'moderate'  # Default to moderate for safety

def estimate_type(text: str) -> str:
    """Estimate interaction type"""
    text_lower = text.lower()
    
    if any(word in text_lower for word in ['absorption', 'metabolism', 'clearance', 'cyp', 'enzyme']):
        return 'pharmacokinetic'
    elif any(word in text_lower for word in ['effect', 'additive', 'synergistic', 'antagonistic']):
        return 'pharmacodynamic'
    else:
        return 'unknown'

def extract_drug_names(text: str) -> List[str]:
    """Extract drug/ingredient names from interaction text"""
    # Common drug name patterns
    drugs = []
    
    # Pattern 1: Capitalized words (likely drug names)
    capitalized = re.findall(r'\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)\b', text)
    drugs.extend([d for d in capitalized if len(d) > 3 and d not in ['The', 'This', 'When', 'If', 'During', 'Routine']])
    
    # Pattern 2: Common drug classes (lowercase)
    drug_classes = re.findall(r'\b(nsaids?|opioids?|antibiotics?|anticoagulants?|diuretics?|beta-blockers?|ace inhibitors?)\b', text.lower())
    drugs.extend(drug_classes)
    
    return list(set(drugs))[:5]  # Return up to 5 unique names

def parse_interaction_text(active_ingredient: str, interaction_text: str) -> List[Dict]:
    """Parse interaction text and extract structured data"""
    if not interaction_text or interaction_text.strip() == '':
        return []
    
    interactions = []
    
    # Split by common delimiters
    sections = re.split(r'\s*[|]\s*|\n{2,}', interaction_text)
    
    for section in sections:
        section = section.strip()
        if len(section) < 20:  # Skip very short sections
            continue
            
        # Check for structured format "Drug Name: Description"
        header_match = re.match(r'^([A-Z][^:]+):\s*(.+)$', section, re.DOTALL)
        
        if header_match:
            interacting_drug = header_match.group(1).strip()
            description = header_match.group(2).strip()
        else:
            # Extract potential drug names
            drug_names = extract_drug_names(section)
            interacting_drug = drug_names[0] if drug_names else None
            description = section
        
        # Split long descriptions into sentences
        sentences = re.split(r'(?<=[.!?])\s+', description)
        
        for sentence in sentences:
            sentence = sentence.strip()
            if len(sentence) < 15:  # Skip very short sentences
                continue
            
            interaction = {
                'ingredient1': active_ingredient.lower().strip(),
                'ingredient2': interacting_drug.lower().strip() if interacting_drug else 'unknown',
                'severity': estimate_severity(sentence),
                'type': estimate_type(sentence),
                'effect': sentence[:500],  # Limit length
                'arabic_effect': '',  # To be filled later
                'recommendation': '',  # Extract separately if needed
                'arabic_recommendation': ''
            }
            interactions.append(interaction)
    
    return interactions

def main():
    input_file = 'scripts/interactions/drug-interactions.md'
    output_file = 'scripts/interactions/drug_interactions_enhanced.json'
    
    print(f"Reading {input_file}...")
    
    all_interactions = []
    
    with open(input_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    # Skip header line
    for line_num, line in enumerate(lines[1:], start=2):
        line = line.strip()
        if not line:
            continue
        
        parts = line.split('\t')
        if len(parts) < 2:
            continue
        
        active_ingredient = parts[0].strip()
        interaction_text = '\t'.join(parts[1:]).strip()
        
        # Replace pipe separators with newlines for better parsing
        interaction_text = interaction_text.replace(' | ', '\n')
        
        if active_ingredient and interaction_text:
            interactions = parse_interaction_text(active_ingredient, interaction_text)
            all_interactions.extend(interactions)
            
            if line_num % 20 == 0:
                print(f"Processed {line_num} lines, extracted {len(all_interactions)} interactions so far...")
    
    # Remove duplicates based on ingredient pair and effect
    unique_interactions = []
    seen = set()
    
    for interaction in all_interactions:
        # Create a key for deduplication
        key = (
            interaction['ingredient1'],
            interaction['ingredient2'],
            interaction['effect'][:100]  # First 100 chars
        )
        
        if key not in seen:
            seen.add(key)
            unique_interactions.append(interaction)
    
    print(f"\nTotal interactions extracted: {len(all_interactions)}")
    print(f"Unique interactions: {len(unique_interactions)}")
    
    # Write to JSON
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(unique_interactions, f, indent=2, ensure_ascii=False)
    
    print(f"✅ Output written to {output_file}")
    
    # Also create a simple version for quick loading
    simple_output = 'assets/data/drug_interactions_full.json'
    with open(simple_output, 'w', encoding='utf-8') as f:
        json.dump(unique_interactions, f, indent=2, ensure_ascii=False)
    
    print(f"✅ Also saved to {simple_output}")

if __name__ == '__main__':
    main()
