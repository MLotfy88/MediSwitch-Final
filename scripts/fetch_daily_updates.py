#!/usr/bin/env python3
"""
DailyMed Daily Update Fetcher
Fetches SPLs published/updated in the last 24 hours (or specified date),
extracts Dosages and Interactions, and outputs incremental updates.
"""

import os
import sys
import json
import requests
import argparse
import zipfile
import io
from datetime import datetime, timedelta
import pandas as pd

# Import logic from sibling scripts
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
try:
    from process_datalake import DosageParser, normalize_active_ingredient, clean_drug_name, load_app_data, extract_regex_concentration
    # Note: process_datalake needs to be importable. We might need to adjust it slightly if it runs code on import.
except ImportError:
    print("⚠️  process_datalake.py not found or failed to import.")
    sys.exit(1)

# We need to import DailyMedInteractionExtractor from production_data directory
sys.path.append(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'production_data'))
try:
    from extract_dailymed_interactions import DailyMedInteractionExtractor
except ImportError:
    print("⚠️  extract_dailymed_interactions.py not found or failed to import. Interactions will be skipped.")
    DailyMedInteractionExtractor = None

# Config
BASE_URL = "https://dailymed.nlm.nih.gov/dailymed/services/v2"
OUTPUT_DIR = "production_data/updates"

def get_updates_list(date_str):
    """Fetch list of updated SPLs for a given date (YYYY-MM-DD)"""
    print(f"🔍 Checking for updates on {date_str}...")
    
    updates = []
    page = 1
    
    while True:
        url = f"{BASE_URL}/spls.json?published_date={date_str}&page={page}"
        try:
            resp = requests.get(url, timeout=30)
            resp.raise_for_status()
            data = resp.json()
            
            items = data.get('data', [])
            if not items:
                break
                
            for item in items:
                updates.append({
                    'setid': item.get('setid'),
                    'title': item.get('title'),
                    'published_date': item.get('published_date')
                })
            
            # Check if more pages
            meta = data.get('metadata', {})
            if meta.get('current_page') >= meta.get('total_pages'):
                break
                
            page += 1
            
        except Exception as e:
            print(f"❌ Error fetching updates list: {e}")
            break
            
    print(f"✅ Found {len(updates)} updates.")
    return updates

def process_single_spl(setid, dosage_parser, interaction_extractor, app_maps):
    """Download and process a single SPL"""
    url = f"{BASE_URL}/spls/{setid}/file"
    try:
        resp = requests.get(url, timeout=60)
        if resp.status_code != 200:
            return None, None
            
        # Unzip in memory
        with zipfile.ZipFile(io.BytesIO(resp.content)) as z:
            xml_files = [f for f in z.namelist() if f.endswith('.xml')]
            if not xml_files:
                return None, None
            
            xml_content = z.read(xml_files[0])
            
            # 1. Extract Dosages (Mocking process_datalake logic)
            # Since process_datalake expects JSON structure from the Data Lake, 
            # we need to parse the XML here similar to how the Data Lake was built.
            # OR better: We parse the XML directly to extract what we need.
            # However, for consistency, reusing the extractor logic is best.
            # But process_datalake works on the JSON output of 'extract_full_dailymed.py'.
            # That extraction logic is complex (XML -> JSON). 
            # For this Daily Script, we will implement a simplified XML parser that targets the fields we need.
            
            from xml.etree import ElementTree as ET
            root = ET.fromstring(xml_content)
            namespaces = {'ns': 'urn:hl7-org:v3'}
            
            # Extract basic info
            drug_name = "Unknown"
            generic_name = "Unknown"
            
            generic_elem = root.find(".//ns:genericMedicine/ns:name", namespaces)
            if generic_elem is not None: generic_name = generic_elem.text
            
            name_elem = root.find(".//ns:manufacturedProduct/ns:manufacturedProduct/ns:name", namespaces)
            if name_elem is not None: drug_name = name_elem.text
            
            # Extract Clinical Sections
            sections = root.findall(".//ns:section", namespaces)
            clinical_data = {}
            section_map = {
                '34068-7': 'dosage_and_administration',
                '34073-7': 'drug_interactions',
                '34070-3': 'contraindications',
                '34071-1': 'warnings_and_cautions', # Boxed warning often here or separate
                '34067-9': 'indications_and_usage',
                '34077-8': 'pregnancy'
            }
            
            for sec in sections:
                code_elem = sec.find("ns:code", namespaces)
                if code_elem is not None:
                    code = code_elem.get('code')
                    if code in section_map:
                        text = "".join(sec.itertext())
                        clinical_data[section_map[code]] = text
            
            # DOSAGE RECORD
            dosage_record = None
            
            # Try Linkage (Simplified Logic from process_datalake)
            app_map, app_active_exact, app_active_stripped = app_maps
            clean_dn = clean_drug_name(drug_name) if drug_name else ""
            
            linked_record = None
            linkage_type = "None"
            
            if clean_dn in app_map:
                linked_record = app_map[clean_dn][0] # Take first
                linkage_type = "Trade_Name"
            elif generic_name:
                g_exact = normalize_active_ingredient(generic_name, strip_salts=False)
                if g_exact in app_active_exact:
                    linked_record = app_active_exact[g_exact][0]
                    linkage_type = "Active_Exact"
                else:
                    g_strip = normalize_active_ingredient(generic_name, strip_salts=True)
                    if g_strip in app_active_stripped:
                        linked_record = app_active_stripped[g_strip][0]
                        linkage_type = "Active_Stripped"
            
            if linked_record:
                # Build Dosage Object
                d_text = clinical_data.get('dosage_and_administration', '')
                struct_dose = dosage_parser.extract_structured_dose(d_text)
                
                dosage_record = {
                    'med_id': linked_record['id'],
                    'set_id': setid,
                    'trade_name': linked_record.get('trade_name'),
                    'dailymed_name': drug_name,
                    'linkage_method': linkage_type,
                    'dosages': struct_dose,
                    'clinical_text': {
                        'dosage': d_text[:2000],
                        'interactions': clinical_data.get('drug_interactions', '')[:1000],
                        'contraindications': clinical_data.get('contraindications', '')[:1000],
                        'pregnancy': clinical_data.get('pregnancy', '')[:500]
                    }
                }

            # INTERACTION RECORD
            interaction_records = []
            if interaction_extractor:
                interaction_records = interaction_extractor.extract_from_xml(xml_content)
                
            return dosage_record, interaction_records

    except Exception as e:
        print(f"  ❌ Error processing {setid}: {e}")
        return None, None

