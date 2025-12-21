#!/usr/bin/env python3
"""
Convert INSERT INTO to REPLACE INTO for D1 upload
"""

import os
import re

input_file = "/home/adminlotfy/project/d1_import.sql"
output_file = "/home/adminlotfy/project/d1_import_replace.sql"

print(f"📖 Reading {input_file}...")

with open(input_file, 'r', encoding='utf-8') as f:
    content = f.read()

print("🔄 Converting INSERT INTO → REPLACE INTO...")

# Replace all INSERT INTO with REPLACE INTO
content = re.sub(r'INSERT INTO', 'REPLACE INTO', content)

# Write output
with open(output_file, 'w', encoding='utf-8') as f:
    f.write(content)

print(f"✅ Created {output_file}")

# Now create small chunks
output_dir = "/home/adminlotfy/project/d1_chunks_replace"
os.makedirs(output_dir, exist_ok=True)

lines = content.split('\n')

# Separate schema from data
schema_lines = []
data_lines = []
in_schema = True

for line in lines:
    if line.strip().startswith('REPLACE INTO'):
        in_schema = False
    
    if in_schema:
        schema_lines.append(line)
    else:
        if line.strip():  # Skip empty lines
            data_lines.append(line)

print(f"📊 Data: {len(data_lines)} REPLACE statements")

# Write schema
schema_file = f"{output_dir}/schema.sql"
with open(schema_file, 'w', encoding='utf-8') as f:
    f.write('\n'.join(schema_lines))
print(f"✅ Schema: {schema_file}")

# Split into chunks of 50 (smaller!)
rows_per_chunk = 50
chunk_num = 1

for i in range(0, len(data_lines), rows_per_chunk):
    chunk = data_lines[i:i+rows_per_chunk]
    chunk_file = f"{output_dir}/chunk_{chunk_num:04d}.sql"
    
    with open(chunk_file, 'w', encoding='utf-8') as f:
        f.write('\n'.join(chunk) + '\n')
    
    if chunk_num % 100 == 0:
        print(f"  Created chunk {chunk_num}...")
    
    chunk_num += 1

total_chunks = chunk_num - 1
print(f"\n✅ Created {total_chunks} chunks of {rows_per_chunk} REPLACE statements each")
print(f"📁 Output: {output_dir}/")
