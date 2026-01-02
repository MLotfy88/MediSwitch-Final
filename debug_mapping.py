
import sqlite3
import re

DB_PATH = "mediswitch.db"
DDINTER_DB = "assets/external_research_data/ddinter_complete.db"

def clean_name(name):
    if not name: return ""
    name = re.sub(r'\(.*?\)', '', name)
    salts = ['tromethamine', 'sodium', 'potassium', 'hcl', 'hydrochloride', 'maleate', 'sulfate', 'phosphate', 'fumarate', 'citrate', 'calcium', 'magnesium', 'acetate', 'topical', 'systemic']
    name = name.lower().strip()
    for salt in salts:
        name = name.replace(f" {salt}", "").replace(f"{salt} ", "").strip()
    return name

def debug_mapping():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute("SELECT id, active FROM drugs WHERE active IS NOT NULL")
    rows = c.fetchall()
    conn.close()
    
    local_drug_map = {}
    for local_id, active in rows:
        cleaned = clean_name(active)
        if not cleaned: continue
        if cleaned not in local_drug_map:
            local_drug_map[cleaned] = []
        local_drug_map[cleaned].append(local_id)
        
    print(f"Total mapped ingredients: {len(local_drug_map)}")
    
    # Check for huge groupings
    for k, v in local_drug_map.items():
        if len(v) > 500:
            print(f"⚠️ High count ingredient: '{k}' -> {len(v)} drugs")
            
    # Simulate problematic DDInter lookups
    conn_dd = sqlite3.connect(DDINTER_DB)
    c_dd = conn_dd.cursor()
    c_dd.execute("SELECT drug_name FROM drug_disease_interactions")
    dd_drugs = c_dd.fetchall()
    conn_dd.close()
    
    print("\nChecking fuzzy matches...")
    count = 0
    for r in dd_drugs[:200]: # Check first 200
        drug_name = r[0]
        cleaned_dd = clean_name(drug_name)
        
        matched_ids = local_drug_map.get(cleaned_dd, [])
        if not matched_ids:
            # Fuzzy match simulation
            for local_active_clean, ids in local_drug_map.items():
                if len(local_active_clean) < 3: continue # Skip tiny local names
                if cleaned_dd in local_active_clean or local_active_clean in cleaned_dd:
                    matched_ids = ids
                    # print(f"  Fuzzy matched: '{cleaned_dd}' with '{local_active_clean}' -> {len(ids)} ids")
                    if len(ids) > 100:
                         print(f"  Available fuzzy match: '{cleaned_dd}' <-> '{local_active_clean}' ({len(ids)} IDs)")
                    break
        
        if len(matched_ids) > 1000:
             print(f"🚨 BOOM: '{drug_name}' mapped to {len(matched_ids)} IDs")
             count += 1
    
    if count == 0:
        print("No immediate huge explosions found in sample. Need deeper check.")

if __name__ == "__main__":
    debug_mapping()
