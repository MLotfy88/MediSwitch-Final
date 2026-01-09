import gzip
import json
import csv
import sys
import os

# Paths
DOSAGE_PATH = 'assets/data/dosage_guidelines.json.gz'
MEDS_PATH = 'assets/meds.csv'

def find_best_drug():
    print("Loading medicines mapping...")
    med_map = {}
    try:
        with open(MEDS_PATH, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                try:
                    med_id = int(row['id'])
                    med_map[med_id] = row['trade_name']
                except ValueError:
                    continue
    except Exception as e:
        print(f"Error loading meds.csv: {e}")
        return

    print("Loading dosage guidelines...")
    dosages = []
    try:
        with gzip.open(DOSAGE_PATH, 'rt', encoding='utf-8') as f:
            dosages = json.load(f)
    except Exception as e:
        print(f"Error loading dosage_guidelines.json.gz: {e}")
        try:
             with open('assets/data/dosage_guidelines.json', 'r', encoding='utf-8') as f:
                dosages = json.load(f)
        except:
            return

    best_score = -1
    best_entry = None
    
    fields_to_check = [
        'warnings', 
        'contraindications', 
        'adverse_reactions', 
        'black_box_warning', 
        'renal_adjustment', 
        'hepatic_adjustment', 
        'pregnancy_category', 
        'lactation_info'
    ]

    print(f"Scanning {len(dosages)} dosage entries...")
    
    if len(dosages) > 0:
        print("First entry sample keys:", list(dosages[0].keys()))
        print("First entry sample val (warnings):", dosages[0].get('warnings'))

    for entry in dosages:
        score = 0
        
        # Check if fields exist and are not empty
        for field in fields_to_check:
            val = entry.get(field)
            if val is not None:
                if isinstance(val, str) and len(val) > 2:
                    score += 1
                elif isinstance(val, list) and len(val) > 0: # Compressed data
                    score += 1
        
        # Bonus for Black Box Warning
        bbw = entry.get('black_box_warning')
        if bbw:
             if isinstance(bbw, list) and len(bbw) > 0: score += 5
             elif isinstance(bbw, str) and len(bbw) > 2: score += 5

        if score > best_score:
            med_id = entry.get('med_id')
            if med_id in med_map: # Must correspond to an existing drug
                best_score = score
                best_entry = entry

    if best_entry:
        med_id = best_entry.get('med_id')
        name = med_map.get(med_id, "Unknown")
        print("\n" + "="*50)
        print(f"FOUND BEST MATCH: {name} (ID: {med_id})")
        print("="*50)
        print(f"Score: {best_score}")
        
        for field in fields_to_check:
            val = best_entry.get(field)
            has_data = val is not None and (len(val) > 0 if isinstance(val, (str, list)) else True)
            val_preview = "YES" if has_data else "NO"
            print(f"- {field}: {val_preview}")
            
        print("\nFull Data Snippet (Instructions):")
        instr = best_entry.get('instructions')
        if instr:
            print(f"{str(instr)[:100]}...")
    else:
        print("No suitable drug found.")

if __name__ == "__main__":
    find_best_drug()
