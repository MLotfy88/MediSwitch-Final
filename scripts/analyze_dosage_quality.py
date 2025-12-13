import json
import collections

INPUT_FILE = 'production_data/dosages_merged.json'

def analyze_dosages():
    try:
        with open(INPUT_FILE, 'r') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"File not found: {INPUT_FILE}")
        return

    total_records = len(data)
    unique_drugs = set(d.get('drug_name', '').lower() for d in data)
    
    # Structured Data Stats
    has_mg_kg = 0
    has_frequency = 0
    has_max_dose = 0
    is_pediatric = 0
    
    # Text Length Stats
    text_lengths = []
    
    for d in data:
        struct = d.get('structured', {})
        if struct.get('dose_mg_kg'): has_mg_kg += 1
        if struct.get('frequency_hours'): has_frequency += 1
        if struct.get('max_dose_mg'): has_max_dose += 1
        if struct.get('is_pediatric'): is_pediatric += 1
        
        text_lengths.append(len(d.get('raw_text', '')))

    avg_text_len = sum(text_lengths) / len(text_lengths) if text_lengths else 0
    
    print(f"Total Records: {total_records}")
    print(f"Unique Drugs: {len(unique_drugs)}")
    print("-" * 20)
    print(f"Structured mg/kg: {has_mg_kg} ({has_mg_kg/total_records*100:.1f}%)")
    print(f"Structured Frequency: {has_frequency} ({has_frequency/total_records*100:.1f}%)")
    print(f"Structured Max Dose: {has_max_dose} ({has_max_dose/total_records*100:.1f}%)")
    print(f"Pediatric Records: {is_pediatric} ({is_pediatric/total_records*100:.1f}%)")
    print("-" * 20)
    print(f"Avg Text Length: {avg_text_len:.0f} chars")

if __name__ == "__main__":
    analyze_dosages()
