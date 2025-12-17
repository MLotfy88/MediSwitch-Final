#!/usr/bin/env python3
"""
Bootstrap App Data
Converts the master 'Production' databases into the App's runtime JSON assets.
Source:
- production_data/production_hybrid.jsonl (Dosages)
- production_data/dailymed_interactions.json (Interactions)
Target:
- assets/data/dosage_guidelines.json
- assets/data/drug_interactions.json
"""

import json
import os
import sys

# Paths
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HYBRID_DB = os.path.join(BASE_DIR, 'production_data', 'production_hybrid.jsonl')
INTERACTIONS_DB = os.path.join(BASE_DIR, 'production_data', 'dailymed_interactions.json')

APP_DOSAGES = os.path.join(BASE_DIR, 'assets', 'data', 'dosage_guidelines.json')
APP_INTERACTIONS = os.path.join(BASE_DIR, 'assets', 'data', 'drug_interactions.json')

def bootstrap_dosages():
    print(f"💊 Bootstrapping Dosages...")
    print(f"  Source: {HYBRID_DB}")
    print(f"  Target: {APP_DOSAGES}")
    
    if not os.path.exists(HYBRID_DB):
        print("❌ Hybrid DB not found. Run 'scripts/merge_hybrid_data.py' first.")
        return

    final_records = {"dosage_guidelines": []}
    
    with open(HYBRID_DB, 'r', encoding='utf-8') as f:
        for line in f:
            if not line.strip(): continue
            try:
                rec = json.loads(line)
                
                # LINKAGE 1: Med ID (The Hub)
                med_id = rec.get('med_id')
                if not med_id: continue
                
                # Extract Structured Data
                dosages_data = rec.get('dosages', {})
                clinical_text = rec.get('clinical_text', {}).get('dosage', '')
                
                std_dose = dosages_data.get('adult_dose_mg')
                freq = dosages_data.get('frequency_hours', 24)
                
                # LINKAGE 2: DailyMed Source ID (The external link)
                dailymed_setid = rec.get('set_id', 'N/A')
                
                new_item = {
                    "med_id": int(med_id),
                    "dailymed_setid": dailymed_setid, # Link back to DailyMed Source
                    "min_dose": std_dose if std_dose else 0,
                    "max_dose": dosages_data.get('max_dose_mg'),
                    "frequency": freq,
                    "duration": 7,
                    "instructions": f"Standard Dose: {std_dose}mg. {clinical_text[:500]}..." if std_dose else (clinical_text[:500] if clinical_text else "See package insert"),
                    "condition": "General",
                    "source": rec.get('data_source', 'DailyMed'),
                    "is_pediatric": dosages_data.get('is_pediatric', False)
                }
                final_records["dosage_guidelines"].append(new_item)
                
            except Exception as e:
                pass
    
    with open(APP_DOSAGES, 'w', encoding='utf-8') as f:
        json.dump(final_records, f, indent=2, ensure_ascii=False)
        
    print(f"✅ Generated {len(final_records['dosage_guidelines'])} dosage guidelines (Linked: MedID <-> DailyMedID).")

def bootstrap_interactions():
    print(f"🔄 Bootstrapping Interactions...")
    print(f"  Source: {INTERACTIONS_DB}")
    print(f"  Target: {APP_INTERACTIONS}")
    
    if not os.path.exists(INTERACTIONS_DB):
        print("❌ Interactions DB not found. Run extraction script first.")
        return

    # Load Interaction Data (Keyed by Ingredient)
    try:
        with open(INTERACTIONS_DB, 'r', encoding='utf-8') as f:
            interactions_map = json.load(f) # { "drug_X": [ { "name": "drug_Y", "severity": "High", "dailymed_id": "..." } ] }
    except Exception as e:
        print(f"❌ Error reading interactions DB: {e}")
        return

    # Load Meds CSV to map Active Ingredient -> Med ID
    import pandas as pd
    try:
        df = pd.read_csv(os.path.join(BASE_DIR, 'assets', 'meds.csv'))
        # Create map: Active (lowercase) -> List of IDs
        active_to_ids = {}
        for _, row in df.iterrows():
            active = str(row.get('active', '')).lower().strip()
            # Basic cleanup to match interaction keys
            active = active.split('+')[0].strip() # Handle combo drugs (take first ingredient for now)
            
            mid = row.get('id')
            if active and mid:
                if active not in active_to_ids:
                     active_to_ids[active] = []
                active_to_ids[active].append(int(mid))
    except Exception as e:
        print(f"❌ Error reading meds.csv for mapping: {e}")
        return

    final_interactions = {"interactions": []}
    
    print("🔄 Linking Interactions to Local Med IDs...")
    matched_count = 0
    
    for active_key, med_ids in active_to_ids.items():
        # Look up interactions for this ingredient
        if active_key in interactions_map:
            inter_list = interactions_map[active_key]
            
            for mid in med_ids:
                for inter in inter_list:
                    new_item = {
                        "med_id": mid, # LINKAGE 1: Our App's Drug ID
                        "interaction_drug_name": inter.get('name'),
                        "interaction_dailymed_id": inter.get('rxcui') or inter.get('unii') or 'N/A', # LINKAGE 2: External Drug ID
                        "severity": inter.get('severity', 'Moderate'),
                        "description": inter.get('description', 'Potential interaction identified.'),
                        "source": "DailyMed"
                    }
                    final_interactions["interactions"].append(new_item)
                    matched_count += 1
    
    with open(APP_INTERACTIONS, 'w', encoding='utf-8') as f:
        json.dump(final_interactions, f, indent=2, ensure_ascii=False)

    print(f"✅ Generated {matched_count} interactions linked by ID (Networked).")

if __name__ == "__main__":
    bootstrap_dosages()
    bootstrap_interactions()
