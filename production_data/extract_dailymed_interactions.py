#!/usr/bin/env python3
"""
DailyMed Drug Interactions Extractor - Production Grade
استخراج التفاعلات الدوائية من DailyMed SPL files

Focus: Real drug names, proper formatting, quality validation
Source: LOINC 34073-7 (DRUG INTERACTIONS section)
"""

import os
import zipfile
import json
import re
from xml.etree import ElementTree as ET
from typing import List, Dict, Set, Optional, Tuple
from collections import Counter

# Configuration
DAILYMED_DOWNLOAD_DIR = 'External_source/dailymed/downloaded'
OUTPUT_DIR = 'production_data'
OUTPUT_FILE = 'production_data/dailymed_interactions_clean.json'

# LOINC code for Drug Interactions section
LOINC_DRUG_INTERACTIONS = '34073-7'

# Known ingredients for validation
KNOWN_INGREDIENTS_FILE = 'production_data/known_ingredients.json'

# Full Release file names
DAILYMED_RELEASE_FILES = [
    'dm_spl_release_human_rx_part1.zip',
    'dm_spl_release_human_rx_part2.zip',
    'dm_spl_release_human_rx_part3.zip',
    'dm_spl_release_human_rx_part4.zip',
    'dm_spl_release_human_rx_part5.zip',
]


def load_known_ingredients() -> Set[str]:
    """Load pharmaceutical ingredients database"""
    try:
        with open(KNOWN_INGREDIENTS_FILE, 'r') as f:
            data = json.load(f)
            return set([ing.lower() for ing in data.get('ingredients', [])])
    except:
        return set()


