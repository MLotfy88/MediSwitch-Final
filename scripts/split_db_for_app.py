import os
import math

import shutil

DB_PATH = "assets/database/mediswitch.db"
OUTPUT_DIR = "assets/database/parts"
CHUNK_SIZE_MB = 45 # Slightly under 50MB to be safe and fit GitHub's 100MB limit easily

def split_database():
    if not os.path.exists(DB_PATH):
        print(f"Database file not found at {DB_PATH}")
        return

    # Clean previous parts
    if os.path.exists(OUTPUT_DIR):
        print(f"Cleaning existing parts in {OUTPUT_DIR}...")
        shutil.rmtree(OUTPUT_DIR)
    
    os.makedirs(OUTPUT_DIR)
    print(f"Created directory {OUTPUT_DIR}")

    file_size = os.path.getsize(DB_PATH)
    print(f"Database size: {file_size / (1024*1024):.2f} MB")

    # Part naming convention from Flutter app: aa, ab, ac...
    # The app expects: mediswitch.db.part-aa
    suffixes = [f"{chr(97)}{chr(97+i)}" for i in range(26)] # aa, ab, ac...
    
    with open(DB_PATH, 'rb') as f:
        chunk_num = 0
        while True:
            chunk = f.read(CHUNK_SIZE_MB * 1024 * 1024)
            if not chunk:
                break
            
            if chunk_num >= len(suffixes):
                print("Error: Too many parts for the hardcoded list in the app!")
                break
            
            suffix = suffixes[chunk_num]
            output_filename = f"mediswitch.db.part-{suffix}"
            output_path = os.path.join(OUTPUT_DIR, output_filename)
            
            with open(output_path, 'wb') as out_f:
                out_f.write(chunk)
            
            print(f"Created {output_filename} ({len(chunk) / (1024*1024):.2f} MB)")
            chunk_num += 1

    print(f"Successfully split into {chunk_num} parts.")

if __name__ == "__main__":
    split_database()
