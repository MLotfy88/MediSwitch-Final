#!/usr/bin/env python3
"""
Heal Truncated Dosages Script
Restores truncated instructions (ending with '...') using the full text from the Data Lake.
"""
import json
import os
import gzip
import sys

DOSAGE_JSON = "assets/data/dosage_guidelines.json.gz"
DATALAKE_FILE = "production_data/production_dosages.jsonl.gz"

def heal_dosages():
    if not os.path.exists(DOSAGE_JSON):
        print(f"❌ Missing source file: {DOSAGE_JSON}")
        return

    print("📖 Loading guidelines...")
    # Initialize heal_count
    heal_count = 0 
    
    try:
        with gzip.open(DOSAGE_JSON, 'rt', encoding='utf-8') as f:
            guidelines = json.load(f)
    except Exception as e:
        print(f"❌ Error loading guidelines: {e}")
        return

    # Check if we have truncated records
    truncated_candidates = [
        g for g in guidelines 
        if (g.get('instructions') or '').endswith('...') and g.get('dailymed_setid')
    ]
    
    if not truncated_candidates:
        print("✅ No truncated records found needed healing.")
        return

    print(f"🔍 Found {len(truncated_candidates)} truncated records. Building Data Lake map...")

    DATALAKE_FILE = "production_data/production_dosages.jsonl.gz"
    if not os.path.exists(DATALAKE_FILE):
        print(f"⚠️ Data Lake file not found: {DATALAKE_FILE}. Cannot heal records.")
        return

    # Build Map from Data Lake
    lake_map = {}
    try:
        with gzip.open(DATALAKE_FILE, 'rt', encoding='utf-8') as f:
            for line in f:
                if not line.strip(): continue
                try:
                    rec = json.loads(line)
                    setid = rec.get('dailymed_setid')
                    dosage = rec.get('clinical_text', {}).get('dosage')
                    if setid and dosage:
                        # Prefer longer text if multiple entries
                        if setid not in lake_map or len(dosage) > len(lake_map[setid]):
                            lake_map[setid] = dosage
                except: pass
    except Exception as e:
         print(f"⚠️ Error reading Data Lake: {e}")
         return

    print(f"📚 Loaded {len(lake_map):,} full records from Data Lake.")

    # Apply Healing
    for g in guidelines:
        if (g.get('instructions') or '').endswith('...'):
            setid = g.get('dailymed_setid')
            if setid in lake_map:
                full_text = lake_map[setid]
                # Only update if full text is actually longer and valid
                if len(full_text) > len(g['instructions']):
                    g['instructions'] = full_text
                    heal_count += 1

    print(f"🩹 Healed {heal_count:,} records.")

    if heal_count > 0:
        with gzip.open(DOSAGE_JSON, 'wt', encoding='utf-8') as f:
            json.dump(guidelines, f, ensure_ascii=False, separators=(',', ':'))
        print(f"💾 Saved changes to {DOSAGE_JSON}")
    else:
        print("✨ No changes needed.")

if __name__ == '__main__':
    heal_dosages()
