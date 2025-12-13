#!/usr/bin/env python3
"""
DailyMed Full Database Extractor (Data Lake)
Extracts ALL clinical and product data for downstream filtering.
"""

import os
import zipfile
import json
import re
import sys
from xml.etree import ElementTree as ET
from typing import List, Dict, Set, Optional, Any

# Configuration
DAILYMED_DOWNLOAD_DIR = 'External_source/dailymed/downloaded'
OUTPUT_DIR = 'production_data'
OUTPUT_FILE = 'production_data/dailymed_full_database.json'

# User's Concentration Regex (from scraper.py)
CONCENTRATION_REGEX = re.compile(
    r"""
    (                          # Start capturing group 1
        \d+ (?:[.,]\d+)?       # Match number (integer or decimal with . or ,)
        \s*                    # Optional whitespace
        (?:mg|mcg|g|kg|ml|l|iu|%) # Match common units (case-insensitive)
        (?:                    # Optional second part for compound units (e.g., /ml)
            \s* / \s*          # Match '/' surrounded by optional spaces
            (?:ml|mg|g|kg|l)   # Match second unit (case-insensitive)
        )?
    )                          # End capturing group 1
    """,
    re.IGNORECASE | re.VERBOSE
)

# Target LOINC Sections
SECTIONS_MAP = {
    '34066-1': 'boxed_warning',
    '34067-9': 'indications',
    '34068-7': 'dosage_and_administration',
    '34081-0': 'pediatric_use',
    '34082-8': 'geriatric_use',
    '42228-7': 'pregnancy',
    '77290-5': 'lactation',
    '88821-5': 'renal_impairment',
    '88822-3': 'hepatic_impairment',
    '34070-3': 'contraindications',
    '34071-1': 'warnings_and_precautions',
    '34084-4': 'adverse_reactions',
    '34073-7': 'drug_interactions',
    '34069-5': 'how_supplied',
}

DAILYMED_RELEASE_FILES = [
    'dm_spl_release_human_rx_part1.zip',
    'dm_spl_release_human_rx_part2.zip',
    'dm_spl_release_human_rx_part3.zip',
    'dm_spl_release_human_rx_part4.zip',
    'dm_spl_release_human_rx_part5.zip',
]

class FullDailyMedExtractor:
    def __init__(self):
        self.namespaces = {'ns': 'urn:hl7-org:v3'}

    def extract_regex_concentration(self, text: str) -> Optional[str]:
        if not text: return None
        match = CONCENTRATION_REGEX.search(text)
        return match.group(1).strip() if match else None

    def _clean_text(self, text: str) -> str:
        if not text: return ""
        return re.sub(r'\s+', ' ', text).strip()

    def _get_section_text(self, root: ET.Element, code: str) -> Optional[str]:
        for section in root.findall(".//ns:section", self.namespaces):
            code_elem = section.find("ns:code", self.namespaces)
            if code_elem is not None and code_elem.get('code') == code:
                text = ''.join(section.itertext())
                return self._clean_text(text)
        return None

    def _extract_products(self, root: ET.Element) -> List[Dict]:
        products = []
        # Find all manufactured products
        for prod in root.findall(".//ns:manufacturedProduct", self.namespaces):
            product_data = {
                'proprietary_name': None,
                'non_proprietary_name': None,
                'dosage_form': None,
                'ingredients': [],
                'packaging': []
            }
            
            # Names
            name_elem = prod.find(".//ns:name", self.namespaces)
            if name_elem is not None:
                product_data['proprietary_name'] = name_elem.text
            
            generic_elem = prod.find(".//ns:asEntityWithGeneric/ns:genericMedicine/ns:name", self.namespaces)
            if generic_elem is not None:
                product_data['non_proprietary_name'] = generic_elem.text
                
            # Dosage Form
            form_elem = prod.find(".//ns:formCode", self.namespaces)
            if form_elem is not None:
                product_data['dosage_form'] = form_elem.get('displayName')

            # Ingredients & Strengths
            for ing in prod.findall(".//ns:ingredient", self.namespaces):
                ing_data = {
                    'name': None,
                    'strength_value': None,
                    'strength_unit': None,
                    'denominator_value': None,
                    'denominator_unit': None,
                    'concentration_string': None
                }
                
                sub_name = ing.find(".//ns:ingredientSubstance/ns:name", self.namespaces)
                if sub_name is not None:
                    ing_data['name'] = sub_name.text
                
                # Quantity (Numerator)
                qty = ing.find(".//ns:quantity/ns:numerator", self.namespaces)
                if qty is not None:
                    ing_data['strength_value'] = qty.get('value')
                    ing_data['strength_unit'] = qty.get('unit')

                # Denominator (Volume/Unit)
                denom = ing.find(".//ns:quantity/ns:denominator", self.namespaces)
                if denom is not None:
                    ing_data['denominator_value'] = denom.get('value')
                    ing_data['denominator_unit'] = denom.get('unit')
                
                # Construct readable string
                if ing_data['strength_value'] and ing_data['strength_unit']:
                     s = f"{ing_data['strength_value']} {ing_data['strength_unit']}"
                     if ing_data['denominator_value'] and ing_data['denominator_value'] != '1':
                         s += f" / {ing_data['denominator_value']} {ing_data['denominator_unit']}"
                     elif ing_data['denominator_unit'] and ing_data['denominator_unit'] != '1':
                         s += f" / {ing_data['denominator_unit']}"
                     ing_data['concentration_string'] = s
                
                product_data['ingredients'].append(ing_data)
                
            products.append(product_data)
            
        return products

    def extract_from_xml(self, xml_data: bytes) -> Optional[Dict]:
        try:
            root = ET.fromstring(xml_data)
            
            # 1. Metadata
            set_id = root.find(".//ns:setId", self.namespaces)
            set_id_val = set_id.get('root') if set_id is not None else None
            
            title = root.find(".//ns:title", self.namespaces)
            title_text = title.text if title is not None else "Unknown"
            
            data = {
                'set_id': set_id_val,
                'title': title_text,
                'products': self._extract_products(root),
                'clinical_data': {}
            }
            
            # Enrich with Regex Concentration (fallback/supplement)
            if data['products']:
                for prod in data['products']:
                    if prod['proprietary_name']:
                        prod['regex_concentration'] = self.extract_regex_concentration(prod['proprietary_name'])
            
            # 2. Extract All Target Sections
            has_content = False
            for code, field_name in SECTIONS_MAP.items():
                content = self._get_section_text(root, code)
                if content:
                    data['clinical_data'][field_name] = content
                    has_content = True
            
            # Skip if essentially empty
            if not has_content and not data['products']:
                return None
                
            return data

        except Exception as e:
            # print(f"Error parsing XML: {e}")
            return None

