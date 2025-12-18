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

    # Load Interaction Data (List of objects)
    try:
        with open(INTERACTIONS_DB, 'r', encoding='utf-8') as f:
            interactions_list = json.load(f) # List of {ingredient1, ingredient2, severity, ...}
            
        if not isinstance(interactions_list, list):
             print(f"❌ Error: Expected list in interactions DB, got {type(interactions_list)}")
             return
             
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
            # Handle combo drugs: "a + b" -> ["a", "b"] ?? 
            # For now, let's just index the whole string AND split parts if needed?
            # Sticking to simple split by '+' for now as per previous logic, but improved.
            parts = [p.strip() for p in active.split('+')]
            
            mid = row.get('id')
            if mid:
                 for p in parts:
                     if not p: continue
                     if p not in active_to_ids:
                         active_to_ids[p] = []
                     active_to_ids[p].append(int(mid))
                     
    except Exception as e:
        print(f"❌ Error reading meds.csv for mapping: {e}")
        return

    # Build Index from Interactions List: Ingredient -> [Interaction Objects]
    # We need to look up by OUR drug's ingredient, and find the OTHER drug.
    # Entry: {i1: "A", i2: "B"}
    # If our drug is "A", interaction is with "B".
    # If our drug is "B", interaction is with "A".
    
    interaction_index = {} # ingredient -> list of {name, severity, ...}
    
    for item in interactions_list:
        i1 = item.get('ingredient1', '').lower().strip()
        i2 = item.get('ingredient2', '').lower().strip()
        
        if not i1 or not i2: continue
        
        # Forward: Key = i1, Value = i2
        if i1 not in interaction_index: interaction_index[i1] = []
        interaction_index[i1].append({
            "name": item.get('ingredient2'), # Display name (original case)
            "rxcui": item.get('rxcui'), # This usually belongs to the PAIR or specific drug? 
                                        # In this context, simpler to just list the other drug's name/severity
            "severity": item.get('severity'),
            "description": item.get('effect') or item.get('description'),
            "source": item.get('source')
        })
        
        # Reverse: Key = i2, Value = i1
        if i2 not in interaction_index: interaction_index[i2] = []
        interaction_index[i2].append({
            "name": item.get('ingredient1'),
            "rxcui": item.get('rxcui'),
            "severity": item.get('severity'),
            "description": item.get('effect') or item.get('description'),
            "source": item.get('source')
        })

    final_interactions = {"interactions": []}
    
    print("🔄 Linking Interactions to Local Med IDs...")
    matched_count = 0
    
    for active_key, med_ids in active_to_ids.items():
        # Look up interactions for this ingredient in our built index
        if active_key in interaction_index:
            inter_list = interaction_index[active_key]
            
            for mid in med_ids:
                for inter in inter_list:
                    new_item = {
                        "med_id": mid, # LINKAGE 1: Our App's Drug ID
                        "interaction_drug_name": inter.get('name', 'Unknown'),
                        "interaction_dailymed_id": 'N/A', # Not strictly available per partner in this simple schema, but okay.
                        "severity": inter.get('severity', 'Moderate'),
                        "description": inter.get('description', 'Potential interaction identified.'),
                        "source": inter.get('source', 'DailyMed')
                    }
                    final_interactions["interactions"].append(new_item)
                    matched_count += 1
    
    # Sort for consistency
    final_interactions["interactions"].sort(key=lambda x: x['med_id'])
    
    # Split into chunks (Github limit ~100MB, so ~50MB chunks is safe)
    # Approx record size ~500 bytes -> 100,000 records = 50MB
    CHUNK_SIZE = 50000 
    
    interactions_list = final_interactions["interactions"]
    total_records = len(interactions_list)
    
    # Output Directory
    OUTPUT_DIR = os.path.join(BASE_DIR, 'assets', 'data', 'interactions')
    if os.path.exists(OUTPUT_DIR):
        import shutil
        shutil.rmtree(OUTPUT_DIR) # Clean old run
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    # Clean old monolithic file if exists
    if os.path.exists(APP_INTERACTIONS):
        os.remove(APP_INTERACTIONS)
        
    num_chunks = (total_records // CHUNK_SIZE) + 1
    print(f"📦 Splitting {total_records:,} interactions into {num_chunks} chunk files (Target: {OUTPUT_DIR})...")
    
    for i in range(0, total_records, CHUNK_SIZE):
        chunk = interactions_list[i:i + CHUNK_SIZE]
        chunk_index = (i // CHUNK_SIZE) + 1
        
        filename = f"interactions_part_{chunk_index:03d}.json"
        filepath = os.path.join(OUTPUT_DIR, filename)
        
        chunk_data = {
            "meta": {
                "chunk_index": chunk_index,
                "total_chunks": num_chunks,
                "total_records": total_records
            },
            "interactions": chunk
        }
        
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(chunk_data, f, indent=None, separators=(',', ':'), ensure_ascii=False) # Minified for space
            
        print(f"  -> {filename} ({len(chunk):,} records)")

    print(f"✅ Generated {matched_count} interactions linked by ID (Networked).")

if __name__ == "__main__":
    bootstrap_dosages()
    bootstrap_interactions()
