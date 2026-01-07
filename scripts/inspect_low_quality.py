#!/usr/bin/env python3
"""
Low Quality Record Inspector
Extracts samples of LOW quality records with detailed diagnostics
"""
import gzip
import json
import csv
import re
from collections import defaultdict

DOSAGE_JSON = 'assets/data/dosage_guidelines.json.gz'
OUTPUT_CSV = 'exports/low_quality_samples.csv'

def classify_with_reason(rec):
    """Classify record and provide detailed reason"""
    text = rec.get('instructions', '') or ''
    freq = rec.get('frequency')
    route = rec.get('route')
    source = rec.get('source', '')
    
    # Quality checks
    has_numbers = bool(re.search(r'\d+', text))
    has_useful_text = has_numbers and len(text) > 20
    has_freq = bool(freq and (isinstance(freq, (int, float)) and freq > 0))
    has_route = bool(route and len(str(route)) > 2)
    
    reasons = []
    
    # Check text quality
    if not text or len(text) < 10:
        reasons.append("Empty/Very Short Text")
    elif not has_numbers:
        reasons.append("No Dosage Numbers in Text")
    elif len(text) < 20:
        reasons.append("Text Too Short")
    
    # Check structured fields
    if not has_freq:
        reasons.append("Missing Frequency")
    if not has_route:
        reasons.append("Missing Route")
    
    # Check for truncation
    if text.endswith('...'):
        reasons.append("Truncated Text")
    
    # Check for boilerplate patterns
    boilerplate_patterns = [
        r'PATIENTS? SHOULD BE',
        r'See (full|complete) prescrib',
        r'Section \d+',
        r'For (complete|full|additional) information',
    ]
    for pattern in boilerplate_patterns:
        if re.search(pattern, text, re.IGNORECASE):
            reasons.append("Contains Boilerplate")
            break
    
    # Classify
    if has_useful_text and has_freq and has_route:
        quality = 'HIGH'
    elif has_useful_text or (has_freq and has_route):
        quality = 'MEDIUM'
    else:
        quality = 'LOW'
    
    return quality, '; '.join(reasons) if reasons else 'N/A'

def main():
    print("🔍 Loading data...")
    with gzip.open(DOSAGE_JSON, 'rt', encoding='utf-8') as f:
        data = json.load(f)
    
    print(f"📊 Analyzing {len(data):,} records...")
    
    # Categorize records
    low_quality = []
    reason_counts = defaultdict(int)
    pattern_examples = defaultdict(list)
    
    for rec in data:
        quality, reason = classify_with_reason(rec)
        
        if quality == 'LOW':
            low_quality.append({
                'med_id': rec.get('med_id', 'N/A'),
                'source': rec.get('source', 'N/A'),
                'active_ingredient': rec.get('active_ingredient', 'N/A'),
                'route': rec.get('route', ''),
                'frequency': rec.get('frequency', ''),
                'instructions': (rec.get('instructions', '') or '')[:200],  # First 200 chars
                'reason': reason,
                'quality': quality
            })
            
            # Track patterns
            for r in reason.split('; '):
                reason_counts[r] += 1
                if len(pattern_examples[r]) < 3:  # Keep 3 examples per pattern
                    instr_text = rec.get('instructions') or ''
                    pattern_examples[r].append(instr_text[:100] if instr_text else 'N/A')
    
    print(f"\n📉 Found {len(low_quality):,} LOW quality records ({len(low_quality)/len(data)*100:.1f}%)")
    
    # Print summary
    print("\n🔍 Common Reasons for LOW Quality:")
    for reason, count in sorted(reason_counts.items(), key=lambda x: x[1], reverse=True):
        print(f"  • {reason}: {count:,} records ({count/len(low_quality)*100:.1f}%)")
    
    # Save sample to CSV
    sample_size = min(500, len(low_quality))
    print(f"\n💾 Saving {sample_size} samples to {OUTPUT_CSV}...")
    
    with open(OUTPUT_CSV, 'w', newline='', encoding='utf-8') as f:
        if low_quality:
            writer = csv.DictWriter(f, fieldnames=low_quality[0].keys())
            writer.writeheader()
            writer.writerows(low_quality[:sample_size])
    
    # Print pattern examples
    print("\n📝 Example Text for Each Pattern:")
    for reason, examples in pattern_examples.items():
        print(f"\n  {reason}:")
        for i, ex in enumerate(examples, 1):
            print(f"    {i}. {ex}...")
    
    print(f"\n✅ Done! Check {OUTPUT_CSV} for detailed samples.")
    
    return 0

if __name__ == '__main__':
    import sys
    sys.exit(main())
