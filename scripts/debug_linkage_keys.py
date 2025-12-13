import json
import os
import sys
import pandas as pd
sys.path.append(os.path.join(os.getcwd(), 'scripts'))
from process_datalake import normalize_active_ingredient, load_app_data, DATALAKE_FILE

def main():
    print("🔍 Debugging Linkage Keys...")
    
    # 1. Load Meds.csv Keys
    print("Loading App Data...")
    app_map, app_active_exact, app_active_stripped = load_app_data()
    
    print(f"\nApp Data Stats:")
    print(f"  Exact Keys: {len(app_active_exact)}")
    print(f"  Stripped Keys: {len(app_active_stripped)}")
    
    # Print sample App keys
    print("\nSample App Keys (Exact):")
    for k in list(app_active_exact.keys())[:10]:
        print(f"  '{k}'")
        
    # 2. Stream DailyMed and check Keys
    print(f"\nScanning DailyMed ({DATALAKE_FILE})...")
    dl_file = DATALAKE_FILE + 'l'
    if not os.path.exists(dl_file):
        dl_file = DATALAKE_FILE
    
    if not os.path.exists(dl_file):
        print(f"⚠️ Full DB not found. Trying mini sample...")
        dl_file = os.path.join(os.path.dirname(DATALAKE_FILE), 'dailymed_mini_sample.json')
    
    if not os.path.exists(dl_file):
         print("❌ No data file found!")
         return
         
    matched_exact = 0
    matched_stripped = 0
    scanned = 0
    scanned = 0
    
    sample_mismatches = []
    
    records = []
    if dl_file.endswith('.jsonl'):
        with open(dl_file, 'r') as f:
            for line in f:
                if not line.strip(): continue
                try:
                    records.append(json.loads(line))
                    if len(records) > 2000: break
                except: pass
    else:
        # Standard JSON
        try:
            with open(dl_file, 'r') as f:
                data = json.load(f)
                if isinstance(data, list):
                    records = data[:2000]
        except Exception as e:
            print(f"❌ Error loading JSON: {e}")
            return
            
    print(f"Loaded {len(records)} DailyMed records for scanning.")

    for entry in records:
        products = entry.get('products', [])
        if not products: continue
        
        # Check Generic Name
        generic_name = products[0].get('non_proprietary_name')
        if not generic_name: continue
        
        scanned += 1
        
        gn_exact = normalize_active_ingredient(generic_name, strip_salts=False)
        gn_stripped = normalize_active_ingredient(generic_name, strip_salts=True)
        
        found = False
        if gn_exact in app_active_exact:
            matched_exact += 1
            found = True
        elif gn_stripped in app_active_stripped:
             matched_stripped += 1
             found = True
            
        if not found and len(sample_mismatches) < 20:
             sample_mismatches.append(f"DM Generic: '{generic_name}' -> Keys: Exact='{gn_exact}', Stripped='{gn_stripped}'")
            
    print(f"\nDailyMed Scan (First {scanned} records):")
    print(f"  Matched Exact: {matched_exact}")
    print(f"  Matched Stripped: {matched_stripped}")
    print(f"  Total Hits: {matched_exact + matched_stripped} ({(matched_exact + matched_stripped)/scanned*100:.1f}%)")
    
    print("\n⚠️ Comparison of Mismatches (What we missed):")
    for m in sample_mismatches:
        print(f"  {m}")

if __name__ == "__main__":
    main()
