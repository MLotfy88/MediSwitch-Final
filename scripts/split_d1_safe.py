#!/usr/bin/env python3
"""
تقسيم d1_import.sql لملفات صغيرة جداً (آمنة 100%)
"""

import os

input_file = "/home/adminlotfy/project/d1_import.sql"
output_dir = "/home/adminlotfy/project/d1_safe_chunks"
drugs_per_file = 500  # 500 drugs per file (~500 KB)

os.makedirs(output_dir, exist_ok=True)

print("📖 قراءة الملف...")

with open(input_file, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# تصنيف الأسطر
schema = []
inserts = []

for line in lines:
    if line.strip().startswith('INSERT INTO drugs'):
        inserts.append(line)
    elif not line.strip().startswith('--') or 'DROP' in line or 'CREATE' in line:
        schema.append(line)

print(f"📊 Schema: {len(schema)} lines")
print(f"📊 INSERTs: {len(inserts):,}")
print()

# Schema file
schema_file = f"{output_dir}/00_schema.sql"
with open(schema_file, 'w', encoding='utf-8') as f:
    f.writelines(schema)
print(f"✅ {schema_file}")

# Split INSERTs
chunk_num = 1
total_files = (len(inserts) + drugs_per_file - 1) // drugs_per_file

for i in range(0, len(inserts), drugs_per_file):
    chunk = inserts[i:i+drugs_per_file]
    chunk_file = f"{output_dir}/{chunk_num:03d}_data.sql"
    
    with open(chunk_file, 'w', encoding='utf-8') as f:
        f.writelines(chunk)
    
    size_kb = os.path.getsize(chunk_file) / 1024
    print(f"✅ Chunk {chunk_num:03d}/{total_files} ({len(chunk):,} drugs, {size_kb:.1f} KB)")
    chunk_num += 1

print()
print(f"✅ تم: {chunk_num} ملف (schema + {chunk_num - 1} data)")
print(f"📁 {output_dir}/")
