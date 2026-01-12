#!/usr/bin/env python3
"""
NCBI Fallback Dosage Integrator
================================
This script populates missing dosage data using NCBI/StatPearls as a fallback.

Strategy:
1. Find all drugs WITHOUT WikEM dosage data
2. Match them to NCBI via ingredient name (using med_ingredients table)
3. Fetch dosage information from NCBI StatPearls
4. Insert into dosage_guidelines with source='NCBI'
"""

import sqlite3
import csv
import requests
import time
import re
from pathlib import Path
from bs4 import BeautifulSoup

# Configuration
DB_PATH = Path("assets/database/mediswitch.db")
NCBI_MATCHES = Path("scripts/statpearls_scraper/bulk_matched_targets.csv")
USER_AGENT = "MediSwitch Research Bot (admin@mediswitch.com)"

session = requests.Session()
session.headers.update({"User-Agent": USER_AGENT})

def get_drugs_without_dosage():
    """Get all drugs that don't have WikEM dosage data"""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Get med_ids that already have WikEM dosages
    cursor.execute("""
        SELECT DISTINCT med_id FROM dosage_guidelines WHERE source = 'WikEM'
    """)
    wikem_meds = set(row[0] for row in cursor.fetchall())
    
    # Get all med_ids with their ingredients
    cursor.execute("""
        SELECT DISTINCT mi.med_id, mi.ingredient
        FROM med_ingredients mi
        WHERE mi.ingredient IS NOT NULL AND mi.ingredient != ''
    """)
    all_meds = cursor.fetchall()
    
    conn.close()
    
    # Filter out those that already have WikEM data
    missing = [(med_id, ing) for med_id, ing in all_meds if med_id not in wikem_meds]
    
    print(f"📊 Found {len(wikem_meds)} drugs with WikEM data")
    print(f"📊 Found {len(missing)} drugs without dosage data")
    
    return missing

def load_ncbi_matches():
    """Load the NCBI ingredient matches"""
    matches = {}
    with open(NCBI_MATCHES, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            ing = row['ingredient'].lower().strip()
            matches[ing] = {
                'nbk_id': row['nbk_id'],
                'title': row['title'],
                'url': row['url']
            }
    
    print(f"✅ Loaded {len(matches)} NCBI matches")
    return matches

def extract_dosage_from_ncbi(nbk_id, url):
    """Fetch and extract dosage information from NCBI page"""
    try:
        time.sleep(1)  # Rate limiting
        response = session.get(url, timeout=30)
        
        if response.status_code != 200:
            return None
        
        soup = BeautifulSoup(response.content, 'html.parser')
        
        # Look for common dosage sections
        dosage_keywords = ['dosing', 'dose', 'administration', 'adult dose', 'pediatric']
        
        dosage_data = {
            'indications': '',
            'administration': '',
            'adverse_effects': '',
            'contraindications': '',
            'monitoring': '',
            'mechanism': '',
            'toxicity': ''
        }
        
        # Extract sections
        for section in soup.find_all(['h2', 'h3', 'h4']):
            section_text = section.get_text().lower()
            
            if 'indication' in section_text:
                dosage_data['indications'] = extract_section_text(section)
            elif any(kw in section_text for kw in ['dosing', 'dose', 'administration']):
                dosage_data['administration'] = extract_section_text(section)
            elif 'adverse' in section_text or 'side effect' in section_text:
                dosage_data['adverse_effects'] = extract_section_text(section)
            elif 'contraindication' in section_text:
                dosage_data['contraindications'] = extract_section_text(section)
            elif 'monitoring' in section_text:
                dosage_data['monitoring'] = extract_section_text(section)
            elif 'mechanism' in section_text:
                dosage_data['mechanism'] = extract_section_text(section)
            elif 'toxicity' in section_text or 'overdose' in section_text:
                dosage_data['toxicity'] = extract_section_text(section)
        
        return dosage_data
    
    except Exception as e:
        print(f"❌ Error fetching {nbk_id}: {e}")
        return None

def extract_section_text(header):
    """Extract text content after a section header"""
    text_parts = []
    next_node = header.find_next_sibling()
    
    while next_node and next_node.name not in ['h2', 'h3', 'h4']:
        if next_node.name in ['p', 'ul', 'ol']:
            text_parts.append(next_node.get_text(separator=' ', strip=True))
        next_node = next_node.find_next_sibling()
    
    return ' '.join(text_parts)[:1000]  # Limit to 1000 chars

def integrate_ncbi_data():
    """Main integration function"""
    print("🚀 Starting NCBI Fallback Integration...")
    
    # 1. Get drugs without dosage
    missing_drugs = get_drugs_without_dosage()
    
    if not missing_drugs:
        print("✅ All drugs already have dosage data!")
        return
    
    # 2. Load NCBI matches
    ncbi_matches = load_ncbi_matches()
    
    # 3. Connect to database
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    processed = 0
    inserted = 0
    
    for med_id, ingredient in missing_drugs:
        ing_lower = ingredient.lower().strip()
        
        # Check if we have an NCBI match for this ingredient
        if ing_lower not in ncbi_matches:
            continue
        
        match = ncbi_matches[ing_lower]
        print(f"🔍 Processing: {ingredient} -> {match['nbk_id']}")
        
        # Fetch dosage data from NCBI
        dosage_data = extract_dosage_from_ncbi(match['nbk_id'], match['url'])
        
        if dosage_data:
            # Insert into database
            cursor.execute("""
                INSERT INTO dosage_guidelines (
                    med_id, source,
                    ncbi_indications, ncbi_administration, ncbi_adverse_effects,
                    ncbi_contraindications, ncbi_monitoring, ncbi_mechanism, ncbi_toxicity
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                med_id, "NCBI",
                dosage_data['indications'],
                dosage_data['administration'],
                dosage_data['adverse_effects'],
                dosage_data['contraindications'],
                dosage_data['monitoring'],
                dosage_data['mechanism'],
                dosage_data['toxicity']
            ))
            
            inserted += 1
            
            if inserted % 10 == 0:
                conn.commit()
                print(f"⏳ Processed {inserted} drugs...")
        
        processed += 1
    
    conn.commit()
    conn.close()
    
    print("=" * 50)
    print("✅ NCBI INTEGRATION COMPLETE")
    print(f"💊 Drugs Checked: {processed}")
    print(f"💉 Rows Inserted: {inserted}")
    print("=" * 50)

if __name__ == "__main__":
    integrate_ncbi_data()
