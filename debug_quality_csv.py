#!/usr/bin/env python3
import csv
import re
import sys

# Logic copied from analyze_quality.py
JUNK_PATTERNS = [
    r'See .* for full prescribing information',
    r'Please refer to the full prescribing information',
    r'^Section \d+',
    r'Table \d+',
    r'^\d+(\.\d+)?$',  # "2.1"
    r'^\d+\s*mg$',      # Pure number? Maybe useful but categorized as Medium?
    r'^\.*$',           # Dots
]

def is_junk(text):
    if not text or len(text) < 5: return True
    for pat in JUNK_PATTERNS:
        if re.search(pat, text, re.IGNORECASE):
            return True
    return False

def is_clinically_useful(text):
    if is_junk(text): return False
    # Must contain numbers?
    if not re.search(r'\d+', text): return False
    return True

def analyze_row(row):
    text = row.get('instructions', '')
    route = row.get('route', '')
    freq = row.get('frequency', '')

    has_useful_text = is_clinically_useful(text)
    
    # Check Freq
    has_freq = False
    try:
        # analyze_quality expects frequency > 0
        if freq and float(freq) > 0: has_freq = True
    except: pass
    
    # Check Route
    has_route = bool(route and len(route) > 2)
    
    status = 'Low'
    if has_useful_text and has_freq and has_route:
        status = 'High'
    elif has_useful_text or (has_freq and has_route):
        status = 'Medium'
        
    return status, text, freq, route, row.get('source')

def main():
    csv_file = 'exports/dosage_guidelines_full.csv'
    print(f"Analyzing {csv_file} for LOW quality records...")
    
    low_count = 0
    total = 0
    
    sources_of_low = {}
    reasons = {'no_text': 0, 'no_freq': 0, 'no_route': 0, 'text_no_numbers': 0}
    
    with open(csv_file, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            total += 1
            status, text, freq, route, source = analyze_row(row)
            
            if status == 'Low':
                low_count += 1
                sources_of_low[source] = sources_of_low.get(source, 0) + 1
                
                # Analyze reason
                if not text: reasons['no_text'] += 1
                elif not re.search(r'\d+', text): reasons['text_no_numbers'] += 1
                
                if not freq or freq == '0': reasons['no_freq'] += 1
                if not route: reasons['no_route'] += 1
                
                # Print breakdown for DailyMed specifically
                if source == 'DailyMed' and low_count < 50:
                    print(f"\n[LOW DailyMed] ID: {row.get('med_id')}")
                    print(f"  Txt: {repr(text)}")
                    print(f"  Frq: {repr(freq)} | Rte: {repr(route)}")
                    
    print("\n--- Summary ---")
    print(f"Total Low: {low_count}/{total} ({low_count/total*100:.1f}%)")
    print("Sources of Low:")
    for s, c in sources_of_low.items():
        print(f"  {s}: {c}")
    print("Reasons (overlap possible):")
    for r, c in reasons.items():
        print(f"  {r}: {c}")

if __name__ == '__main__':
    main()
