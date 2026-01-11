#!/usr/bin/env python3
import sys
import time
sys.path.insert(0, 'scripts/statpearls_scraper')
from generate_targets import search_ncbi

with open('/tmp/sample_ingredients.txt', 'r') as f:
    ingredients = [line.strip() for line in f if line.strip()]

print(f'Testing {len(ingredients)} ingredients')
print('='*70)

success = []
failed = []

for idx, ing in enumerate(ingredients, 1):
    print(f'[{idx}/{len(ingredients)}] {ing}...', end=' ')
    result = search_ncbi(ing)
    if result:
        print(f'MATCH: {result}')
        success.append((ing, result))
    else:
        print('NO MATCH')
        failed.append(ing)
    time.sleep(0.5)

print('='*70)
print(f'Success: {len(success)}/{len(ingredients)} = {len(success)/len(ingredients)*100:.1f}%')
print(f'Failed: {len(failed)}/{len(ingredients)}')

if failed:
    print('\nFailed ingredients:')
    for ing in failed:
        print(f'  - {ing}')
