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
    print(f"🔄 Bootstrapping Interactions (Relational Mode)...")
    print(f"  Source: {INTERACTIONS_DB}")
    
    OUTPUT_DIR = os.path.join(BASE_DIR, 'assets', 'data', 'interactions')
    if os.path.exists(OUTPUT_DIR):
        import shutil
        shutil.rmtree(OUTPUT_DIR)
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    # 1. Process Rules (The Knowledge Base)
    if not os.path.exists(INTERACTIONS_DB):
        print("❌ Interactions DB not found.")
        return

    try:
        with open(INTERACTIONS_DB, 'r', encoding='utf-8') as f:
            rules_list = json.load(f)
            
        print(f"  📚 Loaded {len(rules_list)} interaction rules.")
        
        # Save Rules (Chunked for Offline/Git)
        CHUNK_SIZE = 10000
        total_rules = len(rules_list)
        num_chunks = (total_rules // CHUNK_SIZE) + 1
        
        print(f"  📦 Splitting Rules into {num_chunks} chunks...")
        for i in range(0, total_rules, CHUNK_SIZE):
            chunk = rules_list[i:i + CHUNK_SIZE]
            chunk_num = (i // CHUNK_SIZE) + 1
            fname = f"rules_part_{chunk_num:03d}.json"
            
            with open(os.path.join(OUTPUT_DIR, fname), 'w', encoding='utf-8') as f:
                json.dump({"meta": {"type": "rules", "chunk": chunk_num, "total": total_rules}, "data": chunk}, f, separators=(',', ':'), ensure_ascii=False)
                
    except Exception as e:
        print(f"❌ Error processing rules: {e}")
        return

    # 2. Process Ingredients Index (The Map)
    print("  🗺️  Generating Med-Ingredient Index...")
    import pandas as pd
    try:
        df = pd.read_csv(os.path.join(BASE_DIR, 'assets', 'meds.csv'))
        med_ingredients_list = []
        
        for _, row in df.iterrows():
            mid = row.get('id')
            active = str(row.get('active', '')).strip()
            
            if not mid or not active or str(mid).lower() == 'nan': continue
            
            # Smart Split (semicolon, plus, comma handling)
            # Logic: match scraper's splitting if possible
            import re
            parts = re.split(r'[+;,]', active)
            cleaned_parts = [p.strip().lower() for p in parts if p.strip()]
            
            if cleaned_parts:
                med_ingredients_list.append({
                    "med_id": int(mid),
                    "ingredients": cleaned_parts
                })
                
        print(f"  ✅ Mapped ingredients for {len(med_ingredients_list)} drugs.")
        
        # Save Ingredients Map (Chunked)
        total_meds = len(med_ingredients_list)
        
        # Sort by ID
        med_ingredients_list.sort(key=lambda x: x['med_id'])
        
        CHUNK_SIZE_MAP = 20000
        num_chunks_map = (total_meds // CHUNK_SIZE_MAP) + 1
        
        for i in range(0, total_meds, CHUNK_SIZE_MAP):
            chunk = med_ingredients_list[i:i + CHUNK_SIZE_MAP]
            chunk_num = (i // CHUNK_SIZE_MAP) + 1
            fname = f"ingredients_part_{chunk_num:03d}.json"
            
            with open(os.path.join(OUTPUT_DIR, fname), 'w', encoding='utf-8') as f:
                json.dump({"meta": {"type": "ingredients", "chunk": chunk_num, "total": total_meds}, "data": chunk}, f, separators=(',', ':'), ensure_ascii=False)

    except Exception as e:
        print(f"❌ Error generating index: {e}")
        return

    print(f"✅ Relational Assets Generated in {OUTPUT_DIR}")

if __name__ == "__main__":
    bootstrap_dosages()
    bootstrap_interactions()
