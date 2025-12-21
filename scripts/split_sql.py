#!/usr/bin/env python3
"""
Split large SQL file into manageable chunks for D1 upload
"""

import os

def split_sql_file(input_file, output_prefix, lines_per_chunk=500):
    """Split SQL file into chunks."""
    
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
    
    print(f"📊 Schema: {len(schema_lines)} lines")
    print(f"📊 Data: {len(data_lines)} lines")
    
    # Write schema file
    schema_file = f"{output_prefix}_schema.sql"
    with open(schema_file, 'w', encoding='utf-8') as f:
        f.writelines(schema_lines)
    print(f"✅ Created {schema_file}")
    
    # Split data into chunks
    chunk_num = 1
    for i in range(0, len(data_lines), lines_per_chunk):
        chunk = data_lines[i:i+lines_per_chunk]
        chunk_file = f"{output_prefix}_chunk_{chunk_num}.sql"
        
        with open(chunk_file, 'w', encoding='utf-8') as f:
            f.writelines(chunk)
        
        print(f"✅ Created {chunk_file} ({len(chunk)} lines)")
        chunk_num += 1
    
    print(f"\n✅ Split complete! Created {chunk_num} files")
    return chunk_num - 1


if __name__ == "__main__":
    input_file = "/home/adminlotfy/project/d1_import.sql"
    output_prefix = "/home/adminlotfy/project/d1_chunks/drugs"
    
    os.makedirs("/home/adminlotfy/project/d1_chunks", exist_ok=True)
    
    num_chunks = split_sql_file(input_file, output_prefix, lines_per_chunk=500)
    
    print(f"\n📤 To upload, run:")
    print(f"   wrangler d1 execute mediswitch-db --remote --file=d1_chunks/drugs_schema.sql")
    for i in range(1, num_chunks + 1):
        print(f"   wrangler d1 execute mediswitch-db --remote --file=d1_chunks/drugs_chunk_{i}.sql")
