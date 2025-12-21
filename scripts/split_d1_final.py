#!/usr/bin/env python3
"""
تقسيم d1_import.sql لأجزاء صغيرة قابلة للرفع
"""

import os
import re

input_file = "/home/adminlotfy/project/d1_import.sql"
output_dir = "/home/adminlotfy/project/d1_final_chunks"
inserts_per_chunk = 50  # 50 INSERT per file (~1.3 MB)

os.makedirs(output_dir, exist_ok=True)

print("📖 قراءة الملف...")

with open(input_file, 'r', encoding='utf-8') as f:
    content = f.read()

# Split schema and data
lines = content.split('\n')
schema_lines = []
data_lines = []
in_schema = True

for line in lines:
    if line.strip().startswith('INSERT INTO drugs'):
        in_schema = False
    
    if in_schema and line.strip():
        schema_lines.append(line)
    elif not in_schema and line.strip():
        data_lines.append(line)

print(f"📊 Schema: {len(schema_lines)} lines")
print(f"📊 Data: {len(data_lines)} INSERT statements")
print()

# Write schema file
schema_file = f"{output_dir}/00_schema.sql"
with open(schema_file, 'w', encoding='utf-8') as f:
    f.write('\n'.join(schema_lines))
print(f"✅ {schema_file}")

# Split data into chunks
chunk_num = 1
for i in range(0, len(data_lines), inserts_per_chunk):
    chunk = data_lines[i:i+inserts_per_chunk]
    chunk_file = f"{output_dir}/{chunk_num:02d}_data.sql"
    
    with open(chunk_file, 'w', encoding='utf-8') as f:
        f.write('\n'.join(chunk) + '\n')
    
    file_size = os.path.getsize(chunk_file) / (1024 * 1024)
    print(f"✅ {chunk_file} ({len(chunk)} INSERTs, {file_size:.2f} MB)")
    chunk_num += 1

total_chunks = chunk_num - 1
print()
print(f"✅ تم إنشاء {total_chunks + 1} ملف (schema + {total_chunks} data)")
print(f"📁 المجلد: {output_dir}/")
