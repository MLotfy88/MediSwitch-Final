#!/usr/bin/env python3
"""
DailyMed Parsing Pilot Run
==========================
Analyzes the first 100 active ingredients to extract structured dosage data.
Output: CSV file & Statistics Report.
"""

import sqlite3
import pandas as pd
import re
import logging
import zlib
from pathlib import Path

# Setup Logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger(__name__)

DB_PATH = '/home/adminlotfy/project/assets/database/mediswitch.db'
OUTPUT_CSV = '/home/adminlotfy/project/DailyMed_Parsing_Pilot_Report.csv'

def get_db_connection():
    return sqlite3.connect(DB_PATH)

def decompress_text(data):
    if isinstance(data, str):
        return data
    if isinstance(data, bytes):
        try:
            return zlib.decompress(data).decode('utf-8')
        except:
            return data.decode('utf-8', errors='ignore')
    return ""

def parse_dosage_text(text):
    """
    Advanced Regex Parser for DailyMed (ZLIB decoded) & WHO texts.
    """
    results = []
    text = decompress_text(text)
    if not text:
        return results
        
    text = text.replace('–', '-').replace('\n', ' ')
    
    # --- Regex Patterns ---
    
    # 0. Arabic WHO Pattern (e.g., "الجرعة اليومية المحددة (WHO DDD): 7 g")
    arabic_pattern = r'الجرعة اليومية.*?:.*?(\d+(?:\.\d+)?)\s*(g|mg|mcg|ml)'
    
    # 1. Range with Frequency
    range_freq_pattern = r'(\d+(?:\.\d+)?)\s*(?:to|-)\s*(\d+(?:\.\d+)?)\s*(mg|g|mcg|ml|tablet|cap)\b.*?(every\s+\d+\s+(?:hour|hr|day)s?|daily|bid|tid|qid)'
    
    # 2. Single Dose with Frequency
    single_freq_pattern = r'(\d+(?:\.\d+)?)\s*(mg|g|mcg|ml|tablet|cap)\b.*?(every\s+\d+\s+(?:hour|hr|day)s?|daily|bid|tid|qid)'
    
    # 3. Pediatric
    peds_pattern = r'(\d+(?:\.\d+)?)\s*(?:to|-)\s*(\d+(?:\.\d+)?)\s*(mg/kg/day|mg/kg)'

    # --- Extraction Logic ---
    found = False
    
    # Arabic Check
    for match in re.finditer(arabic_pattern, text):
        results.append({
            "Type": "WHO DDD (Arabic)",
            "Min_Dose": float(match.group(1)),
            "Max_Dose": float(match.group(1)),
            "Unit": match.group(2),
            "Frequency": "Daily",
            "Raw_Match": match.group(0)
        })
        found = True

    # Check Pediatric
    for match in re.finditer(peds_pattern, text, re.IGNORECASE):
        results.append({
            "Type": "Pediatric",
            "Min_Dose": float(match.group(1)),
            "Max_Dose": float(match.group(2)),
            "Unit": match.group(3),
            "Frequency": "See Instructions",
            "Raw_Match": match.group(0)
        })
        found = True
        
    # Check Range + Freq
    for match in re.finditer(range_freq_pattern, text, re.IGNORECASE):
        if "kg" in text[match.start():match.end()+10]: continue
        results.append({
            "Type": "Adult/General Range",
            "Min_Dose": float(match.group(1)),
            "Max_Dose": float(match.group(2)),
            "Unit": match.group(3),
            "Frequency": match.group(4),
            "Raw_Match": match.group(0)
        })
        found = True

    # Check Single + Freq
    if not found: # Only if no high-quality range matches
        for match in re.finditer(single_freq_pattern, text, re.IGNORECASE):
             if "kg" in text[match.start():match.end()+10]: continue
             results.append({
                "Type": "Adult/General Single",
                "Min_Dose": float(match.group(1)),
                "Max_Dose": float(match.group(1)), 
                "Unit": match.group(2),
                "Frequency": match.group(3),
                "Raw_Match": match.group(0)
            })
            
    return results

