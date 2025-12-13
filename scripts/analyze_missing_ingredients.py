import pandas as pd
import json
import os
import re
from collections import Counter

MEDS_CSV = 'assets/meds.csv'
DB_FILE = 'production_data/production_dosages.jsonl'

def clean_active(name):
    if not isinstance(name, str): return ""
    # Remove + and , and sort
    # "ibuprofen + pseudoephedrine" -> "ibuprofen pseudoephedrine"
    normalized = re.sub(r'[+,]', ' ', name.lower())
    parts = sorted(normalized.split())
    return " ".join(parts)

def main():
    print("🕵️ Analyzing Missing Ingredients Gap...")
    
    # 1. Load All Actives from Meds.csv
    if not os.path.exists(MEDS_CSV):
        print("❌ meds.csv not found")
        return
        
    df = pd.read_csv(MEDS_CSV, dtype=str)
    
    # 2. Key Check: Which ones are linked?
    if not os.path.exists(DB_FILE):
        print("❌ production_dosages.jsonl not found")
        return
        
    linked_med_ids = set()
    with open(DB_FILE, 'r') as f:
        for line in f:
            if line.strip():
                try:
                    rec = json.loads(line)
                    if rec.get('med_id'):
                        linked_med_ids.add(str(rec['med_id']))
                except: pass
                
    # 3. Correlate
    total_actives_count = 0
    linked_actives = []
    missing_actives = []
    
    for _, row in df.iterrows():
        mid = str(row.get('id', ''))
        act = str(row.get('active', ''))
        
        if act and act.lower() != 'nan':
            clean = clean_active(act)
            if not clean: continue
            
            total_actives_count += 1
            
            if mid in linked_med_ids:
                linked_actives.append(clean)
            else:
                missing_actives.append(clean)
                
    print(f"📊 Source Status:")
    print(f"  - Total Records with Active: {total_actives_count:,}")
    
    print(f"\n🔗 Linkage Status:")
    print(f"  - Linked Active Records: {len(linked_actives):,} ({(len(linked_actives)/total_actives_count)*100:.1f}%)")
    print(f"  - Missing Active Records: {len(missing_actives):,}")
    
    # 4. Top Missing Ingredients
    missing_counter = Counter(missing_actives)
    print(f"\n📉 Top 50 Missing Ingredients (High Impact Targets):")
    for ing, count in missing_counter.most_common(50):
        print(f"  - [{count}] '{ing}'")
        
if __name__ == "__main__":
    main()
