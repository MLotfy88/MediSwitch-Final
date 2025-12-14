import pandas as pd
import json
import os
import re

MEDS_CSV = 'assets/meds.csv'
DB_FILE = 'production_data/production_hybrid.jsonl'

def is_valid_concentration(conc):
    if not conc or not isinstance(conc, str): return False
    # Simple check: Contains digits and specific units
    return bool(re.search(r'\d', conc) and re.search(r'mg|ml|gm|mcg|iu|%', conc, re.I))

def main():
    print("🚀 Starting Deep Database Analysis...\n")
    
    # 1. Analyze Source (meds.csv)
    if not os.path.exists(MEDS_CSV):
        print("❌ meds.csv not found!")
        return
        
    df_meds = pd.read_csv(MEDS_CSV, dtype=str)
    total_meds = len(df_meds)
    
    # Count meds with non-empty 'active' ingredient
    # filtering out 'nan' or empty strings
    meds_with_active = df_meds[df_meds['active'].notna() & (df_meds['active'].str.strip() != '')]
    count_active_source = len(meds_with_active)
    
    print(f"📂 Source Data (meds.csv):")
    print(f"  - Total Records: {total_meds:,}")
    print(f"  - Records with 'Active Ingredient' list: {count_active_source:,} ({(count_active_source/total_meds)*100:.1f}%)")
    
    source_ids_with_active = set(meds_with_active['id'].astype(str).tolist())
    
    # 2. Analyze Generated DB (production_dosages.jsonl)
    if not os.path.exists(DB_FILE):
        print("❌ production_dosages.jsonl not found!")
        return
        
    db_records = []
    with open(DB_FILE, 'r', encoding='utf-8') as f:
        for line in f:
            if line.strip():
                db_records.append(json.loads(line))
                
    print(f"\n📂 Generated Database (production_dosages.jsonl):")
    print(f"  - Total Generated Records: {len(db_records):,}")
    
    # 3. Match & Evaluate Coverage
    # We are interested in: Of the "Source IDs with Active", how many are in DB?
    
    linked_db_map = {str(r['med_id']): r for r in db_records if r.get('med_id')}
    
    covered_ids = source_ids_with_active.intersection(linked_db_map.keys())
    coverage_count = len(covered_ids)
    
    print(f"\n🔗 Coverage Analysis (Active Ingredient Drugs):")
    print(f"  - Covered in DB: {coverage_count:,} / {count_active_source:,} (Trade Names)")
    print(f"  - Trade Coverage Rate: {(coverage_count/count_active_source)*100:.1f}%")
    
    # --- New Section: Unique Ingredient Coverage ---
    # 1. Map ID -> Normalized Ingredient
    id_to_active = {}
    for _, row in meds_with_active.iterrows():
        # Simple normalization (lowercase, strip) - ideally reuse process_datalake logic but this is sufficient for stats
        act = str(row['active']).lower().strip()
        id_to_active[str(row['id'])] = act
        
    unique_active_ingredients = set(id_to_active.values())
    count_unique_active = len(unique_active_ingredients)
    
    # 2. Find which ingredients are covered
    covered_ingredients = set()
    for mid in covered_ids:
        if mid in id_to_active:
            covered_ingredients.add(id_to_active[mid])
            
    count_covered_active = len(covered_ingredients)
    
    print(f"\n🧬 Unique Active Ingredient Coverage:")
    print(f"  - Total Unique Ingredients (Local): {count_unique_active:,}")
    print(f"  - Covered Ingredients: {count_covered_active:,}")
    print(f"  - Ingredient Coverage Rate: {(count_covered_active/count_unique_active)*100:.1f}%")
    
    # 4. Detailed Quality Check (Calculator Readiness)
    # Calculator Needs: (Pediatric Dose OR Adult Dose) AND Concentration
    
    ready_count = 0
    full_stats = {
        'has_concentration': 0,
        'has_pediatric_dose': 0,
        'has_adult_dose': 0,
        'has_all_clinical_text': 0, # rough proxy
        'missing_cols': {}
    }
    
    formatting_issues = []
    
    for mid in covered_ids:
        rec = linked_db_map[mid]
        dosages = rec.get('dosages', {}) or {}
        conc = rec.get('concentration')
        
        has_conc = is_valid_concentration(conc)
        has_ped = bool(dosages.get('dose_mg_kg'))
        has_adult = bool(dosages.get('adult_dose_mg'))
        
        if has_conc: full_stats['has_concentration'] += 1
        if has_ped: full_stats['has_pediatric_dose'] += 1
        if has_adult: full_stats['has_adult_dose'] += 1
        
        # Calculator Ready Definition
        if has_conc and (has_ped or has_adult):
            ready_count += 1
            
        # Check completeness of other fields
        clin = rec.get('clinical_text', {}) or {}
        if clin.get('interactions') and clin.get('contraindications') and clin.get('pregnancy'):
             full_stats['has_all_clinical_text'] += 1
             
        # Log missing
        if not has_conc: full_stats['missing_cols']['concentration'] = full_stats['missing_cols'].get('concentration', 0) + 1
        if not (has_ped or has_adult): full_stats['missing_cols']['any_dose'] = full_stats['missing_cols'].get('any_dose', 0) + 1
        
        # Formatting Sample Check
        if has_conc and not re.match(r'^\d+(\.\d+)?\s*[a-zA-Z%]+(\s*/\s*\d*[a-zA-Z]+)?$', conc.strip()):
             if len(formatting_issues) < 5:
                 formatting_issues.append(f"Suspicious Conc: '{conc}' (ID: {mid})")

    print(f"\n🧮 Calculator Readiness (For Covered Drugs):")
    print(f"  - Calculator Ready (Dose + Conc): {ready_count:,} ({(ready_count/coverage_count)*100:.1f}%)")
    print(f"  - Has Concentration: {full_stats['has_concentration']:,}")
    print(f"  - Has Pediatric Dose (mg/kg): {full_stats['has_pediatric_dose']:,}")
    print(f"  - Has Adult Dose (Fixed mg): {full_stats['has_adult_dose']:,}")
    print(f"  - Has Full Clinical Text (Inter/Contra/Preg): {full_stats['has_all_clinical_text']:,}")
    
    print(f"\n⚠️ Missing Data Breakdown:")
    for k, v in full_stats['missing_cols'].items():
        print(f"  - Missing {k}: {v:,}")

    if formatting_issues:
        print(f"\n🚩 Potential Formatting Issues (Sample):")
        for issue in formatting_issues:
            print(f"  - {issue}")
    else:
        print(f"\n✅ Concentration Formatting looks clean (Regex Verified).")

if __name__ == "__main__":
    main()
