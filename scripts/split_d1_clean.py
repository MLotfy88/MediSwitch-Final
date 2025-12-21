#!/usr/bin/env python3
"""
تقسيم d1_import.sql الجديد (single INSERTs) لملفات صغيرة
"""

import os

input_file = "/home/adminlotfy/project/d1_import.sql"
output_dir = "/home/adminlotfy/project/d1_clean_chunks"
rows_per_file = 2500  # 2500 drugs per file (~2 MB)

os.makedirs(output_dir, exist_ok=True)

print("📖 قراءة الملف...")

with open(input_file, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Separate schema and INSERTs
schema_lines = []
insert_lines = []
in_schema = True

for line in lines:
    if line.strip().startswith('INSERT INTO drugs'):
        in_schema = False
        insert_lines.append(line)
    elif in_schema:
        schema_lines.append(line)

print(f"📊 Schema: {len(schema_lines)} lines")
print(f"📊 INSERTs: {len(insert_lines):,}")
print()

# Write schema
schema_file = f"{output_dir}/00_schema.sql"
with open(schema_file, 'w', encoding='utf-8') as f:
    f.writelines(schema_lines)
print(f"✅ {schema_file}")

# Split INSERTs into chunks
chunk_num = 1
for i in range(0, len(insert_lines), rows_per_file):
    chunk = insert_lines[i:i+rows_per_file]
    chunk_file = f"{output_dir}/{chunk_num:02d}_data.sql"
    
    with open(chunk_file, 'w', encoding='utf-8') as f:
        f.writelines(chunk)
    
    size_mb = os.path.getsize(chunk_file) / (1024 * 1024)
    print(f"✅ {chunk_file} ({len(chunk):,} rows, {size_mb:.2f} MB)")
    chunk_num += 1

total = chunk_num - 1
print()
print(f"✅ تم: {total + 1} ملف (schema + {total} data)")
print(f"📁 {output_dir}/")
