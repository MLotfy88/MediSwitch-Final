import csv
import re

# Read sample CSV
with open('exports/dosage_guidelines_sample.csv', 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    dailymed_records = [r for r in reader if r.get('source') == 'DailyMed']

print(f"Total DailyMed in sample: {len(dailymed_records)}")
print("="*80)

# Quality metrics
high = medium = low = 0

for i, rec in enumerate(dailymed_records[:10], 1):
    instr = rec.get('instructions', '')
    freq = rec.get('frequency', '')
    route = rec.get('route', '')
    
    has_nums = bool(re.search(r'\d+', instr))
    has_freq = bool(freq)
    has_route = bool(route)
    
    # Check for boilerplate
    issues = []
    if 'DOSAGE AND ADMINISTRATION' in instr:
        issues.append('Section header')
    if re.search(r'\[see .+?\]', instr):
        issues.append('References')
    if 'PATIENTS SHOULD' in instr.upper():
        issues.append('Legal text')
    if re.search(r'Section \d', instr):
        issues.append('Section numbers')
    if len(instr) > 1000:
        issues.append('Too long')
        
    # Quality classification
    if has_nums and has_freq and has_route:
        quality = 'HIGH'
        high += 1
    elif has_nums or (has_freq and has_route):
        quality = 'MEDIUM'
        medium += 1
    else:
        quality = 'LOW'
        low += 1
    
    print(f"\nRecord {i} [{quality}]:")
    print(f"  Route: {route or 'MISSING'}")
    print(f"  Frequency: {freq or 'MISSING'}")
    print(f"  Length: {len(instr)} chars")
    print(f"  Issues: {', '.join(issues) if issues else 'Clean'}")
    print(f"  Preview: {instr[:200]}...")

print("\n" + "="*80)
print(f"Sample Quality:")
print(f"  HIGH: {high}/10")
print(f"  MEDIUM: {medium}/10")
print(f"  LOW: {low}/10")
