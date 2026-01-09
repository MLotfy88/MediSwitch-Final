
import os

CHUNK_SIZE = 50 * 1024 * 1024  # 50MB
INPUT_FILE = '/home/adminlotfy/project/assets/database/mediswitch.db'
OUTPUT_DIR = '/home/adminlotfy/project/assets/database/parts/'

def split_file():
    if not os.path.exists(INPUT_FILE):
        print(f"Error: Input file {INPUT_FILE} not found.")
        return

    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)

    file_size = os.path.getsize(INPUT_FILE)
    print(f"Splitting {INPUT_FILE} ({file_size / (1024*1024):.2f} MB)...")

    part_num = 0
    with open(INPUT_FILE, 'rb') as infile:
        while True:
            chunk = infile.read(CHUNK_SIZE)
            if not chunk:
                break
            
            # Generate part suffix: aa, ab, ac...
            # This logic assumes < 26*26 parts, which is fine for < 30GB DB
            suffix_1 = chr(ord('a') + (part_num // 26))
            suffix_2 = chr(ord('a') + (part_num % 26))
            part_name = f"mediswitch.db.part-{suffix_1}{suffix_2}"
            part_path = os.path.join(OUTPUT_DIR, part_name)
            
            with open(part_path, 'wb') as outfile:
                outfile.write(chunk)
            
            print(f"Created {part_name} ({len(chunk) / (1024*1024):.2f} MB)")
            part_num += 1

    print(f"✅ Splitting complete. Created {part_num} parts.")

if __name__ == "__main__":
    split_file()
