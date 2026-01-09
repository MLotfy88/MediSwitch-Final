
import sqlite3
import requests
import json
import zlib
import re
import time
from html.parser import HTMLParser
import logging

# Setup Logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

DB_PATH = '/home/adminlotfy/project/assets/database/mediswitch.db'
OPENFDA_ENDPOINT = "https://api.fda.gov/drug/label.json"

# ==============================================================================
# 1. PARSING LOGIC (The "Smart" Engine)
# ==============================================================================

class SmartTableParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.rows = []
        self.current_row = []
        self.in_td = False
        self.capture_text = ""
        self.headers = []

    def handle_starttag(self, tag, attrs):
        if tag == 'tr':
            self.current_row = []
        elif tag in ('td', 'th'):
            self.in_td = True
            self.capture_text = ""

    def handle_endtag(self, tag):
        if tag == 'tr':
            self.rows.append(self.current_row)
        elif tag in ('td', 'th'):
            self.in_td = False
            clean_text = ' '.join(self.capture_text.split())
            self.current_row.append(clean_text)

    def handle_data(self, data):
        if self.in_td:
            self.capture_text += data

    def get_structured_data(self):
        # Apply the "Smart Header" logic we developed
        if not self.rows: return []

        max_cols = max(len(r) for r in self.rows) if self.rows else 0
        
        # Heuristic: Find best header row (most populated row in top 5)
        header_row_index = -1
        candidate_headers = []
        
        for i, row in enumerate(self.rows[:5]):
            if len(row) == max_cols:
                non_empty = [c for c in row if c.strip()]
                if len(non_empty) > len(candidate_headers):
                    candidate_headers = row
                    header_row_index = i
        
        # Fallback headers
        if not candidate_headers:
            candidate_headers = [f"Info {i+1}" for i in range(max_cols)]
            best_data_start_index = 0
        else:
            best_data_start_index = header_row_index + 1

        # Adaptive renaming for clarity
        header_str = " ".join(candidate_headers).lower()
        if max_cols == 2:
            if "adult" in header_str or "dose" in header_str:
                candidate_headers = ["Indication/Context", "Dosage Instruction"]
            elif "pediatric" in header_str:
                candidate_headers = ["Population", "Dosage Instruction"]

        structured_cards = []
        data_rows = self.rows[best_data_start_index:]

        for row in data_rows:
            if len([c for c in row if c.strip()]) < 2: continue # Skip mostly empty rows

            card = {}
            # Basic Mapping
            for i, cell in enumerate(row):
                if i < len(candidate_headers):
                    header = candidate_headers[i]
                    card[header] = cell
            
            # -------------------------------------------------------
            # HERO EXTRACTION (The "Focused" Layer)
            # -------------------------------------------------------
            # Check if any cell contains a dosage pattern
            full_text = " ".join(row)
            
            # Regex for "0.05 to 0.1 mg/kg" or "5 mg"
            # Captures: (Range Start, Range End, Unit)
            range_match = re.search(r'(\d+\.?\d*)\s*(?:to|-)\s*(\d+\.?\d*)\s*(mg/kg|mg|mcg/kg|mcg)', full_text, re.IGNORECASE)
            single_match = re.search(r'(\d+\.?\d*)\s*(mg/kg|mg|mcg/kg|mcg)', full_text, re.IGNORECASE)
            
            if range_match:
                card['hero_dose'] = f"{range_match.group(1)} - {range_match.group(2)} {range_match.group(3)}"
                card['is_weight_based'] = 'kg' in range_match.group(3)
            elif single_match:
                card['hero_dose'] = f"{single_match.group(1)} {single_match.group(2)}"
                card['is_weight_based'] = 'kg' in single_match.group(2)
            
            # Safety/Constraints extraction
            if "max" in full_text.lower() or "exceed" in full_text.lower():
                max_match = re.search(r'(?:max|exceed)\D*(\d+\.?\d*\s*(?:mg|g))', full_text, re.IGNORECASE)
                if max_match:
                    card['max_dose_constraint'] = max_match.group(1)

            structured_cards.append(card)

        return structured_cards

# ==============================================================================
# 2. ETL CONTROLLER (Fetch -> Transform -> Load)
# ==============================================================================

