#!/usr/bin/env python3
"""
Analyze ingredients for common errors and create correction dictionary
"""
import re
from collections import defaultdict

# Read all ingredients
with open('/tmp/all_ingredients.txt', 'r') as f:
    ingredients = [line.strip() for line in f if line.strip()]

print(f"Total ingredients: {len(ingredients)}\n")

# Patterns to detect
issues = {
    'misspelled': [],
    'incomplete': [],
    'with_dose': [],
    'abbreviated': [],
    'special_chars': []
}

# Common misspellings (known from test)
known_misspellings = {
    'soduim': 'sodium',
    'chondrotin': 'chondroitin',
    'bromalin': 'bromelain',
    'camomil': 'chamomile',
    'gingenol': 'gingerol',
    'magnesiun': 'magnesium',
    'calcuim': 'calcium',
    'potassuim': 'potassium',
}

# Incomplete/abbreviated patterns
incomplete_patterns = [
    r'^[a-z]{1,3}$',  # Too short (e.g., "lysi")
    r'vit \(',         # Incomplete vitamin names
    r'\w+ \w+\)$',     # Malformed endings
]

corrections = {}

for ing in ingredients:
    lower = ing.lower()
    
    # Check for known misspellings
    for wrong, correct in known_misspellings.items():
        if wrong in lower:
            issues['misspelled'].append(ing)
            corrections[ing] = ing.replace(wrong, correct).replace(wrong.title(), correct.title())
            break
    
    # Check for doses/concentrations
    if re.search(r'\d+\s*(mg|mcg|gm|ml|iu|%)', lower):
        issues['with_dose'].append(ing)
        # Remove dose for correction
        clean = re.sub(r'\s*\d+\.?\d*\s*(mg|mcg|gm|ml|iu|%)\s*', ' ', ing, flags=re.IGNORECASE).strip()
        if clean != ing:
            corrections[ing] = clean
    
    # Check for incomplete/malformed
    if re.match(r'^[a-z]{1,3}$', lower) or '(' in ing and ')' not in ing:
        issues['incomplete'].append(ing)
    
    # Special characters issues
    if ing.count('(') != ing.count(')'):
        issues['special_chars'].append(ing)

print("="*70)
print("ISSUES FOUND:\n")
print(f"1. Misspelled: {len(issues['misspelled'])}")
print(f"2. With doses: {len(issues['with_dose'])}")
print(f"3. Incomplete: {len(issues['incomplete'])}")
print(f"4. Special char issues: {len(issues['special_chars'])}")

print("\n" + "="*70)
print("SAMPLE CORRECTIONS:\n")
for orig, corrected in list(corrections.items())[:20]:
    print(f"  {orig} → {corrected}")

print(f"\n\nTotal corrections: {len(corrections)}")

# Save corrections dictionary
with open('/tmp/corrections_dict.txt', 'w') as f:
    for orig, corrected in sorted(corrections.items()):
        f.write(f"{orig}|||{corrected}\n")

print(f"\n✅ Saved to /tmp/corrections_dict.txt")