class DailyMedInteractionExtractor:
    """Extract structured drug interactions from DailyMed XML"""
    
    def __init__(self, known_ingredients: Set[str]):
        self.known_ingredients = known_ingredients
        self.namespaces = {'ns': 'urn:hl7-org:v3'}
    
    def extract_from_xml(self, xml_data: bytes) -> List[Dict]:
        """Extract interactions from XML data"""
        interactions = []
        
        try:
            root = ET.fromstring(xml_data)
            
            # Get primary drug name
            primary_drug = self._extract_drug_name(root)
            if not primary_drug:
                return []
            
            # Find Drug Interactions section (LOINC 34073-7)
            interaction_sections = self._find_sections_by_code(root, LOINC_DRUG_INTERACTIONS)
            
            if not interaction_sections:
                return []
            
            # Process each interactions section
            for section in interaction_sections:
                section_interactions = self._parse_interaction_section(
                    section, 
                    primary_drug
                )
                interactions.extend(section_interactions)
        
        except Exception as e:
            # Skip problematic files silently
            pass
        
        return interactions
    
    def _extract_drug_name(self, root: ET.Element) -> Optional[str]:
        """Extract primary drug name from SPL"""
        # Try generic name first
        generic_elem = root.find(".//ns:genericMedicine/ns:name", self.namespaces)
        if generic_elem is not None and generic_elem.text:
            return generic_elem.text.strip().lower()
        
        # Try active ingredient
        ingredient_elem = root.find(".//ns:ingredientSubstance/ns:name", self.namespaces)
        if ingredient_elem is not None and ingredient_elem.text:
            return ingredient_elem.text.strip().lower()
        
        # Try brand name as last resort
        brand_elem = root.find(".//ns:name", self.namespaces)
        if brand_elem is not None:
            text = ''.join(brand_elem.itertext()).strip()
            if text:
                return text.lower()
        
        return None
    
    def _find_sections_by_code(self, root: ET.Element, code: str) -> List[ET.Element]:
        """Find all sections with specific LOINC code"""
        sections = []
        
        for section in root.findall(".//ns:section", self.namespaces):
            code_elem = section.find("ns:code", self.namespaces)
            if code_elem is not None and code_elem.get('code') == code:
                sections.append(section)
        
        return sections
    
    def _parse_interaction_section(self, section: ET.Element, primary_drug: str) -> List[Dict]:
        """Parse Drug Interactions section"""
        interactions = []
        
        # Get all text from section
        full_text = ''.join(section.itertext())
        full_text = re.sub(r'\s+', ' ', full_text).strip()
        
        if len(full_text) < 30:
            return []
        
        # Split into logical parts (by paragraph or by drug mention)
        # Strategy 1: Look for explicit drug mentions
        drug_mentions = self._find_drug_mentions(full_text)
        
        if drug_mentions:
            # Create interactions for each mentioned drug
            for secondary_drug in drug_mentions:
                # Extract relevant text about this specific interaction
                interaction_text = self._extract_interaction_text(
                    full_text, 
                    primary_drug, 
                    secondary_drug
                )
                
                if interaction_text:
                    interaction = self._create_interaction_record(
                        primary_drug,
                        secondary_drug,
                        interaction_text
                    )
                    
                    if interaction:
                        interactions.append(interaction)
        else:
            # No specific drug mentioned - general interaction warning
            # Still useful but lower priority
            interaction = self._create_interaction_record(
                primary_drug,
                "drug_class",  # placeholder
                full_text
            )
            if interaction:
                interactions.append(interaction)
        
        return interactions
    
    def _find_drug_mentions(self, text: str) -> List[str]:
        """Find mentioned drugs in text"""
        mentioned_drugs = []
        text_lower = text.lower()
        
        # Look for known ingredients
        for ingredient in self.known_ingredients:
            if ingredient in text_lower:
                mentioned_drugs.append(ingredient)
        
        # Look for drug patterns (e.g., "Drug X", capitalized drug names)
        drug_patterns = [
            r'\b([A-Z][a-z]+(?:ine|cin|pril|olol|statin|mycin|cillin|zole|azole|mab))\b',
            r'\b(insulin|lithium|digoxin|warfarin|aspirin)\b',
        ]
        
        for pattern in drug_patterns:
            matches = re.findall(pattern, text, re.IGNORECASE)
            for match in matches:
                drug = match.lower()
                if drug in self.known_ingredients and drug not in mentioned_drugs:
                    mentioned_drugs.append(drug)
        
        return mentioned_drugs
    
    def _extract_interaction_text(self, full_text: str, drug1: str, drug2: str) -> Optional[str]:
        """Extract text relevant to specific drug pair"""
        # Find sentences mentioning drug2
        sentences = re.split(r'(?<=[.!?])\s+', full_text)
        
        relevant_sentences = []
        drug2_lower = drug2.lower()
        
        for sentence in sentences:
            if drug2_lower in sentence.lower():
                relevant_sentences.append(sentence.strip())
        
        if relevant_sentences:
            # Join up to 3 sentences
            text = ' '.join(relevant_sentences[:3])
            return self._clean_text(text)
        
        # Fallback: use first paragraph if it's not too long
        if len(full_text) < 500:
            return self._clean_text(full_text)
        
        return None
    
    def _clean_text(self, text: str) -> str:
        """Clean and format text"""
        if not text:
            return ""
        
        # Remove excessive whitespace
        text = re.sub(r'\s+', ' ', text)
        
        # Remove special formatting artifacts
        text = re.sub(r'\s+([.,;:])', r'\1', text)
        
        # Capitalize first letter
        text = text.strip()
        if text:
            text = text[0].upper() + text[1:]
        
        return text
    
    def _create_interaction_record(self, drug1: str, drug2: str, text: str) -> Optional[Dict]:
        """Create validated interaction record"""
        # Classify severity
        severity, confidence = self._classify_severity(text)
        
        # Extract recommendation
        recommendation = self._extract_recommendation(text)
        
        # Validate
        if len(text) < 30:
            return None
        
        if drug2 in ['other', 'multiple', 'various', 'unknown']:
            return None
        
        return {
            'ingredient1': drug1,
            'ingredient2': drug2,
            'severity': severity,
            'severity_confidence': round(confidence, 2),
            'effect': text[:800],  # Limit length
            'recommendation': recommendation or '',
            'source': 'DailyMed',
            'confidence_score': round(confidence * 0.9, 2)  # Slightly lower for DailyMed
        }
    
    def _classify_severity(self, text: str) -> Tuple[str, float]:
        """Classify interaction severity"""
        text_lower = text.lower()
        
        # Contraindicated
        if any(w in text_lower for w in ['contraindicated', 'do not use', 'must not', 'fatal']):
            return 'contraindicated', 1.0
        
        # Severe
        if any(w in text_lower for w in ['severe', 'serious', 'life-threatening', 'dangerous']):
            return 'severe', 0.9
        
        # Major
        if any(w in text_lower for w in ['major', 'significant', 'important']):
            return 'major', 0.7
        
        # Moderate
        if any(w in text_lower for w in ['moderate', 'caution', 'monitor', 'careful']):
            return 'moderate', 0.5
        
        # Minor (default)
        return 'minor', 0.3
    
    def _extract_recommendation(self, text: str) -> Optional[str]:
        """Extract recommendation from text"""
        patterns = [
            r'((?:avoid|do not|should not|must not)[^.!?]*[.!?])',
            r'((?:recommended|advised|suggested)[^.!?]*[.!?])',
            r'((?:monitor|adjust|reduce|increase)[^.!?]*[.!?])',
        ]
        
        for pattern in patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                rec = match.group(1).strip()
                return rec[0].upper() + rec[1:] if rec else None
        
        return None


def process_drug_zip(zip_path: str, extractor: DailyMedInteractionExtractor) -> List[Dict]:
    """Process single drug ZIP file"""
    try:
        with zipfile.ZipFile(zip_path, 'r') as z:
            xml_files = [f for f in z.namelist() if f.endswith('.xml')]
            if not xml_files:
                return []
            
            xml_data = z.read(xml_files[0])
            return extractor.extract_from_xml(xml_data)
    except:
        return []


