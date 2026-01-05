#!/usr/bin/env python3
"""
Clinical Quality Analysis Script
Measures "True Enrichment" by excluding generic content and validating clinical utility.
"""
import csv
import re
import sys

# Input File
INPUT_CSV = 'exports/dosage_guidelines_full.csv'

# "Junk" Patterns - Content that is NOT clinically useful
JUNK_PATTERNS = [
    r'see package insert',
    r'consult (your|a) (doctor|physician|pharmacist)',
    r'refer to.*prescribing information',
    r'read the leaflet',
    r'as directed by.*physician',
    r'^See package insert$',
]

# Arabic Junk (Generic descriptions)
ARABIC_JUNK = [
    r'مضاد للتقلصات',
    r'مسكن',
    r'خافض للحرارة',
    r'مضاد حيوي',
    r'فيتامين',
    r'مكمل غذائي',
]

def is_junk(text):
    if not text: return True
    text = text.lower().strip()
    if len(text) < 5: return True # Too short to be useful
    
    for p in JUNK_PATTERNS:
        if re.search(p, text): return True
        
    return False

def is_clinically_useful(text):
    if is_junk(text): return False
    # Must contain numbers (dosage amounts)
    if not re.search(r'\d+', text): return False
    return True

def analyze_row(row):
    instructions = row.get('instructions', '')
    freq = row.get('frequency')
    dur = row.get('duration')
    route = row.get('route')
    source = row.get('source')
    
    has_freq = bool(freq and float(freq) > 0)
    has_dur = bool(dur and float(dur) > 0)
    has_route = bool(route)
    has_useful_text = is_clinically_useful(instructions)
    
    # Classification
    if has_useful_text and has_freq and has_route:
        return 'High'
    elif has_useful_text or (has_freq and has_route):
        return 'Medium'
    else:
        return 'Low'

def main():
    print("🔬 Analyzing Clinical Quality...\n")
    
    try:
        rows = list(csv.DictReader(open(INPUT_CSV)))
    except FileNotFoundError:
        print(f"❌ File {INPUT_CSV} not found.")
        return
        
    total = len(rows)
    stats = {'High': 0, 'Medium': 0, 'Low': 0}
    sources = {}
    
    for row in rows:
        rating = analyze_row(row)
        stats[rating] += 1
        
        src = row.get('source', 'Unknown')
        if src not in sources: sources[src] = {'High': 0, 'Medium': 0, 'Low': 0}
        sources[src][rating] += 1

    # Report
    print(f"📊 Total Records: {total:,}")
    print("-" * 40)
    print(f"🏆 HIGH Quality (Useful Text + Freq + Route):")
    print(f"   {stats['High']:,} ({stats['High']/total*100:.1f}%)")
    print(f"✨ MEDIUM Quality (Useful Text OR Freq/Route):")
    print(f"   {stats['Medium']:,} ({stats['Medium']/total*100:.1f}%)")
    print(f"⚠️ LOW Quality (Generic/Empty/Lazy):")
    print(f"   {stats['Low']:,} ({stats['Low']/total*100:.1f}%)")
    
    print("\n🔍 Breakdown by Source:")
    for src, counts in sources.items():
        t = sum(counts.values())
        h_pct = counts['High']/t*100 if t else 0
        l_pct = counts['Low']/t*100 if t else 0
        print(f"  • {src}: {h_pct:.1f}% High / {l_pct:.1f}% Low (n={t})")

    # Generate Markdown Report for GitHub Actions
    with open('quality_report.md', 'w') as f:
        f.write('## 🩺 Clinical Quality Report\n\n')
        f.write('| Quality Level | Count | Percentage | Description |\n')
        f.write('|---|---|---|---|\n')
        f.write(f'| 🏆 **HIGH** | {stats["High"]:,} | {stats["High"]/total*100:.1f}% | Useful Text + Freq + Route |\n')
        f.write(f'| ✨ **MEDIUM** | {stats["Medium"]:,} | {stats["Medium"]/total*100:.1f}% | Useful Text or Numbers Only |\n')
        f.write(f'| ⚠️ **LOW** | {stats["Low"]:,} | {stats["Low"]/total*100:.1f}% | Generic/Lazy Content |\n\n')

    # Print Report to Stdout (Backup for Visibility)
    print("\n" + "="*50)
    print("📢 GITHUB ACTION SUMMARY (Preview)")
    print("="*50)
    print(open('quality_report.md').read())
    print("="*50 + "\n")

if __name__ == '__main__':
    main()
