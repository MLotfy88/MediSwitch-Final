#!/usr/bin/env python3
"""
تحليل ملف D1 import والتحقق من المشكلة
"""

import os

sql_file = "/home/adminlotfy/project/d1_import.sql"

if not os.path.exists(sql_file):
    print("❌ File not found!")
    exit(1)

print("📊 تحليل ملف D1 import...")
print("=" * 50)

# Read file
with open(sql_file, 'r', encoding='utf-8') as f:
    content = f.read()

# Stats
file_size = os.path.getsize(sql_file) / (1024 * 1024)  # MB
lines = content.split('\n')
insert_statements = [line for line in lines if line.strip().startswith('INSERT INTO drugs')]

print(f"📁 حجم الملف: {file_size:.2f} MB")
print(f"📝 عدد الأسطر: {len(lines):,}")
print(f"💉 عدد INSERT statements: {len(insert_statements):,}")
print()

# Check structure
has_schema = any('CREATE TABLE' in line for line in lines[:50])
has_drops = any('DROP TABLE' in line for line in lines[:50])

print("🔍 بنية الملف:")
print(f"  - Schema (CREATE TABLE): {'✅' if has_schema else '❌'}")
print(f"  - Drop statements: {'✅' if has_drops else '❌'}")
print()

# Sample data
print("📋 عينة من البيانات:")
for i, stmt in enumerate(insert_statements[:3]):
    print(f"  {i+1}. {stmt[:100]}...")
print()

# Size analysis
avg_stmt_size = len(content) / len(insert_statements) if insert_statements else 0
print(f"📐 متوسط حجم كل INSERT: {avg_stmt_size:.0f} bytes")
print()

# Recommendations
print("💡 التوصيات:")
print()

if file_size > 5:
    print("⚠️  الملف كبير جداً لـ wrangler (> 5 MB)")
    chunks_needed = int(file_size / 1) + 1  # 1 MB chunks
    print(f"   يحتاج تقسيم لـ {chunks_needed} أجزاء")
    print()
    
    rows_per_chunk = len(insert_statements) // chunks_needed
    print(f"📦 مقترح التقسيم:")
    print(f"   - {chunks_needed} ملفات")
    print(f"   - ~{rows_per_chunk} INSERT لكل ملف")
    print(f"   - ~{file_size / chunks_needed:.2f} MB لكل ملف")
else:
    print("✅ الملف مناسب لـ wrangler direct upload")

print()
print("=" * 50)
print("✅ التحليل مكتمل!")
