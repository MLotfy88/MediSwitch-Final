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
            
        # PROBE FOR STRENGTH / CONCENTRATIONS
        print("\n🔍 Probing for Product Strengths:")
        # Look for manufacturedProduct/manufacturedMedicine
        products = root.findall(".//ns:manufacturedProduct", namespaces)
        for prod in products:
             name_elem = prod.find(".//ns:name", namespaces)
             prod_name = name_elem.text if name_elem is not None else "Unknown"
             
             # Strength is often in ingredient/quantity
             ingredients = prod.findall(".//ns:ingredient", namespaces)
             for ing in ingredients:
                 sub_name_elem = ing.find(".//ns:ingredientSubstance/ns:name", namespaces)
                 sub_name = sub_name_elem.text if sub_name_elem is not None else "Unknown"
                 
                 qty_elem = ing.find(".//ns:quantity/ns:numerator", namespaces)
                 unit_elem = ing.find(".//ns:quantity/ns:numerator", namespaces) # unit is attr
                 
                 val = qty_elem.get('value') if qty_elem is not None else "?"
                 unit = qty_elem.get('unit') if qty_elem is not None else "?"
                 
                 denom_elem = ing.find(".//ns:quantity/ns:denominator", namespaces)
                 denom_val = denom_elem.get('value') if denom_elem is not None else "1"
                 denom_unit = denom_elem.get('unit') if denom_elem is not None else ""
                 
                 print(f"  - Product: {prod_name}")
                 print(f"    Active: {sub_name}")
                 print(f"    Strength: {val} {unit} / {denom_val} {denom_unit}")

        # 2. List all sections and their codes
        print("\nAll Sections found in XML:")
        TARGETS = {
            '34068-7': 'DOSAGE',
            '34081-0': 'PEDIATRIC',
            '42228-7': 'PREGNANCY',
            '77290-5': 'LACTATION',
            '34066-1': 'BOXED WARNING',
            '34067-9': 'INDICATIONS'
        }
        
        for section in root.findall(".//ns:section", namespaces):
            code_elem = section.find("ns:code", namespaces)
            title_elem = section.find("ns:title", namespaces)
            
            code = code_elem.get('code') if code_elem is not None else "N/A"
            title = ''.join(title_elem.itertext()) if title_elem is not None else "No Title"
            
            if code in TARGETS:
                print(f"    ✅ MATCHES {TARGETS[code]} ({code}) | Title: {title}")

        # 3. Run full extraction
        print("\nRunning Extractor...")
        results = extractor.extract_from_xml(xml_data)
        print(json.dumps(results, indent=2))

if __name__ == '__main__':
    main()