def main():
    parser = argparse.ArgumentParser(description="Fetch DailyMed Updates")
    parser.add_argument("--days", type=int, default=1, help="Number of recent days to fetch (default: 1)")
    parser.add_argument("--date", type=str, help="Specific date YYYY-MM-DD")
    args = parser.parse_args()
    
    # Determine dates
    dates = []
    if args.date:
        dates.append(args.date)
    else:
        today = datetime.now()
        for i in range(args.days):
            d = today - timedelta(days=i)
            dates.append(d.strftime("%Y-%m-%d"))
            
    # Load Support Data
    print("📂 Loading App Data for Linkage...")
    try:
        app_maps = load_app_data()
    except Exception as e:
        print(f"  ❌ Failed to load app data: {e}")
        app_maps = ({}, {}, {})

    dosage_parser = DosageParser()
    
    # Load Interaction Extractor
    interaction_extractor = None
    if DailyMedInteractionExtractor:
         # Mock known ingredients (or load real file if present)
         known_file = 'production_data/known_ingredients.json'
         known = set()
         if os.path.exists(known_file):
             with open(known_file) as f:
                 known = set(json.load(f).get('ingredients', []))
         interaction_extractor = DailyMedInteractionExtractor(known)

    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    new_dosages = []
    new_interactions = []
    
    for date_str in dates:
        updates = get_updates_list(date_str)
        
        for i, item in enumerate(updates):
            setid = item['setid']
            print(f"  Processing {i+1}/{len(updates)}: {setid}...")
            
            d_rec, i_recs = process_single_spl(setid, dosage_parser, interaction_extractor, app_maps)
            
            if d_rec:
                new_dosages.append(d_rec)
                print(f"    ✅ Linked Dosage for {d_rec['dailymed_name']}")
            
            if i_recs:
                new_interactions.extend(i_recs)
                print(f"    found {len(i_recs)} interactions")

    # SAVE OUTPUT
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    if new_dosages:
        dose_file = f"{OUTPUT_DIR}/update_dosages_{timestamp}.jsonl"
        with open(dose_file, 'w') as f:
            for rec in new_dosages:
                f.write(json.dumps(rec, ensure_ascii=False) + '\n')
        print(f"\n💾 Saved {len(new_dosages)} dosage updates to {dose_file}")
        
    if new_interactions:
        int_file = f"{OUTPUT_DIR}/update_interactions_{timestamp}.json"
        with open(int_file, 'w') as f:
            json.dump(new_interactions, f, indent=2, ensure_ascii=False)
        print(f"💾 Saved {len(new_interactions)} interaction updates to {int_file}")

if __name__ == "__main__":
    main()