def run_pilot():
    conn = get_db_connection()
    cursor = conn.cursor()
    
    print(f"🚀 Starting Pilot Run on {DB_PATH}...")
    
    # 1. Get first 100 distinct ingredients
    query_ingredients = """
        SELECT DISTINCT ingredient 
        FROM med_ingredients 
        LIMIT 100;
    """
    cursor.execute(query_ingredients)
    ingredients = [row[0] for row in cursor.fetchall()]
    
    print(f"📋 Found {len(ingredients)} ingredients to process.")
    
    extracted_data = []
    stats = {
        "ingredients_processed": 0,
        "ingredients_with_data": 0,
        "total_dosage_records": 0,
        "successful_extractions": 0,
        "failed_extractions": 0
    }
    
    for ing_name in ingredients:
        stats["ingredients_processed"] += 1
        
        # 2. Find dosage guidelines for this ingredient
        # Linking: med_ingredients -> med_id -> dosage_guidelines
        query_dosages = """
            SELECT dg.id, dg.instructions, dg.condition
            FROM dosage_guidelines dg
            JOIN med_ingredients mi ON dg.med_id = mi.med_id
            WHERE mi.ingredient = ?
            AND dg.instructions IS NOT NULL
            LIMIT 5; -- Limit per ingredient to avoid noise in pilot
        """
        cursor.execute(query_dosages, (ing_name,))
        rows = cursor.fetchall()
        
        if rows:
            stats["ingredients_with_data"] += 1
        
        for row in rows:
            dg_id, instructions, condition = row
            
            # Decompress details for report display (just first 100 chars)
            display_text = decompress_text(instructions)[:100] + "..." if instructions else ""
            
            stats["total_dosage_records"] += 1
            
            # 3. Apply Parsing
            parsed_results = parse_dosage_text(instructions)
            
            if parsed_results:
                stats["successful_extractions"] += 1
                for res in parsed_results:
                    extracted_data.append({
                        "Ingredient": ing_name,
                        "Source_ID": dg_id,
                        "Condition": condition,
                        "Extracted_Type": res["Type"],
                        "Min": res["Min_Dose"],
                        "Max": res["Max_Dose"],
                        "Unit": res["Unit"],
                        "Freq": res["Frequency"],
                        "Raw_Text_Snippet": res["Raw_Match"],
                        "Full_Instructions": display_text
                    })
            else:
                stats["failed_extractions"] += 1
                extracted_data.append({
                    "Ingredient": ing_name,
                    "Source_ID": dg_id,
                    "Condition": decompress_text(condition),
                    "Extracted_Type": "FAILED",
                    "Min": None, "Max": None, "Unit": None, "Freq": None,
                    "Raw_Text_Snippet": "No Match Found",
                    "Full_Instructions": display_text
                })

    conn.close()
    
    # 4. Generate Report
    df = pd.DataFrame(extracted_data)
    df.to_csv(OUTPUT_CSV, index=False, escapechar='\\')
    
    print("\n" + "="*50)
    print("📊 PILOT RUN STATISTICS")
    print("="*50)
    print(f"Total Ingredients Tested: {stats['ingredients_processed']}")
    print(f"Ingredients with Dosage Text: {stats['ingredients_with_data']}")
    print(f"Total Guidelines Processed: {stats['total_dosage_records']}")
    print(f"✅ Successful Extractions: {stats['successful_extractions']} ({(stats['successful_extractions']/stats['total_dosage_records']*100 if stats['total_dosage_records'] else 0):.1f}%)")
    print(f"❌ Failed / Complex Text: {stats['failed_extractions']}")
    print("="*50)
    print(f"📄 Report Saved: {OUTPUT_CSV}")
    
    # Display Sample
    if not df.empty:
        success_df = df[df['Extracted_Type'] != 'FAILED']
        print("\n🏆 Top 5 Successful Extractions:")
        print(success_df[['Ingredient', 'Min', 'Max', 'Unit', 'Freq']].head(5).to_string(index=False))

if __name__ == "__main__":
    run_pilot()