def process_zip_part(zip_path: str, extractor: FullDailyMedExtractor) -> List[Dict]:
    part_results = []
    if not os.path.exists(zip_path):
        print(f"❌ File not found: {zip_path}")
        return []
        
    try:
        with zipfile.ZipFile(zip_path, 'r') as z:
            nested_zips = [f for f in z.namelist() if f.endswith('.zip')]
            print(f"  Found {len(nested_zips):,} nested files")
            
            for i, nested_name in enumerate(nested_zips):
                try:
                    nested_data = z.read(nested_name)
                    # Handle zipped XMLs
                    import io
                    with zipfile.ZipFile(io.BytesIO(nested_data)) as nz:
                        xml_files = [f for f in nz.namelist() if f.endswith('.xml')]
                        if xml_files:
                            xml_content = nz.read(xml_files[0])
                            record = extractor.extract_from_xml(xml_content)
                            if record:
                                part_results.append(record)
                except Exception:
                    continue
                    
                if (i + 1) % 2000 == 0:
                    print(f"    Processed {i+1} files... ({len(part_results)} valid records)")
                    
    except Exception as e:
        print(f"❌ Error reading zip {zip_path}: {e}")
        
    return part_results

def main():
    print("="*80)
    print("DailyMed FULL DATA LAKE Extractor (Streaming JSONL)")
    print("="*80)
    
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    extractor = FullDailyMedExtractor()
    
    # Change output to .jsonl
    output_path = OUTPUT_FILE + 'l' # .jsonl
    
    print(f"Streaming records to {output_path}...")
    
    total_count = 0
    
    try:
        with open(output_path, 'w', encoding='utf-8') as f_out:
            for filename in DAILYMED_RELEASE_FILES:
                path = os.path.join(DAILYMED_DOWNLOAD_DIR, filename)
                print(f"\n📦 Processing {filename}...")
                
                if not os.path.exists(path):
                    print(f"❌ File not found: {path} (Skipping)")
                    continue

                # Custom Streaming logic for zip processing
                # We can't use the previous 'process_zip_part' easily if it returns a list
                # Let's inline the logic or modify it. 
                # For simplicity, let's copy the logic here to yield instead of return list
                
                try:
                    with zipfile.ZipFile(path, 'r') as z:
                        nested_zips = [x for x in z.namelist() if x.endswith('.zip')]
                        print(f"  Found {len(nested_zips):,} nested files")
                        
                        for i, nested_name in enumerate(nested_zips):
                            try:
                                nested_data = z.read(nested_name)
                                import io
                                with zipfile.ZipFile(io.BytesIO(nested_data)) as nz:
                                    xml_files = [x for x in nz.namelist() if x.endswith('.xml')]
                                    if xml_files:
                                        xml_content = nz.read(xml_files[0])
                                        record = extractor.extract_from_xml(xml_content)
                                        if record:
                                            # Write line immediately
                                            f_out.write(json.dumps(record, ensure_ascii=False) + '\n')
                                            total_count += 1
                            except Exception:
                                continue
                                
                            if (i + 1) % 2000 == 0:
                                print(f"    Processed {i+1} files... ({total_count} total records)")
                                f_out.flush() # Ensure wrote to disk
                                
                except Exception as e:
                    print(f"❌ Error reading zip {path}: {e}")

        print(f"\n✅ Done! Total Records: {total_count:,}")
        
    except Exception as e:
        print(f"❌ Fatal Error: {e}")
        
if __name__ == '__main__':
    main()