def fetch_and_process_drug(drug_name):
    # 1. Fetch from OpenFDA
    logging.info(f"Fetching data for: {drug_name}...")
    
    def query_openfda(query):
        try:
            r = requests.get(OPENFDA_ENDPOINT, params={'search': query, 'limit': 1})
            if r.status_code == 200:
                d = r.json()
                if 'results' in d and d['results']:
                    return d['results'][0]
            return None
        except Exception as e:
            logging.error(f"Request error: {e}")
            return None

    # Strategy 1: Exact Brand Name
    product = query_openfda(f'openfda.brand_name:"{drug_name}"')
    
    # Strategy 2: Generic Name (if brand fails)
    if not product:
        logging.info(f"Brand search failed for {drug_name}. Trying generic name...")
        # Dictionary for mapping common brands to generics if needed, or just try the name as generic
        # For this pilot, let's assume the user might pass a generic name or we guess it.
        # But here 'Dormicum' IS the brand.
        # Let's try searching for the active ingredient if we knew it.
        # Hardcoding a fallback for Dormicum -> Midazolam for this pilot.
        if drug_name.lower() == "dormicum":
            product = query_openfda('openfda.generic_name:"MIDAZOLAM"')
        elif drug_name.lower() == "augmentin":
            product = query_openfda('openfda.brand_name:"AUGMENTIN"') # US name
        elif drug_name.lower() == "panadol":
             product = query_openfda('openfda.generic_name:"ACETAMINOPHEN"') # US uses Acetaminophen 

    if not product:
        logging.warning(f"Failed to find data for {drug_name} after fallback strategies.")
        return None
        
    # 2. Extract Key Fields
    # 2. Extract Key Fields
    tables_html = product.get('dosage_and_administration_table', [])
    
    # 3. Transform (Parse Tables)
    structured_content = []
    
    try:
        for i, table_html in enumerate(tables_html):
            parser = SmartTableParser()
            parser.feed(table_html)
            cards = parser.get_structured_data()
            if cards:
                structured_content.append({
                    "section_id": i,
                    "type": "table_cards",
                    "data": cards
                })
        
        # If no tables, fallback to text splitting (Simple version for now)
        if not structured_content and 'dosage_and_administration' in product:
            text = product['dosage_and_administration'][0]
            # Simple chunking by newlines for generic text
            structured_content.append({
                "type": "text_blob",
                "data": text[:2000] + "..." # Truncate for now as placeholder
            })

        # 4. Final Object for Storage
        final_doc = {
            "drug_name": drug_name,
            "source": "OpenFDA",
            "last_updated": "2026-01-09",
            "ui_sections": structured_content
        }
        
        return final_doc

    except Exception as e:
        logging.error(f"Error processing {drug_name}: {e}")
        return None

def save_to_db(drug_name, json_obj):
    if not json_obj: return
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Compress JSON
    json_str = json.dumps(json_obj)
    compressed_data = zlib.compress(json_str.encode('utf-8'))
    
    try:
        # Update existing record or insert if logic requires (assuming updating dosage_guidelines based on generic match?)
        # For this ETL, let's update entries where user input matches or generic name matches.
        # But wait, we match by specific IDs usually.
        # For this pilot, let's look up the ID by exact matching 'ingredient' or 'drug' name strings used in previous steps.
        # Let's match by a generic LIKE query on the 'instructions' column just to find *some* row to attach this to, or use drug_name.
        
        # BETTER: Let's find rows in dosage_guidelines that match this drug name in the 'condition' or related tables.
        # Since I don't have perfect linking yet, I will use a placeholder query:
        # Update WHERE instructions LIKE %drug_name% (Risky but okay for pilot)
        # OR: Just print the success for now as we might not have 'Dormicum' explicitly in a 'brand_name' column in dosage_guidelines.
        # Actually, let's try to update based on the `target_drug` if we have it.
        
        logging.info(f"Saving structured data for {drug_name} (Size: {len(compressed_data)} bytes)...")
        
        # NOTE: In a real run, we iterate DB rows -> Get Name -> Fetch. 
        # Here we are doing: Input Name -> Fetch -> Update DB.
        # Let's try to update any row that contains the drug name in the text, to prove storage works.
        cursor.execute("UPDATE dosage_guidelines SET structured_dosage = ? WHERE instructions LIKE ?", 
                       (compressed_data, f'%{drug_name}%'))
        
        if cursor.rowcount == 0:
            logging.warning(f"Analysis: No local DB rows found containing '{drug_name}' to update. Data prepared but not linked.")
        else:
            logging.info(f"Updated {cursor.rowcount} rows in DB with structured data.")
            
        conn.commit()
    except Exception as e:
        logging.error(f"DB Error: {e}")
    finally:
        conn.close()

def run_pilot_etl():
    # List of drugs to process in this pilot
    pilot_drugs = ["Dormicum", "Panadol", "Augmentin", "Zithromax"] # Common drugs to test variety
    
    conn = sqlite3.connect(DB_PATH)
    # Check if we have these in DB to ensure we can update them
    cursor = conn.cursor()
    
    for drug in pilot_drugs:
        logging.info(f"--- Processing {drug} ---")
        doc = fetch_and_process_drug(drug)
        if doc:
            save_to_db(drug, doc)
            # Verify for user (Read back one record)
            if drug == "Dormicum":
                print(f"\n[Verification] Parsed Data Preview for {drug}:")
                print(json.dumps(doc['ui_sections'][0]['data'][:2], indent=2)) # Show first 2 cards of first table
                
    conn.close()

if __name__ == "__main__":
    run_pilot_etl()
