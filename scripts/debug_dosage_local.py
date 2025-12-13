import os
import zipfile
import json
import io
import sys

# Adjust path to import production module
sys.path.append(os.getcwd())
from production_data.extract_dosages_production import DailyMedDosageExtractor, LOINC_DOSAGE_ADMIN, LOINC_PEDIATRIC, LOINC_GERIATRIC, LOINC_RENAL, LOINC_HEPATIC

TEST_ZIP = 'External_source/dailymed/downloaded/extracted/prescription/20251211_a774e1ae-3997-49ee-8b0e-99a2b315d409.zip'
KNOWN_INGREDIENTS_FILE = 'production_data/known_ingredients.json'

def main():
    print(f"Testing with: {TEST_ZIP}")
    
    # Load ingredients (or mock it to allow everything for debugging)
    with open(KNOWN_INGREDIENTS_FILE, 'r') as f:
        known = set(json.load(f)['ingredients'])
    
    # Initialize extractor with relaxed matching for debugging
    # We want to see what's in the file even if it's not in known_ingredients
    extractor = DailyMedDosageExtractor(known)
    
    with zipfile.ZipFile(TEST_ZIP, 'r') as z:
        xml_files = [f for f in z.namelist() if f.endswith('.xml')]
        print(f"Found XMLs: {xml_files}")
        
        if not xml_files:
            return
            
        xml_data = z.read(xml_files[0])
        
        # 1. Print drug name found
        from xml.etree import ElementTree as ET
        root = ET.fromstring(xml_data)
        namespaces = {'ns': 'urn:hl7-org:v3'}
        
        name = extractor._extract_drug_name(root)
        print(f"Extracted Drug Name: '{name}'")
        
        if name and name not in known:
            print(f"⚠️ Warning: '{name}' is NOT in known ingredients")
            
        # 2. List all sections and their codes
        print("\nAll Sections found in XML:")
        for section in root.findall(".//ns:section", namespaces):
            code_elem = section.find("ns:code", namespaces)
            title_elem = section.find("ns:title", namespaces)
            
            code = code_elem.get('code') if code_elem is not None else "N/A"
            title = ''.join(title_elem.itertext()) if title_elem is not None else "No Title"
            
            print(f"  Code: {code} | Title: {title}")
            
            # Check if it matches our targets
            if code == LOINC_DOSAGE_ADMIN:
                print(f"    ✅ MATCHES DOSAGE_ADMIN (34068-7)")
                text = ''.join(section.itertext())
                print(f"    Length: {len(text)} chars")
                print(f"    Sample: {text[:100]}...")
            elif code == LOINC_PEDIATRIC:
                print(f"    ✅ MATCHES PEDIATRIC")

        # 3. Run full extraction
        print("\nRunning Extractor...")
        results = extractor.extract_from_xml(xml_data)
        print(json.dumps(results, indent=2))

if __name__ == '__main__':
    main()
