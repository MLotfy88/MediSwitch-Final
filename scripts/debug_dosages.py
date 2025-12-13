import json
import re

FILE = 'dosages_final.json'

def debug():
    try:
        with open(FILE, 'r') as f:
            data = json.load(f)
    except Exception as e:
        print(f"Error loading file: {e}")
        return

    print(f"Total Records: {len(data)}")
    
    null_structured = 0
    null_text = 0
    total = len(data)
    
    print("\n--- First 5 Records ---")
    for i, r in enumerate(data[:5]):
        print(f"Record {i+1}: {r.get('drug_name')}")
        print(f"  Concentration: {r.get('concentration')}")
        dosages = r.get('dosages', {})
        print(f"  Text Length: {len(dosages.get('text_dosage') or '')}")
        print(f"  Structured: {dosages.get('structured')}")
        print(f"  Snippet: {(dosages.get('text_dosage') or '')[:100]}...")
        print("-" * 20)
        
    for r in data:
        d = r.get('dosages', {})
        if not d.get('text_dosage'):
            null_text += 1
        else:
            if not d.get('structured') or not d['structured'].get('dose_mg_kg'):
                null_structured += 1
                
    print("\n--- Statistics ---")
    print(f"Null Text: {null_text} ({null_text/total*100:.1f}%) -- (Source Data Empty)")
    print(f"Text Present but Structured Null: {null_structured} ({null_structured/total*100:.1f}%) -- (Parser Failed)")

if __name__ == '__main__':
    debug()
