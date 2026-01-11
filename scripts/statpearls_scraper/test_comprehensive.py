#!/usr/bin/env python3
"""
Comprehensive NCBI Matching Test
Tests 100 random REAL drugs and measures success rate
"""
import sys
sys.path.insert(0, '/home/adminlotfy/project/scripts/statpearls_scraper')
from generate_targets import search_ncbi
import sqlite3
import time
from pathlib import Path

DB_PATH = Path('/home/adminlotfy/project/assets/database/mediswitch.db')

# Get 100 random REAL drugs (filtered)
conn = sqlite3.connect(DB_PATH)
cursor = conn.cursor()

query = """
SELECT DISTINCT ingredient 
FROM med_ingredients 
WHERE ingredient IS NOT NULL 
  AND LENGTH(ingredient) >= 3
  AND ingredient GLOB '[A-Za-z]*'
  AND LOWER(ingredient) NOT LIKE '%oil%'
  AND LOWER(ingredient) NOT LIKE '%extract%'
  AND LOWER(ingredient) NOT LIKE '%wax%'
  AND LOWER(ingredient) NOT LIKE '%powder%'
  AND LOWER(ingredient) NOT LIKE '%cream%'
  AND LOWER(ingredient) NOT LIKE '%lotion%'
  AND LOWER(ingredient) NOT LIKE '%gel%'
  AND LOWER(ingredient) NOT LIKE '%ointment%'
  AND LOWER(ingredient) NOT LIKE '%vitamin%'
  AND LOWER(ingredient) NOT LIKE '%mineral%'
  AND LOWER(ingredient) NOT LIKE '%formula%'
  AND LENGTH(ingredient) - LENGTH(REPLACE(ingredient, ' ', '')) <= 2
ORDER BY RANDOM() 
LIMIT 100
"""

cursor.execute(query)
test_drugs = [row[0] for row in cursor.fetchall()]
conn.close()

print(f"🧪 Testing {len(test_drugs)} REAL pharmaceutical drugs")
print("="*70)

success = []
failed = []

for idx, drug in enumerate(test_drugs, 1):
    print(f"[{idx}/100] {drug[:40]}...", end=" ")
    
    result = search_ncbi(drug)
    
    if result:
        print(f"✅ {result}")
        success.append((drug, result))
    else:
        print("❌")
        failed.append(drug)
    
    # Progress every 10
    if idx % 10 == 0:
        print(f"\n📊 Progress: {idx}/100 | Success: {len(success)} | Failed: {len(failed)}\n")
    
    time.sleep(0.5)

print("\n" + "="*70)
print(f"\n📈 FINAL RESULTS:")
print(f"✅ Success: {len(success)}/100 = {len(success)}%")
print(f"❌ Failed: {len(failed)}/100 = {len(failed)}%")

if failed:
    print(f"\n🔍 Failed Drugs (for analysis):")
    for drug in failed[:20]:
        print(f"  - {drug}")
    if len(failed) > 20:
        print(f"  ... and {len(failed)-20} more")

# Save results
with open('/tmp/ncbi_test_results.txt', 'w') as f:
    f.write(f"Success: {len(success)}/100 = {len(success)}%\n")
    f.write(f"Failed: {len(failed)}/100\n\n")
    f.write("Failed drugs:\n")
    for drug in failed:
        f.write(f"  - {drug}\n")

print(f"\n✅ Results saved to /tmp/ncbi_test_results.txt")
