#!/usr/bin/env python3
"""
DailyMed SPL Data Downloader & Extractor - OPTIMIZED
Downloads DailyMed daily update and extracts dosage + drug interactions from XML SPL files

Based on the same architecture as extract_dosages_optimized.py for consistency
"""

import os
import requests
import zipfile
import json
import re
from typing import List, Dict, Optional, Tuple
from xml.etree import ElementTree as ET
from datetime import datetime
import sys

# DailyMed Daily Update URL (12/11/2025)
DAILYMED_DAILY_UPDATE = "https://dailymed-data.nlm.nih.gov/public-release-files/dm_spl_daily_update_12112025.zip"

DOWNLOAD_DIR = 'External_source/dailymed/downloaded'
OUTPUT_DIR = 'External_source/dailymed/extracted'
DOSAGE_OUTPUT = 'External_source/dailymed/extracted/dailymed_dosages.json'
INTERACTIONS_OUTPUT = 'External_source/dailymed/extracted/dailymed_interactions.json'

# XML namespaces used in DailyMed SPL
NAMESPACES = {
    'ns': 'urn:hl7-org:v3',
    'xsi': 'http://www.w3.org/2001/XMLSchema-instance'
}

# LOINC codes for relevant sections in SPL
LOINC_CODES = {
    'dosage': '34068-7',           # DOSAGE & ADMINISTRATION
    'interactions': '34073-7',     # DRUG INTERACTIONS
    'pediatric': '34081-0',        # PEDIATRIC USE
    'geriatric': '34082-8',        # GERIATRIC USE
    'indications': '34067-9',      # INDICATIONS AND USAGE
    'warnings': '43685-7',         # WARNINGS AND PRECAUTIONS
    'contraindications': '34070-3' # CONTRAINDICATIONS
}


