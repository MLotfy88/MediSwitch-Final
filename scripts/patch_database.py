#!/usr/bin/env python3
"""
Database Patcher & App Sync
1. Merges incremental updates into Master DB (production_*.jsonl)
2. Syncs updates to App Assets (assets/data/*.json)
"""

import sys
import os
import json
import glob

# App Paths
APP_DOSAGE_FILE = "assets/data/dosage_guidelines.json"
APP_INTERACTION_FILE = "assets/data/drug_interactions_complete.json"

def patch_dosages(main_file, update_file):
    print(f"💊 Patching Dosages: {main_file} <-- {update_file}")
    
    # 1. Update Master File (Line-based JSONL)
    master_map = {}
    if os.path.exists(main_file):
        with open(main_file, 'r', encoding='utf-8') as f:
            for line in f:
                if line.strip():
                    try:
                        rec = json.loads(line)
                        if rec.get('med_id'): master_map[rec['med_id']] = rec
                    except: pass

    # Load Updates
    updates = []
    with open(update_file, 'r', encoding='utf-8') as f:
        for line in f:
            if line.strip():
                try:
                    rec = json.loads(line)
                    if rec.get('med_id'):
                        master_map[rec['med_id']] = rec
                        updates.append(rec)
                except: pass
    
    # Save Master
    with open(main_file, 'w', encoding='utf-8') as f:
        for rec in master_map.values():
            f.write(json.dumps(rec, ensure_ascii=False) + '\n')
    print(f"  ✅ Updated Master: {len(master_map)} records")

    # 2. Sync to App Assets (dosage_guidelines.json)
    if os.path.exists(APP_DOSAGE_FILE):
        print(f"  📲 Syncing to App: {APP_DOSAGE_FILE}")
        with open(APP_DOSAGE_FILE, 'r', encoding='utf-8') as f:
            app_data = json.load(f)
            
        # Index by active_ingredient
        app_map = {item['active_ingredient'].lower(): item for item in app_data}
        
        updated_count = 0
        for rec in updates:
            # Map Hybrid Schema -> App Schema
            active = rec.get('active_ingredient', '').lower()
            if not active and rec.get('dailymed_name'):
                active = rec['dailymed_name'].lower() # Fallback
            
            if active:
                dosage_text = rec.get('clinical_text', {}).get('dosage', '')
                std_dose = rec.get('dosages', {}).get('adult_dose_mg')
                
                # Upsert logic
                new_item = {
                    "active_ingredient": active,
                    "strength": rec.get('strength', "general"),
                    "standard_dose": f"{std_dose} mg" if std_dose else "See label",
                    "max_dose": rec.get('dosages', {}).get('max_dose_mg'),
                    "package_label": dosage_text[:10000], # Truncate for JSON limit (expanded)
                    "source": "DailyMed (Patch)",
                    "updated_at": rec.get('published_date', '')
                }
                
                app_map[active] = new_item
                updated_count += 1
        
        # Save App File
        with open(APP_DOSAGE_FILE, 'w', encoding='utf-8') as f:
            json.dump(list(app_map.values()), f, indent=2, ensure_ascii=False)
        print(f"  ✅ Updated App Assets: {updated_count} new/modified records")

def patch_interactions(main_file, update_file):
    print(f"🔄 Patching Interactions: {main_file} <-- {update_file}")

    # 1. Update Master File (JSON List)
    master_list = []
    if os.path.exists(main_file):
        with open(main_file, 'r', encoding='utf-8') as f:
            master_list = json.load(f)
            
    master_map = {f"{i['ingredient1']}|{i['ingredient2']}": i for i in master_list}
    
    with open(update_file, 'r', encoding='utf-8') as f:
        updates = json.load(f)
        
    for item in updates:
        key = f"{item['ingredient1']}|{item['ingredient2']}"
        master_map[key] = item
        
    with open(main_file, 'w', encoding='utf-8') as f:
        json.dump(list(master_map.values()), f, indent=2, ensure_ascii=False)
    print(f"  ✅ Updated Master: {len(master_map)} interactions")

    # 2. Sync to App Assets (drug_interactions.json)
    if os.path.exists(APP_INTERACTION_FILE):
        print(f"  📲 Syncing to App: {APP_INTERACTION_FILE}")
        with open(APP_INTERACTION_FILE, 'r', encoding='utf-8') as f:
             app_data = json.load(f)
             
        # Index
        app_map = {f"{i['ingredient1'].lower()}|{i['ingredient2'].lower()}": i for i in app_data}
        
        updated_count = 0
        for item in updates:
            i1 = item['ingredient1'].lower()
            i2 = item['ingredient2'].lower()
            key = f"{i1}|{i2}"
            
            # Map Schema
            new_item = {
                "ingredient1": i1,
                "ingredient2": i2,
                "severity": item.get('severity', 'minor'),
                "type": "dailymed_interaction",
                "effect": item.get('effect', ''),
                "arabic_effect": "", # Preserve existing? Not easy without lookup. Default to empty.
                "recommendation": item.get('recommendation', ''),
                "arabic_recommendation": "",
                "source": "DailyMed"
            }
            
            # Smart Upsert: Preserve arabic if exists in old
            if key in app_map:
                old = app_map[key]
                if old.get('arabic_effect'): new_item['arabic_effect'] = old['arabic_effect']
                if old.get('arabic_recommendation'): new_item['arabic_recommendation'] = old['arabic_recommendation']
            
            app_map[key] = new_item
            updated_count += 1
            
        with open(APP_INTERACTION_FILE, 'w', encoding='utf-8') as f:
            json.dump(list(app_map.values()), f, indent=2, ensure_ascii=False)
        print(f"  ✅ Updated App Assets: {updated_count} interactions")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 patch_database.py <type> <main_file> <update_file_pattern>")
        sys.exit(1)
        
    mode = sys.argv[1]
    main = sys.argv[2]
    pattern = sys.argv[3]
    
    files = glob.glob(pattern)
    for f in files:
        if mode == 'dosages': patch_dosages(main, f)
        elif mode == 'interactions': patch_interactions(main, f)
