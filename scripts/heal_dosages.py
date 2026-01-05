#!/usr/bin/env python3
import json
import os

DOSAGE_JSON = "assets/data/dosage_guidelines.json"
DATALAKE_FILE = "production_data/production_dosages.jsonl"

def heal_dosages():
    if not os.path.exists(DOSAGE_JSON) or not os.path.exists(DATALAKE_FILE):
        print("❌ Missing source files.")
        return

    print("📖 Loading guidelines...")
    with open(DOSAGE_JSON, 'r', encoding='utf-8') as f:
        guidelines = json.load(f)

    print("📖 Building map from Data Lake (this may take a moment)...")
    lake_map = {}
    with open(DATALAKE_FILE, 'r', encoding='utf-8') as f:
        for line in f:
            if not line.strip(): continue
            try:
                rec = json.loads(line)
                setid = rec.get('dailymed_setid')
                dosage = rec.get('clinical_text', {}).get('dosage')
                if setid and dosage:
                    # Prefer longer text if multiple entries for same setid
                    if setid not in lake_map or len(dosage) > len(lake_map[setid]):
                        lake_map[setid] = dosage
            except: pass

    print(f"✅ Loaded {len(lake_map):,} unique DailyMed dosage texts.")

    heal_count = 0
    skip_count = 0
    
    print("🩹 Healing truncated records...")
    for guideline in guidelines:
        instructions = guideline.get('instructions', '')
        setid = guideline.get('dailymed_setid', '')
        
        # If truncated and has DailyMed setid (check instructions is not None)
        if instructions and instructions.endswith('...') and setid and setid != 'N/A':
            if setid in lake_map:
                full_text = lake_map[setid]
                # Compare start of string to ensure it's the right text
                # (Remove "Standard Dose: Xmg. " if it was added by the extraction script)
                clean_instructions = instructions.rstrip('.')
                if clean_instructions in full_text or full_text[:100] in instructions:
                    guideline['instructions'] = full_text
                    heal_count += 1
                else:
                    # Try a more fuzzy check if the extraction script prepended info
                    if "DOSAGE AND ADMINISTRATION" in full_text and "DOSAGE AND ADMINISTRATION" in instructions:
                        guideline['instructions'] = full_text
                        heal_count += 1
                    else:
                        skip_count += 1
            else:
                skip_count += 1

    print(f"\n✨ Healing Report:")
    print(f"🔹 Successfully healed: {heal_count:,} records.")
    print(f"🔹 Could not match: {skip_count:,} truncated records.")
    
    if heal_count > 0:
        with open(DOSAGE_JSON, 'w', encoding='utf-8') as f:
            json.dump(guidelines, f, ensure_ascii=False, separators=(',', ':'))
        print(f"💾 Saved changes to {DOSAGE_JSON}")
    else:
        print("ℹ️ No changes needed.")

if __name__ == "__main__":
    heal_dosages()
