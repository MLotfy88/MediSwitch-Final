#!/usr/bin/env python3
"""
Large File Manager
Splits large GZIP files into smaller chunks for Git storage, and reassembles them.
Target chunk size: ~45MB to be safe for GitHub (limit is 100MB, warning at 50MB).
"""

import sys
import os
import glob
import shutil

CHUNK_SIZE = 45 * 1024 * 1024  # 45 MB

def split_file(input_file, output_dir):
    """Splits a large file into chunks."""
    if not os.path.exists(input_file):
        print(f"❌ Input file not found: {input_file}")
        sys.exit(1)

    os.makedirs(output_dir, exist_ok=True)
    
    # Clean old chunks
    for f in glob.glob(os.path.join(output_dir, "part_*")):
        os.remove(f)

    print(f"🔪 Splitting {input_file} into {output_dir}...")
    
    chunk_num = 0
    with open(input_file, 'rb') as f_in:
        while True:
            chunk = f_in.read(CHUNK_SIZE)
            if not chunk:
                break
            
            chunk_name = f"part_{chunk_num:03d}.gz" # Keep .gz extension even on parts to clarify content type
            output_path = os.path.join(output_dir, chunk_name)
            
            with open(output_path, 'wb') as f_out:
                f_out.write(chunk)
                
            print(f"   Created {chunk_name} ({len(chunk)/1024/1024:.2f} MB)")
            chunk_num += 1
            
    print(f"✅ Split complete. Created {chunk_num} chunks.")

def join_files(input_dir, output_file):
    """Reassembles chunks into the original file."""
    parts = sorted(glob.glob(os.path.join(input_dir, "part_*")))
    
    if not parts:
        print(f"❌ No parts found in {input_dir}")
        sys.exit(1)
        
    print(f"🧩 Reassembling {len(parts)} parts into {output_file}...")
    
    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    
    with open(output_file, 'wb') as f_out:
        for part in parts:
            print(f"   Reading {os.path.basename(part)}...")
            with open(part, 'rb') as f_in:
                shutil.copyfileobj(f_in, f_out)
                
    if os.path.exists(output_file):
        print(f"✅ Reassembly successful: {output_file} ({os.path.getsize(output_file)/1024/1024:.2f} MB)")
    else:
        print("❌ Reassembly failed.")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage:")
        print("  Split: python manage_large_file.py split <input_file> <output_dir>")
        print("  Join:  python manage_large_file.py join <input_dir> <output_file>")
        sys.exit(1)
        
    action = sys.argv[1].lower()
    
    if action == 'split':
        split_file(sys.argv[2], sys.argv[3])
    elif action == 'join':
        join_files(sys.argv[2], sys.argv[3])
    else:
        print(f"Unknown action: {action}")
        sys.exit(1)
