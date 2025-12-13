#!/usr/bin/env python3
"""
DailyMed Dosage Data Extractor - Production Grade
استخراج بيانات الجرعات الطبية بدقة عالية (Structured Dosage Data)

Focus:
- Structured numeric values (mg/kg/day)
- Pediatric vs Adult distinction
- Renal/Hepatic adjustments
- Max dose limits
"""

import os
import zipfile
import json
import re
from xml.etree import ElementTree as ET
from typing import List, Dict, Set, Optional, Tuple

# Configuration
DAILYMED_DOWNLOAD_DIR = 'External_source/dailymed/downloaded'
OUTPUT_DIR = 'production_data'
OUTPUT_FILE = 'production_data/dosages_clean.json'

# LOINC Codes
LOINC_DOSAGE_ADMIN = '34068-7'     # Dosage and Administration
LOINC_PEDIATRIC = '34081-0'        # Pediatric Use
LOINC_GERIATRIC = '34082-8'        # Geriatric Use
LOINC_RENAL = '88821-5'            # Renal Impairment
LOINC_HEPATIC = '88822-3'          # Hepatic Impairment

# Known ingredients
KNOWN_INGREDIENTS_FILE = 'production_data/known_ingredients.json'

# Full Release files
DAILYMED_RELEASE_FILES = [
    'dm_spl_release_human_rx_part1.zip',
    'dm_spl_release_human_rx_part2.zip',
    'dm_spl_release_human_rx_part3.zip',
    'dm_spl_release_human_rx_part4.zip',
    'dm_spl_release_human_rx_part5.zip',
]

class DosageParser:
    """Parses text into structured dosage data"""
    
    def __init__(self):
        # Regex Patterns
        self.mg_kg_pattern = re.compile(r'(\d+(?:\.\d+)?)\s*(?:mg|mcg|g)/kg', re.IGNORECASE)
        self.frequency_map = {
            'once daily': 24, 'daily': 24, 'q24h': 24, 'every 24 hours': 24,
            'twice daily': 12, 'bid': 12, 'q12h': 12, 'every 12 hours': 12,
            'three times': 8, 'tid': 8, 'q8h': 8, 'every 8 hours': 8,
            'four times': 6, 'qid': 6, 'q6h': 6, 'every 6 hours': 6
        }
    
    def extract_structured_dose(self, text: str) -> Dict:
        """Attempt to extract structured numeric variables from text"""
        data = {
            'dose_mg_kg': None,
            'frequency_hours': None,
            'max_dose_mg': None,
            'is_pediatric': False
        }
        
        # 1. Mg/Kg (Pediatric indicator)
        match = self.mg_kg_pattern.search(text)
        if match:
            data['dose_mg_kg'] = float(match.group(1))
            data['is_pediatric'] = True
        
        # 2. Frequency
        text_lower = text.lower()
        for key, hours in self.frequency_map.items():
            if key in text_lower:
                data['frequency_hours'] = hours
                break
                
        # 3. Max Dose
        max_pattern = re.search(r'max(?:imum)?\s*(?:dose)?\s*(?:of)?\s*(\d+(?:\.\d+)?)\s*mg', text_lower)
        if max_pattern:
            data['max_dose_mg'] = float(max_pattern.group(1))
            
        return data