def process_release_zip(release_zip_path: str, extractor: DailyMedInteractionExtractor) -> List[Dict]:
    """Process a DailyMed Full Release ZIP (contains nested drug ZIPs)"""
    all_interactions = []
    drugs_processed = 0
    
    if not os.path.exists(release_zip_path):
        print(f"⚠️  File not found: {release_zip_path}")
        return []
    
    try:
        with zipfile.ZipFile(release_zip_path, 'r') as main_zip:
            # Get list of nested ZIPs (drug files)
            nested_zips = [f for f in main_zip.namelist() if f.endswith('.zip')]
            total = len(nested_zips)
            
            print(f"  Found {total:,} drug files")
            
            for i, nested_zip_name in enumerate(nested_zips):
                try:
                    # Read nested ZIP
                    nested_zip_data = main_zip.read(nested_zip_name)
                    
                    # Process nested ZIP
                    import io
                    with zipfile.ZipFile(io.BytesIO(nested_zip_data)) as drug_zip:
                        xml_files = [f for f in drug_zip.namelist() if f.endswith('.xml')]
                        if xml_files:
                            xml_data = drug_zip.read(xml_files[0])
                            interactions = extractor.extract_from_xml(xml_data)
                            if interactions:
                                all_interactions.extend(interactions)
                    
                    drugs_processed += 1
                    
                    if (i + 1) % 1000 == 0:
                        print(f"    Processed {i+1:,}/{total:,} drugs ({len(all_interactions):,} interactions)")
                
                except Exception as e:
                    # Skip problematic files
                    continue
    
    except Exception as e:
        print(f"❌ Error processing {os.path.basename(release_zip_path)}: {e}")
    
    return all_interactions


def main():
    """Main extraction process"""
    print("="*80)
    print("DailyMed Drug Interactions Extractor - Production Grade")
    print("Full Release Processing (All Human Rx)")
    print("="*80)
    
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    # Load known ingredients
    known_ingredients = load_known_ingredients()
    print(f"\n📚 Loaded {len(known_ingredients):,} known ingredients")
    
    # Initialize extractor
    extractor = DailyMedInteractionExtractor(known_ingredients)
    
    # Process each Full Release part
    all_interactions = []
    
    for part_filename in DAILYMED_RELEASE_FILES:
        release_path = os.path.join(DAILYMED_DOWNLOAD_DIR, part_filename)
        
        if not os.path.exists(release_path):
            print(f"\n⚠️  {part_filename} not found, skipping...")
            continue
        
        print(f"\n📦 Processing {part_filename}...")
        file_size_gb = os.path.getsize(release_path) / (1024 ** 3)
        print(f"  Size: {file_size_gb:.2f} GB")
        
        interactions = process_release_zip(release_path, extractor)
        all_interactions.extend(interactions)
        
        print(f"  ✅ Extracted {len(interactions):,} interactions from this part")
    
    # Deduplicate
    unique_interactions = {}
    for interaction in all_interactions:
        key = (
            interaction['ingredient1'],
            interaction['ingredient2'],
            interaction['severity']
        )
        
        if key not in unique_interactions:
            unique_interactions[key] = interaction
        else:
            # Keep higher confidence
            if interaction['confidence_score'] > unique_interactions[key]['confidence_score']:
                unique_interactions[key] = interaction
    
    final_interactions = list(unique_interactions.values())
    
    # Save
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(final_interactions, f, indent=2, ensure_ascii=False)
    
    # Summary
    print("\n" + "="*80)
    print("📊 FINAL SUMMARY")
    print("="*80)
    print(f"Total files processed: {total_files}")
    print(f"Files with interactions: {files_with_interactions}")
    print(f"Total interactions extracted: {len(all_interactions):,}")
    print(f"Unique interactions: {len(final_interactions):,}")
    print(f"\nOutput: {OUTPUT_FILE}")
    
    if final_interactions:
        print(f"Size: {os.path.getsize(OUTPUT_FILE) / 1024:.1f} KB")
        
        # Show severity distribution
        severity_counts = Counter(i['severity'] for i in final_interactions)
        print(f"\nSeverity Distribution:")
        for severity, count in severity_counts.most_common():
            print(f"  {severity}: {count} ({count/len(final_interactions)*100:.1f}%)")
        
        # Sample
        print(f"\n📋 Sample interactions:")
        for i, interaction in enumerate(final_interactions[:5], 1):
            print(f"\n{i}. {interaction['ingredient1'].title()} + {interaction['ingredient2'].title()}")
            print(f"   Severity: {interaction['severity'].upper()}")
            print(f"   Effect: {interaction['effect'][:120]}...")
            if interaction['recommendation']:
                print(f"   Recommendation: {interaction['recommendation'][:100]}...")
    
    print("\n✅ DailyMed extraction complete!")


if __name__ == '__main__':
    main()
