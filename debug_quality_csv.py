#!/usr/bin/env python3
import csv
import glob
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
    # Logic matching analyze_quality.py
    instructions = row.get('instructions', '')
    freq = row.get('frequency', '')
    route = row.get('route', '')
    
    try:
        has_freq = bool(freq and float(freq) > 0)
    except:
        has_freq = False
        
    has_route = bool(route and len(route) > 0)
    has_useful_text = is_clinically_useful(instructions)
    
    status = 'Low'
    if has_useful_text and has_freq and has_route:
        status = 'High'
    elif has_useful_text or (has_freq and has_route):
        status = 'Medium'
        
    return status, instructions, freq, route, row.get('source')

def main():
    csv_files = sorted(glob.glob('exports/dosage_guidelines_part_*.csv'))
    print(f"Analyzing {len(csv_files)} output files...")
    
    low_count = 0
    total = 0
    stats = {'High': 0, 'Medium': 0, 'Low': 0}
    sources = {}
    
    for csv_file in csv_files:
        print(f"Reading {csv_file}...")
        with open(csv_file, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                total += 1
                status, text, freq, route, source = analyze_row(row)
                stats[status] += 1
                
                # Track Source Stats
                src = source or 'Unknown'
                if src not in sources: sources[src] = {'High': 0, 'Medium': 0, 'Low': 0}
                sources[src][status] += 1
                
                if status == 'Low':
                    low_count += 1
                    # Debug print for first few Lows
                    if low_count <= 5:
                        print(f"\n[LOW] Source: {source}")
                        print(f"  Txt: {repr(text)}")
                        print(f"  Frq: {repr(freq)} | Rte: {repr(route)}")

    print("\n" + "="*50)
    print(f"📊 Local Quality Check Results (Total: {total:,})")
    print("="*50)
    print(f"🏆 HIGH   : {stats['High']:,} ({stats['High']/total*100:.1f}%)")
    print(f"✨ MEDIUM : {stats['Medium']:,} ({stats['Medium']/total*100:.1f}%)")
    print(f"⚠️ LOW    : {stats['Low']:,} ({stats['Low']/total*100:.1f}%)")
    print("-" * 50)
    
    print("\n🔍 Breakdown by Source:")
    for src, counts in sources.items():
        t = sum(counts.values())
        print(f"  • {src}: {counts['High']/t*100:.1f}% High / {counts['Low']/t*100:.1f}% Low (n={t:,})")


if __name__ == '__main__':
    main()
