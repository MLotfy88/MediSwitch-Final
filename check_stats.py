import json
import os

if os.path.exists('assets/data/dosage_guidelines.json'):
    data = json.load(open('assets/data/dosage_guidelines.json'))
    total = len(data)
    std = len([d for d in data if d.get('standard_dose')])
    max_d = len([d for d in data if d.get('max_dose')])
    print(f'Total: {total}')
    print(f'With Standard Dose: {std}')
    print(f'With Max Dose: {max_d}')
else:
    print("File not found.")
