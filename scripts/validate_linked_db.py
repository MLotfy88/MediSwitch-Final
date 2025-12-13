import json
import random
import os

FILE_PATH = 'production_data/production_dosages.jsonl'

def main():
    if not os.path.exists(FILE_PATH):
        print(f"❌ File not found: {FILE_PATH}")
        return

    print(f"🔍 Validating {FILE_PATH}...")
    
    total = 0
    linked = 0
    app_conc_source = 0
    dailymed_conc_source = 0
    
    linked_samples = []
    
    with open(FILE_PATH, 'r', encoding='utf-8') as f:
        for line in f:
            if not line.strip(): continue
            try:
                rec = json.loads(line)
                total += 1
                
                if rec.get('med_id'):
                    linked += 1
                    linked_samples.append(rec)
                    
                src = rec.get('concentration_source')
                if src == 'App_Name_Regex':
                    app_conc_source += 1
                elif src in ['XML_Structured', 'XML_Constructed', 'Name_Regex']:
                    dailymed_conc_source += 1
                    
            except Exception:
                pass
                
    print(f"\n📊 STATISTICS:")
    print(f"  Total Records: {total:,}")
    print(f"  Linked to App IDs: {linked:,} ({linked/total*100:.1f}%)")
    print(f"  Concentration Sources:")
    print(f"    - From App Name: {app_conc_source:,}")
    print(f"    - From DailyMed: {dailymed_conc_source:,}")
    
    print(f"\n🧪 SAMPLE LINKED RECORDS:")
    if linked_samples:
        for rec in random.sample(linked_samples, min(10, len(linked_samples))):
            print("-" * 60)
            print(f"Trade Name: {rec.get('trade_name')}")
            print(f"App ID: {rec.get('med_id')}")
            print(f"Concentration: {rec.get('concentration')} (Source: {rec.get('concentration_source')})")
            print(f"DailyMed Name: {rec.get('dailymed_name')}")
            if rec.get('dosages'):
                 print(f"Dosage: {rec['dosages']}")

if __name__ == "__main__":
    main()
