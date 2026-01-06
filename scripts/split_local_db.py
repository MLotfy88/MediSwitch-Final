import os

def split_db(db_path, output_dir, chunk_size=45 * 1024 * 1024): # 45MB chunks to be safe (GitHub allows 100MB, but Android assets vary)
    if not os.path.exists(db_path):
        print(f"Error: Database file {db_path} not found.")
        return

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    part_suffixes = [
        'aa', 'ab', 'ac', 'ad', 'ae', 'af', 'ag', 'ah', 'ai', 'aj', 
        'ak', 'al', 'am', 'an', 'ao', 'ap', 'aq', 'ar', 'as', 'at'
    ]

    file_size = os.path.getsize(db_path)
    with open(db_path, 'rb') as f:
        part_num = 0
        while True:
            chunk = f.read(chunk_size)
            if not chunk:
                break
            
            if part_num >= len(part_suffixes):
                print("Error: Too many parts. Increase chunk size or add suffixes.")
                return

            part_name = f"mediswitch.db.part-{part_suffixes[part_num]}"
            output_path = os.path.join(output_dir, part_name)
            
            with open(output_path, 'wb') as out_f:
                out_f.write(chunk)
            
            print(f"Created {part_name} ({len(chunk)} bytes)")
            part_num += 1

    print(f"Successfully split {db_path} into {part_num} parts in {output_dir}")

if __name__ == "__main__":
    DB_PATH = "mediswitch.db" # Root project DB
    OUTPUT_DIR = "assets/database/parts"
    split_db(DB_PATH, OUTPUT_DIR)
