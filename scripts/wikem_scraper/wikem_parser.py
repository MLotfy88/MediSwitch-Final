
import re
import json
import zlib
import sqlite3
import pandas as pd
from pathlib import Path

# Configuration
DB_PATH = Path("assets/database/mediswitch.db")
WIKEM_DIR = Path("scripts/wikem_scraper/scraped_data/drugs")
MATCH_REPORT = Path("scripts/wikem_scraper/wikem_matches.csv")

# Regex Patterns
DOSE_PATTERN = re.compile(
    r'(\d+(?:\.\d+)?)\s*(?:-|to)?\s*(\d+(?:\.\d+)?)?\s*(mg/kg|mcg/kg|g/kg|mg|mcg|g|units/kg|units|mEq/kg|mEq)',
    re.IGNORECASE
)

ROUTE_PATTERN = re.compile(r'\b(PO|IV|IM|SC|IO|PR|SL|IN)\b', re.IGNORECASE)

FREQ_PATTERN = {
    # Pattern : (Frequency, Interval Period)
    r'\bq(\d+)h\b': (1, 'hour'), # q4h matched dynamically if we cared about interval, but simplistically:
    r'\bdaily\b': 1,
    r'\bqd\b': 1,
    r'\bbid\b': 2,
    r'\bq12h\b': 2,
    r'\btid\b': 3,
    r'\bq8h\b': 3,
    r'\bqid\b': 4,
    r'\bq6h\b': 4,
    r'\bq4h\b': 6,
}

def clean_text(text):
    if not text: return ""
    return re.sub(r'\s+', ' ', text).strip()

def parse_dosage_line(text, section_name=""):
    """
    Extracts structured data from a single line of text.
    """
    guideline = {
        "min_dose": None,
        "max_dose": None,
        "dose_unit": None,
        "frequency": None,
        "route": None,
        "patient_category": "Adult", # Default
        "instructions": clean_text(text)
    }

    # Detect Pediatric
    if "pediatric" in section_name.lower() or "child" in text.lower():
        guideline["patient_category"] = "Pediatric"
    
    # Extract Dose (Value + Unit)
    dose_match = DOSE_PATTERN.search(text)
    if dose_match:
        val1 = float(dose_match.group(1))
        val2 = float(dose_match.group(2)) if dose_match.group(2) else None
        unit = dose_match.group(3)
        
        guideline["dose_unit"] = unit
        guideline["min_dose"] = val1
        guideline["max_dose"] = val2 if val2 else val1 # If single value, min=max

    # Extract Route
    route_match = ROUTE_PATTERN.search(text)
    if route_match:
        guideline["route"] = route_match.group(1).upper()

    # Extract Frequency
    text_lower = text.lower()
    for pattern, freq_val in FREQ_PATTERN.items():
        if re.search(pattern, text_lower):
            if isinstance(freq_val, tuple):
                 # Handle dynamic regex logic if needed later
                 pass
            else:
                 guideline["frequency"] = freq_val
            break
            
    return guideline

def process_file(json_path, med_id):
    """
    Reads JSON, finds relevant dosage sections, parses them, 
    and returns a list of guideline objects + the compressed blob.
    """
    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # 1. Compress Blob
    json_str = json.dumps(data)
    compressed_blob = zlib.compress(json_str.encode('utf-8'))

    # Parse Sections
    parsed_guidelines = []
    
    sections = data.get("sections", {})
    
    # Target specific sections likely to have dosage
    target_keywords = ["dosage", "dosing", "treatment", "management", "administration", "pediatric"]
    
    def process_section(title, content):
        # 1. Look in the main text of this section
        if "text" in content and content["text"]:
            lines = content["text"].split('\n')
            for line in lines:
                if DOSE_PATTERN.search(line):
                    guideline = parse_dosage_line(line, title)
                    guideline["source_section"] = title
                    parsed_guidelines.append(guideline)
        
        # 2. Recursively look into subsections
        subsections = content.get("subsections", {})
        for sub_title, sub_content in subsections.items():
            process_section(f"{title} > {sub_title}", sub_content)

    # Intro
    if "Intro" in sections:
        process_section("Intro", sections["Intro"])
    
    # Process all sections that match keywords
    for title, content in sections.items():
        if any(kw in title.lower() for kw in target_keywords):
           process_section(title, content)

    return parsed_guidelines, compressed_blob

def run_pipeline():
    # 1. Connect DB
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # 2. Load Map
    df = pd.read_csv(MATCH_REPORT)
    # Filter only Exact + Fuzzy matches
    valid_matches = df[df["Match_Type"] != "None"]
    
    print(f"🚀 Starting Extraction for {len(valid_matches)} drugs...")
    
    processed_count = 0
    inserted_count = 0
    
    for _, row in valid_matches.iterrows():
        file_path = row["File_Path"]
        ing_name = row["DB_Ingredient_Name"]
        
        # Get Med ID
        cursor.execute("SELECT med_id FROM med_ingredients WHERE ingredient = ?", (ing_name,))
        res = cursor.fetchone()
        if not res:
            continue
        med_id = res[0]
        
        try:
            guidelines, blob = process_file(file_path, med_id)
            
            # A. Strategy: Insert distinct parsed lines
            # If no parsed lines found, Insert at least ONE row with just the BLOB
            
            if not guidelines:
                # Fallback: Insert Empty Structured Row just to hold the Blob
                cursor.execute("""
                    INSERT INTO dosage_guidelines (med_id, source, wikem_json_blob, wikem_instructions)
                    VALUES (?, ?, ?, ?)
                """, (med_id, "WikEM", blob, "See detailed card for dosage information."))
                inserted_count += 1
            else:
                for gl in guidelines:
                    cursor.execute("""
                        INSERT INTO dosage_guidelines (
                            med_id, source, wikem_json_blob,
                            wikem_min_dose, wikem_max_dose, wikem_dose_unit, wikem_frequency, wikem_route, 
                            wikem_patient_category, wikem_instructions
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """, (
                        med_id, "WikEM", blob,
                        gl["min_dose"], gl["max_dose"], gl["dose_unit"], 
                        gl["frequency"], gl["route"], gl["patient_category"], gl["instructions"]
                    ))
                    inserted_count += 1
            
            processed_count += 1
            
            if processed_count % 50 == 0:
                print(f"⏳ Processed {processed_count} drugs...")
                conn.commit()
                
        except Exception as e:
            print(f"❌ Error processing {ing_name}: {e}")

    conn.commit()
    conn.close()
    
    print("=" * 40)
    print("✅ EXTRACTION COMPLETE")
    print(f"💊 Drugs Processed: {processed_count}")
    print(f"💉 Rows Inserted:   {inserted_count}")
    print("=" * 40)

if __name__ == "__main__":
    run_pipeline()