def download_file(url: str, output_path: str, max_retries: int = 3) -> bool:
    """Download a file from URL with retry logic"""
    for attempt in range(max_retries):
        try:
            print(f"\nDownloading: {os.path.basename(url)}" + 
                  (f" (Attempt {attempt + 1}/{max_retries})" if attempt > 0 else ""))
            
            response = requests.get(url, stream=True, timeout=60)
            response.raise_for_status()
            
            total_size = int(response.headers.get('content-length', 0))
            downloaded = 0
            
            with open(output_path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    if chunk:
                        f.write(chunk)
                        downloaded += len(chunk)
                        if total_size:
                            percent = (downloaded / total_size) * 100
                            print(f"\r  Progress: {percent:.1f}%", end='')
            
            print(f"  ✅ Downloaded: {downloaded / (1024**2):.1f} MB")
            return True
            
        except Exception as e:
            print(f"❌ Download failed: {e}")
            if attempt < max_retries - 1:
                print(f"🔄 Retrying in 5 seconds...")
                import time
                time.sleep(5)
    
    return False


def extract_main_zip(zip_path: str, extract_to: str) -> bool:
    """Extract main ZIP file"""
    try:
        print(f"\n📦 Extracting: {os.path.basename(zip_path)}")
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(extract_to)
        print(f"  ✅ Extracted successfully")
        return True
    except Exception as e:
        print(f"  ❌ Error extracting: {e}")
        return False


def get_section_text(root: ET.Element, section_code: str) -> Optional[str]:
    """Extract text from SPL section using LOINC code"""
    try:
        # Find all sections with matching code
        xpath = f".//ns:section[ns:code[@code='{section_code}']]"
        sections = root.findall(xpath, NAMESPACES)
        
        if not sections:
            return None
        
        texts = []
        for section in sections:
            # Get all text content
            section_text = ''.join(section.itertext())
            if section_text:
                texts.append(section_text.strip())
        
        return ' '.join(texts) if texts else None
    except:
        return None


def clean_text(text: str) -> str:
    """Clean and normalize text"""
    if not text:
        return ""
    # Remove excessive whitespace
    text = re.sub(r'\s+', ' ', text)
    return text.strip()


def extract_drug_names(root: ET.Element) -> Tuple[Optional[str], Optional[str]]:
    """Extract brand name and active ingredient from SPL"""
    try:
        # Brand name
        brand = None
        brand_elem = root.find(".//ns:name", NAMESPACES)
        if brand_elem is not None and brand_elem.text:
            brand = brand_elem.text.strip()
        
        # Active ingredient (substance)
        ingredient = None
        ingredient_elem = root.find(".//ns:activeIngredient/ns:activeIngredient/ns:name", NAMESPACES)
        if ingredient_elem is not None and ingredient_elem.text:
            ingredient = ingredient_elem.text.strip()
        elif root.find(".//ns:ingredient/ns:ingredientSubstance/ns:name", NAMESPACES) is not None:
            ingredient = root.find(".//ns:ingredient/ns:ingredientSubstance/ns:name", NAMESPACES).text.strip()
        
        return brand, ingredient
    except:
        return None, None


def extract_strength(text: str) -> Optional[str]:
    """Extract strength/concentration from text (same as OpenFDA)"""
    if not text:
        return None
    
    text = text.lower().strip()
    text = text.replace('equivalent to', '')
    
    # Pattern for strength
    pattern = r'\b(\d+(?:\.\d+)?)\s*(mg|mcg|g|ml|%|meq|units?|iu)(?:\s*/\s*(\d+(?:\.\d+)?)\s*(mg|mcg|ml|g))?\b'
    match = re.search(pattern, text)
    
    if match:
        value1 = match.group(1)
        unit1 = match.group(2)
        
        if match.group(3):
            value2 = match.group(3)
            unit2 = match.group(4)
            return f"{value1}{unit1}/{value2}{unit2}"
        else:
            return f"{value1}{unit1}"
    
    return None


def extract_dosage_info(dosage_text: str) -> Tuple[str, str]:
    """Extract standard_dose and max_dose from text (same patterns as OpenFDA)"""
    standard_dose = ""
    max_dose = ""
    
    if not dosage_text:
        return standard_dose, max_dose
        
    text_lower = dosage_text.lower()
    
    # Max dose patterns
    max_patterns = [
        r'max(?:imum)?\\s*(?:daily)?\\s*(?:dose)?\\s*(?:is|of)?\\s*:?\\s*(\\d+(?:\\.\\d+)?)\\s*(mg|mcg|g|tablet|capsule)s?',
        r'not\\s*(?:to)?\\s*(?:take|use|exceed)?\\s*more\\s*than\\s*(\\d+(?:\\.\\d+)?)\\s*(mg|mcg|g|tablet|capsule|dose)s?',
        r'do\\s*not\\s*exceed\\s*(\\d+(?:\\.\\d+)?)\\s*(mg|mcg|g|tablet|capsule)s?',
        r'(?:up|no\\s*more)\\s*(?:to|than)\\s*(\\d+(?:\\.\\d+)?)\\s*(mg|mcg|g|tablet|capsule|dose)s?',
    ]
    
    for pattern in max_patterns:
        match = re.search(pattern, text_lower)
        if match:
            max_dose = f"{match.group(1)} {match.group(2)}"
            break
    
    # Standard dose patterns
    standard_patterns = [
        r'(?:recommended|usual|starting|initial)\\s+(?:adult|pediatric)?\\s*dose\\s*(?:is|of)?\\s*:?\\s*(\\d+(?:\\.\\d+)?)\\s*(mg|mcg|g|ml|tablet|capsule)s?',
        r'take\\s*(\\d+(?:\\.\\d+)?)\\s*(tablet|capsule|pill|caplet)s?',
        r'(\\d+)\\s*(?:to|-)\\s*(\\d+)\\s*(tablet|capsule|pill|caplet)s?\\s*(?:every|daily|per\\s*day)',
        r'(\\d+(?:\\.\\d+)?)\\s*(mg|mcg|g|ml)\\s+(?:every|once|twice|three\\s*times|q\\d+h?|daily)',
        r'dose(?:age)?:\\s*(\\d+(?:\\.\\d+)?)\\s*(mg|mcg|g|ml|tablet|capsule)s?',
    ]
    
    for pattern in standard_patterns:
        match = re.search(pattern, text_lower)
        if match:
            if len(match.groups()) >= 2 and match.group(2):
                standard_dose = f"{match.group(1)} {match.group(2)}"
            else:
                standard_dose = match.group(1)
            break
    
    return standard_dose, max_dose


def estimate_severity(text: str) -> str:
    """Estimate interaction severity"""
    text_lower = text.lower()
    if any(w in text_lower for w in ['contraindicated', 'do not use', 'life-threatening', 'avoid', 'must not']):
        return 'contraindicated'
    elif any(w in text_lower for w in ['severe', 'serious', 'fatal']):
        return 'severe'
    elif any(w in text_lower for w in ['major', 'significant', 'important']):
        return 'major'
    elif any(w in text_lower for w in ['moderate', 'caution', 'monitor', 'careful']):
        return 'moderate'
    else:
        return 'minor'


def process_spl_xml(xml_file: str) -> Tuple[Optional[Dict], List[Dict]]:
    """Process single SPL XML file and extract dosage + interactions"""
    dosage_record = None
    interaction_records = []
    
    try:
        tree = ET.parse(xml_file)
        root = tree.getroot()
        
        brand_name, active_ingredient = extract_drug_names(root)
        
        if not brand_name and not active_ingredient:
            return None, []
        
        drug_name = (brand_name or active_ingredient).lower()
        
        # === Extract Dosage Information ===
        dosage_text = get_section_text(root, LOINC_CODES['dosage'])
        pediatric_text = get_section_text(root, LOINC_CODES['pediatric'])
        
        if dosage_text or pediatric_text:
            combined_text = (dosage_text or '') + ' ' + (pediatric_text or '')
            standard_dose, max_dose = extract_dosage_info(combined_text)
            
            # Extract strength
            strength = extract_strength(combined_text)
            if not strength:
                strength = "general"
            
            # Create dosage record if we have meaningful data
            if standard_dose or max_dose or len(combined_text) > 100:
                dosage_record = {
                    'active_ingredient': drug_name,
                    'strength': strength,
                    'standard_dose': standard_dose if standard_dose else None,
                    'max_dose': max_dose if max_dose else None,
                    'package_label': clean_text(combined_text[:500]) if combined_text else None
                }
        
        # === Extract Drug Interactions ===
        interactions_text = get_section_text(root, LOINC_CODES['interactions'])
        
        if interactions_text and len(interactions_text) > 30:
            # Split into sentences
            sentences = re.split(r'(?<=[.!?])\s+', interactions_text)
            
            for sentence in sentences:
                if len(sentence) < 40:
                    continue
                
                interaction = {
                    'ingredient1': drug_name,
                    'ingredient2': 'other_medications',
                    'severity': estimate_severity(sentence),
                    'type': 'pharmacodynamic' if 'effect' in sentence.lower() else 'class_interaction',
                    'effect': clean_text(sentence[:500]),
                    'arabic_effect': '',
                    'recommendation': '',
                    'arabic_recommendation': '',
                    'source': 'DailyMed'
                }
                interaction_records.append(interaction)
    
    except Exception as e:
        # Silently skip problematic files
        pass
    
    return dosage_record, interaction_records


def process_drug_zip(zip_path: str) -> Tuple[Optional[Dict], List[Dict]]:
    """Process individual drug ZIP file containing XML"""
    try:
        with zipfile.ZipFile(zip_path, 'r') as z:
            xml_files = [f for f in z.namelist() if f.endswith('.xml')]
            if not xml_files:
                return None, []
            
            # Extract XML temporarily
            xml_data = z.read(xml_files[0])
            
            # Parse from string
            root = ET.fromstring(xml_data)
            
            # Extract data (reusing logic)
            brand_name, active_ingredient = extract_drug_names(root)
            
            if not brand_name and not active_ingredient:
                return None, []
            
            drug_name = (brand_name or active_ingredient).lower()
            
            # Dosage
            dosage_text = get_section_text(root, LOINC_CODES['dosage'])
            pediatric_text = get_section_text(root, LOINC_CODES['pediatric'])
            
            dosage_record = None
            if dosage_text or pediatric_text:
                combined_text = (dosage_text or '') + ' ' + (pediatric_text or '')
                standard_dose, max_dose = extract_dosage_info(combined_text)
                strength = extract_strength(combined_text) or "general"
                
                if standard_dose or max_dose or len(combined_text) > 100:
                    dosage_record = {
                        'active_ingredient': drug_name,
                        'strength': strength,
                        'standard_dose': standard_dose if standard_dose else None,
                        'max_dose': max_dose if max_dose else None,
                        'package_label': clean_text(combined_text[:500]) if combined_text else None
                    }
            
            # Interactions
            interactions_text = get_section_text(root, LOINC_CODES['interactions'])
            interaction_records = []
            
            if interactions_text and len(interactions_text) > 30:
                sentences = re.split(r'(?<=[.!?])\s+', interactions_text)
                
                for sentence in sentences:
                    if len(sentence) < 40:
                        continue
                    
                    interaction = {
                        'ingredient1': drug_name,
                        'ingredient2': 'other_medications',
                        'severity': estimate_severity(sentence),
                        'type': 'pharmacodynamic' if 'effect' in sentence.lower() else 'class_interaction',
                        'effect': clean_text(sentence[:500]),
                        'arabic_effect': '',
                        'recommendation': '',
                        'arabic_recommendation': '',
                        'source': 'DailyMed'
                    }
                    interaction_records.append(interaction)
            
            return dosage_record, interaction_records
            
    except Exception as e:
        return None, []


def main():
    """Main extraction process"""
    print("=" * 80)
    print("DailyMed SPL Data Extractor - OPTIMIZED")
    print("=" * 80)
    
    os.makedirs(DOWNLOAD_DIR, exist_ok=True)
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    # Download if needed
    zip_filename = os.path.basename(DAILYMED_DAILY_UPDATE)
    zip_path = os.path.join(DOWNLOAD_DIR, zip_filename)
    
    if not os.path.exists(zip_path):
        print(f"\n📥 Downloading DailyMed daily update...")
        if not download_file(DAILYMED_DAILY_UPDATE, zip_path):
            print("❌ Failed to download. Exiting.")
            return
    else:
        print(f"\n✓ Using cached file: {zip_filename}")
    
    # Extract main ZIP
    extract_dir = os.path.join(DOWNLOAD_DIR, 'extracted')
    if not os.path.exists(extract_dir):
        if not extract_main_zip(zip_path, extract_dir):
            print("❌ Failed to extract. Exiting.")
            return
    
    # Process drug ZIP files
    print("\n🔄 Processing drug files...")
    
    all_dosages = {}
    all_interactions = []
    
    # Only process prescription and otc (most relevant)
    categories = ['prescription', 'otc']
    
    for category in categories:
        category_dir = os.path.join(extract_dir, category)
        if not os.path.exists(category_dir):
            continue
        
        drug_zips = [f for f in os.listdir(category_dir) if f.endswith('.zip')]
        print(f"\n  {category.upper()}: {len(drug_zips)} drugs")
        
        for i, drug_zip in enumerate(drug_zips):
            if (i + 1) % 100 == 0:
                print(f"    Processed {i+1}/{len(drug_zips)} ({len(all_dosages)} dosages, {len(all_interactions)} interactions)")
            
            zip_path = os.path.join(category_dir, drug_zip)
            dosage, interactions = process_drug_zip(zip_path)
            
            if dosage:
                key = (dosage['active_ingredient'], dosage['strength'])
                all_dosages[key] = dosage
            
            all_interactions.extend(interactions)
    
    # Convert to lists
    final_dosages = list(all_dosages.values())
    
    # Save results
    with open(DOSAGE_OUTPUT, 'w', encoding='utf-8') as f:
        json.dump(final_dosages, f, indent=2, ensure_ascii=False)
    
    with open(INTERACTIONS_OUTPUT, 'w', encoding='utf-8') as f:
        json.dump(all_interactions, f, indent=2, ensure_ascii=False)
    
    # Summary
    print("\n" + "=" * 80)
    print("📊 Extraction Summary")
    print("=" * 80)
    print(f"  • Dosages extracted: {len(final_dosages):,}")
    print(f"    File: {DOSAGE_OUTPUT}")
    print(f"    Size: {os.path.getsize(DOSAGE_OUTPUT) / 1024:.1f} KB")
    print(f"  • Interactions extracted: {len(all_interactions):,}")
    print(f"    File: {INTERACTIONS_OUTPUT}")
    print(f"    Size: {os.path.getsize(INTERACTIONS_OUTPUT) / 1024:.1f} KB")
    
    # Statistics
    with_standard = sum(1 for d in final_dosages if d['standard_dose'])
    with_max = sum(1 for d in final_dosages if d['max_dose'])
    with_label = sum(1 for d in final_dosages if d['package_label'])
    
    print(f"\nDosage Breakdown:")
    print(f"  • With standard_dose: {with_standard:,} ({with_standard/len(final_dosages)*100:.1f}%)" if final_dosages else "  • No dosages")
    print(f"  • With max_dose: {with_max:,} ({with_max/len(final_dosages)*100:.1f}%)" if final_dosages else "")
    print(f"  • With package_label: {with_label:,} ({with_label/len(final_dosages)*100:.1f}%)" if final_dosages else "")
    
    print("\n✅ Extraction complete!")


if __name__ == '__main__':
    main()
