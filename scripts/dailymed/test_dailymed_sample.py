#!/usr/bin/env python3
"""
DailyMed Sample Analyzer - Quick Test Script
Test extraction from one DailyMed file to compare with OpenFDA
"""

import zipfile
import json
from xml.etree import ElementTree as ET
import re
import os

NANESPACES = {
    '': 'urn:hl7-org:v3',
    'xsi': 'http://www.w3.org/2001/XMLSchema-instance'
}

def clean_text(txt):
    if not txt:
        return ""
    return re.sub(r'\s+', ' ', txt).strip()

def extract_text_from_section(section_elem):
    """Extract all text from section"""
    texts = []
    for text_elem in section_elem.iter('{urn:hl7-org:v3}text'):
        txt = ''.join(text_elem.itertext())
        if txt:
            texts.append(clean_text(txt))
    return ' '.join(texts)

# Test file
test_zip = "External_source/dailymed/downloaded/extracted/otc/20251211_a89f021e-1a82-83f7-e053-2a95a90a518f.zip"

print("="*80)
print("DailyMed Sample Analysis")
print("="*80)

with zipfile.ZipFile(test_zip, 'r') as z:
    xml_files = [f for f in z.namelist() if f.endswith('.xml')]
    print(f"\nXML files in ZIP: {xml_files}")
    
    xml_data = z.read(xml_files[0])
    root = ET.fromstring(xml_data)
    
    # Get drug name
    name_elem = root.find('.//{urn:hl7-org:v3}name')
    if name_elem is not None:
        drug_name = ''.join(name_elem.itertext()).strip()
        print(f"\nDrug Name: {drug_name}")
    
    # Get active ingredient
    active_elem = root.find('.//{urn:hl7-org:v3}genericMedicine/{urn:hl7-org:v3}name')
    if active_elem is not None:
        print(f"Active Ingredient: {active_elem.text}")
    
    # Get all sections
    print("\n" + "="*80)
    print("SECTIONS FOUND:")
    print("="*80)
    
    sections = root.findall('.//{urn:hl7-org:v3}section')
    print(f"Total sections: {len(sections)}")
    
    for i, section in enumerate(sections[:10]):  # First 10 sections
        code_elem = section.find('{urn:hl7-org:v3}code')
        if code_elem is not None:
            code = code_elem.get('code')
            display = code_elem.get('displayName', 'N/A')
            
            # Get section text
            text = extract_text_from_section(section)
            text_preview = text[:200] if text else "No text"
            
            print(f"\n[{i+1}] Code: {code}")
            print(f"    Display: {display}")
            print(f"    Text ({len(text)} chars): {text_preview}...")
    
    # Try specific LOINC codes
    print("\n" + "="*80)
    print("SEARCHING FOR SPECIFIC LOINC CODES:")
    print("="*80)
    
    target_codes = {
        '34068-7': 'DOSAGE & ADMINISTRATION',
        '34073-7': 'DRUG INTERACTIONS',
        '34081-0': 'PEDIATRIC USE',
        '50565-1': 'KEEP OUT OF REACH OF CHILDREN',
        '55106-9': 'OTC - ACTIVE INGREDIENT SECTION',
        '50566-9': 'PRINCIPAL DISPLAY PANEL',
    }
    
    for code, name in target_codes.items():
        xpath = f".//{'{urn:hl7-org:v3}'}section[{'{urn:hl7-org:v3}'}code[@code='{code}']]"
        sections = root.findall(xpath)
        
        if sections:
            text = extract_text_from_section(sections[0])
            print(f"\n✓ {name} ({code})")
            print(f"  Text: {text[:300]}...")
        else:
            print(f"\n✗ {name} ({code}) - NOT FOUND")

print("\n" + "="*80)
