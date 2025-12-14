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
INTERACTIONS_DB = os.path.join(BASE_DIR, 'production_data', 'dailymed_interactions_clean.json')

APP_DOSAGES = os.path.join(BASE_DIR, 'assets', 'data', 'dosage_guidelines.json')
APP_INTERACTIONS = os.path.join(BASE_DIR, 'assets', 'data', 'drug_interactions.json')

def bootstrap_dosages():
    print(f"💊 Bootstrapping Dosages...")
    print(f"  Source: {HYBRID_DB}")
    print(f"  Target: {APP_DOSAGES}")
    
    if not os.path.exists(HYBRID_DB):
        print("❌ Hybrid DB not found. Run 'scripts/merge_hybrid_data.py' first.")
        return

    app_records = []
    seen_ingredients = set()

    with open(HYBRID_DB, 'r', encoding='utf-8') as f:
        for line in f:
            if not line.strip(): continue
            try:
                rec = json.loads(line)
                
                # Determine Active Ingredient Key
                # App uses 'active_ingredient' as the lookup key.
                # DailyMed data has 'dailymed_name' or 'trade_name' if active is missing.
                # Ideally, we used normalized active ingredient.
                
                # The App's 'active_ingredient' field usually matches what's in meds.csv 'active' column.
                # BUT `production_hybrid` links by `med_id`.
                # We should look up the `active` from the record if available (Scraped part)
                # or fallback to `dailymed_name`.
                
                active = rec.get('active_ingredient', '').lower()
                if not active and rec.get('dailymed_name'):
                     active = rec['dailymed_name'].lower()
                
                if not active: continue
                
                # Deduplication logic (One guideline per active ingredient?)
                # If multiple meds share an ingredient, we might get duplicates.
                # We should probably merge or pick the best one.
                # For this bootstrap, we'll pick the first one we see (or overwrite?).
                # Let's check if we already have it.
                if active in seen_ingredients:
                    continue # Skip duplicate actives for now
                
                seen_ingredients.add(active)
                
                dosage_text = rec.get('clinical_text', {}).get('dosage', '')
                std_dose = rec.get('dosages', {}).get('adult_dose_mg')
                
                new_item = {
                    "active_ingredient": active,
                    "strength": "general",
                    "standard_dose": f"{std_dose} mg" if std_dose else "See label",
                    "max_dose": None,
                    "package_label": dosage_text[:2000] if dosage_text else "Refer to package insert."
                }
                app_records.append(new_item)
                
            except Exception as e:
                pass
                
    # Parse existing to preserve manual overrides?
    # User said "Update database with New System", simplifying "Replace with new DailyMed data".
    # We will OVERWRITE for now to ensure consistency with the new pipeline.
    
    with open(APP_DOSAGES, 'w', encoding='utf-8') as f:
        json.dump(app_records, f, indent=2, ensure_ascii=False)
        
    print(f"✅ Generated {len(app_records)} dosage guidelines.")

def bootstrap_interactions():
    print(f"🔄 Bootstrapping Interactions...")
    print(f"  Source: {INTERACTIONS_DB}")
    print(f"  Target: {APP_INTERACTIONS}")
    
    if not os.path.exists(INTERACTIONS_DB):
        print("❌ Interactions DB not found. Run extraction script first.")
        return

    with open(INTERACTIONS_DB, 'r', encoding='utf-8') as f:
        source_data = json.load(f)
        
    app_records = []
    seen = set()
    
    for item in source_data:
        i1 = item.get('ingredient1', '').lower()
        i2 = item.get('ingredient2', '').lower()
        if not i1 or not i2: continue
        
        key = f"{i1}|{i2}"
        if key in seen: continue
        seen.add(key)
        
        new_item = {
            "ingredient1": i1,
            "ingredient2": i2,
            "severity": item.get('severity', 'minor'),
            "type": "dailymed_interaction",
            "effect": item.get('effect', '')[:500],
            "arabic_effect": "", 
            "recommendation": item.get('recommendation', '')[:500],
            "arabic_recommendation": "",
            "source": "DailyMed"
        }
        app_records.append(new_item)
        
    with open(APP_INTERACTIONS, 'w', encoding='utf-8') as f:
        json.dump(app_records, f, indent=2, ensure_ascii=False)
        
    print(f"✅ Generated {len(app_records)} interactions.")

if __name__ == "__main__":
    bootstrap_dosages()
    bootstrap_interactions()
