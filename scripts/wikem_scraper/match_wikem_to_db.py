
import sqlite3
import json
import csv
from pathlib import Path
from difflib import get_close_matches

# Configuration
DB_PATH = Path("assets/database/mediswitch.db")
WIKEM_DIR = Path("scripts/wikem_scraper/scraped_data/drugs")
OUTPUT_CSV = Path("scripts/wikem_scraper/wikem_matches.csv")

def match_data():
    if not DB_PATH.exists():
        print(f"❌ Database not found at {DB_PATH}")
        return

    # 1. Load Ingredients from DB
    print("🔌 Connecting to database...")
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Adjust column name based on schema (assuming 'name' or 'ingredient_name')
    # We will fetch the schema first or assume 'name' based on typical structure
    # For now, I'll select all and inspect first row or just fetch names if I know column
    try:
        cursor.execute("SELECT name FROM med_ingredients")
        db_ingredients = [row[0] for row in cursor.fetchall() if row[0]]
    except sqlite3.OperationalError:
        # Fallback if 'name' is not the column
        print("⚠️ Column 'name' not found. Fetching schema...")
        cursor.execute("PRAGMA table_info(med_ingredients)")
        columns = [col[1] for col in cursor.fetchall()]
        print(f"Columns: {columns}")
        target_col = next((c for c in columns if 'name' in c.lower()), columns[1])
        print(f"Using column: {target_col}")
        cursor.execute(f"SELECT {target_col} FROM med_ingredients")
        db_ingredients = [row[0] for row in cursor.fetchall() if row[0]]

    conn.close()
    print(f"✅ Loaded {len(db_ingredients)} ingredients from DB.")

    # 2. Load Scraped Drugs
    scraped_files = list(WIKEM_DIR.glob("*.json"))
    scraped_names = [f.stem.replace('_', ' ') for f in scraped_files]
    print(f"✅ Loaded {len(scraped_names)} scraped drugs from WikEM.")

    # 3. Matching Logic (Optimized)
    print("🔍 Performing Fuzzy Matching (Optimized)...")
    
    matches = []
    
    # Pre-index DB ingredients by first letter for speed
    db_index = {}
    for name in db_ingredients:
        key = name[0].lower() if name else ""
        if key not in db_index:
            db_index[key] = []
        db_index[key].append(name)
        
    db_ingredients_lower = {name.lower(): name for name in db_ingredients}
    
    for i, file_path in enumerate(scraped_files):
        wikem_name = file_path.stem.replace('_', ' ')
        wikem_name_lower = wikem_name.lower()
        
        match_type = "None"
        db_match = ""
        
        # A. Exact Match
        if wikem_name_lower in db_ingredients_lower:
            match_type = "Exact"
            db_match = db_ingredients_lower[wikem_name_lower]
        
        # B. Fuzzy Match (Optimized: Only check same starting letter)
        else:
            first_char = wikem_name_lower[0] if wikem_name_lower else ""
            candidates_pool = db_index.get(first_char, [])
            
            # If no candidates with same letter, maybe check similar letters? 
            # (Skipping for speed, rigorous enough for this use case)
            if len(candidates_pool) > 0:
                candidates = get_close_matches(wikem_name, candidates_pool, n=1, cutoff=0.85)
                if candidates:
                    match_type = "Fuzzy (>0.85)"
                    db_match = candidates[0]
        
        matches.append({
            "WikEM_Name": wikem_name,
            "DB_Ingredient_Name": db_match,
            "Match_Type": match_type,
            "File_Path": str(file_path)
        })
        
        if i % 500 == 0:
            print(f"Processed {i}/{len(scraped_files)}...")

    # 4. Export CSV
    print(f"💾 Saving report to {OUTPUT_CSV}...")
    with open(OUTPUT_CSV, 'w', newline='', encoding='utf-8') as csvfile:
        fieldnames = ["WikEM_Name", "DB_Ingredient_Name", "Match_Type", "File_Path"]
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        
        writer.writeheader()
        for row in matches:
            writer.writerow(row)
            
    # Summary
    exact_count = sum(1 for m in matches if m["Match_Type"] == "Exact")
    fuzzy_count = sum(1 for m in matches if "Fuzzy" in m["Match_Type"])
    miss_count = len(matches) - exact_count - fuzzy_count
    
    print("\n📊 MATCHING RESULTS:")
    print(f"✅ Exact Matches: {exact_count}")
    print(f"⚠️ Fuzzy Matches: {fuzzy_count}")
    print(f"❌ No Match:      {miss_count}")
    print(f"📄 Report File:   {OUTPUT_CSV}")

if __name__ == "__main__":
    match_data()
