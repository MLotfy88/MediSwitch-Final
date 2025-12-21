#!/usr/bin/env python3
"""
Create smaller chunks - 100 rows per chunk for better success rate
"""

import os

input_file = "/home/adminlotfy/project/d1_import.sql"
output_dir = "/home/adminlotfy/project/d1_chunks_small"
rows_per_chunk = 100

os.makedirs(output_dir, exist_ok=True)

print(f"📖 Reading {input_file}...")

with open(input_file, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Separate schema from data
schema_lines = []
data_lines = []
in_schema = True

for line in lines:
    if line.strip().startswith('INSERT INTO'):
        in_schema = False
    
    if in_schema:
        schema_lines.append(line)
    else:
        data_lines.append(line)

print(f"📊 Data: {len(data_lines)} INSERT statements")

# Write schema
schema_file = f"{output_dir}/drugs_schema.sql"
with open(schema_file, 'w', encoding='utf-8') as f:
    f.writelines(schema_lines)
print(f"✅ Schema: {schema_file}")

# Split data into smaller chunks
chunk_num = 1
for i in range(0, len(data_lines), rows_per_chunk):
    chunk = data_lines[i:i+rows_per_chunk]
    chunk_file = f"{output_dir}/chunk_{chunk_num:04d}.sql"
    
    with open(chunk_file, 'w', encoding='utf-8') as f:
        f.writelines(chunk)
    
    if chunk_num % 50 == 0:
        print(f"  Created chunk {chunk_num}...")
    
    chunk_num += 1

total_chunks = chunk_num - 1
print(f"\n✅ Created {total_chunks} chunks of {rows_per_chunk} rows each")
print(f"📁 Output: {output_dir}/")
