import sqlite3
import csv
import json
from collections import Counter

# Paths
DDINTER_DB = 'ddinter_data/ddinter_complete.db'
LOCAL_MEDS_CSV = 'assets/meds.csv'

print("🔍 Analyzing Matching Failures\n")
print("=" * 80)

# Load DDInter drug names
conn = sqlite3.connect(DDINTER_DB)
cursor = conn.cursor()
cursor.execute("SELECT LOWER(drug_name) FROM drugs")
ddinter_names = set(row[0] for row in cursor.fetchall())
conn.close()

print(f"✅ DDInter has {len(ddinter_names):,} unique drug names\n")

# Load local ingredients
local_ingredients = set()
local_trade_names = set()
unmatched_ingredients = []
unmatched_trade_names = []

with open(LOCAL_MEDS_CSV, 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        trade = row.get('trade_name', '').strip().lower()
        active = row.get('active', '').strip()
        
        if trade:
            local_trade_names.add(trade)
            if trade not in ddinter_names:
                unmatched_trade_names.append(trade)
        
        if active:
            for ing in active.replace('+', ';').replace('/', ';').split(';'):
                ing = ing.strip().lower()
                if ing:
                    local_ingredients.add(ing)
                    if ing not in ddinter_names:
                        unmatched_ingredients.append(ing)

print(f"📦 Local Data:")
print(f"   Trade Names: {len(local_trade_names):,}")
print(f"   Active Ingredients: {len(local_ingredients):,}\n")

print(f"❌ Unmatched:")
print(f"   Trade Names: {len(unmatched_trade_names):,} ({len(unmatched_trade_names)/len(local_trade_names)*100:.1f}%)")
print(f"   Ingredients: {len(unmatched_ingredients):,} ({len(unmatched_ingredients)/len(local_ingredients)*100:.1f}%)\n")

# Analyze patterns in unmatched names
print("=" * 80)
print("📊 Sample Unmatched Ingredients (first 30):\n")
for i, ing in enumerate(unmatched_ingredients[:30], 1):
    print(f"{i:2d}. {ing}")

print("\n" + "=" * 80)
print("📊 Sample Unmatched Trade Names (first 30):\n")
for i, name in enumerate(unmatched_trade_names[:30], 1):
    print(f"{i:2d}. {name}")

print("\n" + "=" * 80)
print("📊 Sample DDInter Drug Names (first 30):\n")
for i, name in enumerate(sorted(ddinter_names)[:30], 1):
    print(f"{i:2d}. {name}")

# Detect patterns
print("\n" + "=" * 80)
print("🔍 Pattern Analysis:\n")

# Check for Arabic vs English
arabic_count = sum(1 for ing in local_ingredients if any('\u0600' <= c <= '\u06FF' for c in ing))
print(f"Local ingredients with Arabic characters: {arabic_count} ({arabic_count/len(local_ingredients)*100:.1f}%)")

# Check for special characters
special_chars = Counter()
for ing in local_ingredients:
    for char in ing:
        if not char.isalnum() and not char.isspace():
            special_chars[char] += 1

print(f"\nMost common special characters in local data:")
for char, count in special_chars.most_common(10):
    print(f"   '{char}': {count:,} times")
