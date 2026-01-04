#!/usr/bin/env python3
"""
DailyMed Streaming Processor
Combines Download & Extraction to minimize disk usage.
Process: Download Part -> Extract to JSONL.GZ -> Delete Part -> Repeat
"""

import os
import requests
import zipfile
import json
import re
import sys
import gzip
import io
from xml.etree import ElementTree as ET
from typing import List, Dict, Optional

# --- Configuration ---
DAILYMED_URLS = [
    "https://dailymed-data.nlm.nih.gov/public-release-files/dm_spl_release_human_rx_part1.zip",
    "https://dailymed-data.nlm.nih.gov/public-release-files/dm_spl_release_human_rx_part2.zip",
    "https://dailymed-data.nlm.nih.gov/public-release-files/dm_spl_release_human_rx_part3.zip",
    "https://dailymed-data.nlm.nih.gov/public-release-files/dm_spl_release_human_rx_part4.zip",
    "https://dailymed-data.nlm.nih.gov/public-release-files/dm_spl_release_human_rx_part5.zip",
]

TEMP_DIR = "External_source/dailymed/temp"
OUTPUT_DIR = "production_data"
OUTPUT_FILE = "production_data/dailymed_full_database.jsonl.gz"

# --- Extraction Logic (Copied from extract_full_dailymed.py) ---
CONCENTRATION_REGEX = re.compile(
    r"""
    (                          # Start capturing group 1
        \d+ (?:[.,]\d+)?       # Match number
        \s*                    # Optional whitespace
        (?:mg|mcg|g|kg|ml|l|iu|%) # Match units
        (?:                    # Optional second part
            \s* / \s*          
            (?:ml|mg|g|kg|l)   
        )?
    )                          # End capturing group 1
    """,
    re.IGNORECASE | re.VERBOSE
)

SECTIONS_MAP = {
    '34066-1': 'boxed_warning',
    '34067-9': 'indications',
    '34068-7': 'dosage_and_administration',
    '34081-0': 'pediatric_use',
    '88821-5': 'renal_impairment',
    '88822-3': 'hepatic_impairment',
    '34070-3': 'contraindications',
    '34071-1': 'warnings_and_precautions',
    '34073-7': 'drug_interactions',
}

class DailyMedExtractor:
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
        for prod in root.findall(".//ns:manufacturedProduct", self.namespaces):
            product_data = {
                'proprietary_name': None,
                'non_proprietary_name': None,
                'ingredients': []
            }
            # Names
            name_elem = prod.find(".//ns:name", self.namespaces)
            if name_elem is not None:
                product_data['proprietary_name'] = name_elem.text
            
            generic_elem = prod.find(".//ns:asEntityWithGeneric/ns:genericMedicine/ns:name", self.namespaces)
            if generic_elem is not None:
                product_data['non_proprietary_name'] = generic_elem.text

            # Ingredients
            for ing in prod.findall(".//ns:ingredient", self.namespaces):
                ing_data = {'name': None, 'strength': None}
                sub_name = ing.find(".//ns:ingredientSubstance/ns:name", self.namespaces)
                if sub_name is not None:
                    ing_data['name'] = sub_name.text
                
                # Simple strength extraction
                qty = ing.find(".//ns:quantity/ns:numerator", self.namespaces)
                unit = qty.get('unit') if qty is not None else ''
                val = qty.get('value') if qty is not None else ''
                if val: ing_data['strength'] = f"{val} {unit}"
                
                products.append({**product_data, **ing_data}) # Flatten for simplicity
                
            if not products: # If no ingredients found (rare), still add product
                 products.append(product_data)
                 
        return products

    def extract_from_xml(self, xml_data: bytes) -> Optional[Dict]:
        try:
            root = ET.fromstring(xml_data)
            
            set_id = root.find(".//ns:setId", self.namespaces)
            set_id_val = set_id.get('root') if set_id is not None else None
            
            data = {
                'set_id': set_id_val,
                'products': self._extract_products(root),
                'clinical_data': {}
            }
            
            # Extract Sections
            has_content = False
            for code, field_name in SECTIONS_MAP.items():
                content = self._get_section_text(root, code)
                if content:
                    data['clinical_data'][field_name] = content
                    has_content = True
            
            if not has_content and not data['products']:
                return None
                
            return data

        except Exception:
            return None

# --- Streaming Functions ---

def download_file(url, output_path):
    print(f"📥 Downloading {os.path.basename(url)}...")
    try:
        with requests.get(url, stream=True, timeout=600) as r:
            r.raise_for_status()
            with open(output_path, 'wb') as f:
                for chunk in r.iter_content(chunk_size=8192):
                    f.write(chunk)
        print("✅ Download complete.")
        return True
    except Exception as e:
        print(f"❌ Download failed: {e}")
        return False

def process_and_delete(zip_path, writer, extractor):
    print(f"📦 Extracting from {os.path.basename(zip_path)}...")
    count = 0
    try:
        with zipfile.ZipFile(zip_path, 'r') as z:
            nested_zips = [f for f in z.namelist() if f.endswith('.zip')]
            print(f"   Found {len(nested_zips)} nested SPL files.")
            
            for i, nested_name in enumerate(nested_zips):
                try:
                    nested_data = z.read(nested_name)
                    with zipfile.ZipFile(io.BytesIO(nested_data)) as nz:
                        xml_files = [x for x in nz.namelist() if x.endswith('.xml')]
                        if xml_files:
                            xml_content = nz.read(xml_files[0])
                            record = extractor.extract_from_xml(xml_content)
                            if record:
                                writer.write(json.dumps(record, ensure_ascii=False) + '\n')
                                count += 1
                except Exception:
                    continue
                    
                if (i + 1) % 5000 == 0:
                    print(f"   Processed {i+1} nested files...")
                    
        print(f"✅ Extracted {count} valid records.")
    except Exception as e:
        print(f"❌ Error processing zip: {e}")
    finally:
        print(f"🗑️ Deleting {zip_path} to free space...")
        try:
            os.remove(zip_path)
            print("✅ Deleted.")
        except OSError as e:
            print(f"⚠️ Could not delete: {e}")
            
    return count

def main():
    print("🚀 Starting Streamlined DailyMed Processing")
    os.makedirs(TEMP_DIR, exist_ok=True)
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    extractor = DailyMedExtractor()
    total_records = 0
    
    # Open Output File (Append Mode if we were resuming, but here we overwrite for fresh build)
    # Actually, iterate URLs.
    
    with gzip.open(OUTPUT_FILE, 'wt', encoding='utf-8') as f_out:
        for url in DAILYMED_URLS:
            filename = os.path.basename(url)
            temp_path = os.path.join(TEMP_DIR, filename)
            
            # 1. Download
            if download_file(url, temp_path):
                # 2. Process & 3. Delete
                count = process_and_delete(temp_path, f_out, extractor)
                total_records += count
                f_out.flush()
            else:
                print(f"⚠️ Skipping {filename} due to download failure.")
                
    print(f"\n🎉 Total Records Processed: {total_records:,}")
    print(f"💾 Saved to: {OUTPUT_FILE}")
    print(f"📏 File Size: {os.path.getsize(OUTPUT_FILE) / (1024**2):.2f} MB")

if __name__ == '__main__':
    main()