class DailyMedDosageExtractor:
    """Extracts dosage sections from DailyMed XML"""
    
    def __init__(self, known_ingredients: Set[str]):
        self.known_ingredients = known_ingredients
        self.namespaces = {'ns': 'urn:hl7-org:v3'}
        self.parser = DosageParser()
    
    def extract_from_xml(self, xml_data: bytes) -> List[Dict]:
        dosages = []
        try:
            root = ET.fromstring(xml_data)
            
            # Identify Drug
            drug_name = self._extract_drug_name(root)
            if not drug_name or drug_name not in self.known_ingredients:
                return []
            
            # Extract Sections
            sections = {
                'general': self._get_section_text(root, LOINC_DOSAGE_ADMIN),
                'pediatric': self._get_section_text(root, LOINC_PEDIATRIC),
                'geriatric': self._get_section_text(root, LOINC_GERIATRIC),
                'renal': self._get_section_text(root, LOINC_RENAL),
                'hepatic': self._get_section_text(root, LOINC_HEPATIC),
            }
            
            # If no dosage section, skip
            if not sections['general'] and not sections['pediatric']:
                return []
                
            # Process General Dosage
            if sections['general']:
                structured = self.parser.extract_structured_dose(sections['general'])
                dosages.append({
                    'drug_name': drug_name,
                    'group': 'General/Adult',
                    'raw_text': sections['general'][:2000], # Keep reasonably long text
                    'structured': structured,
                    'source': 'DailyMed'
                })
            
            # Process Pediatric
            if sections['pediatric']:
                structured = self.parser.extract_structured_dose(sections['pediatric'])
                structured['is_pediatric'] = True
                dosages.append({
                    'drug_name': drug_name,
                    'group': 'Pediatric',
                    'raw_text': sections['pediatric'][:2000],
                    'structured': structured,
                    'source': 'DailyMed'
                })
                
            # Process Renal/Hepatic (Adjusments)
            for type_ in ['renal', 'hepatic']:
                if sections[type_]:
                     dosages.append({
                        'drug_name': drug_name,
                        'group': f'{type_.capitalize()} Impairment',
                        'raw_text': sections[type_][:1500],
                        'structured': {},
                        'source': 'DailyMed'
                    })

        except Exception as e:
            pass
            
        return dosages
    
    def _extract_drug_name(self, root: ET.Element) -> Optional[str]:
        # Same logic as interactions extractor
        generic_elem = root.find(".//ns:genericMedicine/ns:name", self.namespaces)
        if generic_elem is not None and generic_elem.text:
            return generic_elem.text.strip().lower()
            
        ingredient_elem = root.find(".//ns:ingredientSubstance/ns:name", self.namespaces)
        if ingredient_elem is not None and ingredient_elem.text:
            return ingredient_elem.text.strip().lower()

        return None

    def _get_section_text(self, root: ET.Element, code: str) -> Optional[str]:
        """Find section by code and return clean text"""
        for section in root.findall(".//ns:section", self.namespaces):
            code_elem = section.find("ns:code", self.namespaces)
            if code_elem is not None and code_elem.get('code') == code:
                text = ''.join(section.itertext())
                return re.sub(r'\s+', ' ', text).strip()
        return None

def load_known_ingredients() -> Set[str]:
    try:
        with open(KNOWN_INGREDIENTS_FILE, 'r') as f:
            data = json.load(f)
            return set(data.get('ingredients', []))
    except:
        return set()

def process_release_zip(release_zip_path: str, extractor: DailyMedDosageExtractor) -> List[Dict]:
    all_dosages = []
    
    if not os.path.exists(release_zip_path):
        print(f"⚠️  File not found: {release_zip_path}")
        return []
        
    try:
        with zipfile.ZipFile(release_zip_path, 'r') as main_zip:
            nested_zips = [f for f in main_zip.namelist() if f.endswith('.zip')]
            total = len(nested_zips)
            print(f"  Found {total:,} drug files")
            
            for i, nested_zip_name in enumerate(nested_zips):
                try:
                    nested_zip_data = main_zip.read(nested_zip_name)
                    import io
                    with zipfile.ZipFile(io.BytesIO(nested_zip_data)) as drug_zip:
                        xml_files = [f for f in drug_zip.namelist() if f.endswith('.xml')]
                        if xml_files:
                            xml_data = drug_zip.read(xml_files[0])
                            dosages = extractor.extract_from_xml(xml_data)
                            if dosages:
                                all_dosages.extend(dosages)
                except:
                    continue
                    
                if (i + 1) % 5000 == 0:
                    print(f"    Processed {i+1:,}/{total:,} drugs ({len(all_dosages):,} records)")
                    
    except Exception as e:
        print(f"❌ Error: {e}")
        
    return all_dosages

def main():
    print("="*80)
    print("DailyMed Dosage Data Extractor - Production Grade")
    print("="*80)
    
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    known = load_known_ingredients()
    print(f"📚 Targeting {len(known)} known ingredients")
    
    extractor = DailyMedDosageExtractor(known)
    all_results = []
    
    for part in DAILYMED_RELEASE_FILES:
        path = os.path.join(DAILYMED_DOWNLOAD_DIR, part)
        if os.path.exists(path):
            print(f"\n📦 Processing {part}...")
            results = process_release_zip(path, extractor)
            all_results.extend(results)
            
    print(f"\nTotal dosage records extracted: {len(all_results):,}")
    
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(all_results, f, indent=2, ensure_ascii=False)
        
    print(f"Saved to {OUTPUT_FILE}")

if __name__ == '__main__':
    main()
