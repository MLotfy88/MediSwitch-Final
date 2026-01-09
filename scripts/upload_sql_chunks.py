import os
import subprocess
import time
import argparse

CLOUDFLARE_API_TOKEN = "yy-vk8KC4yth3Cn2lpva1AgrP2kGMJrQQrGIUM1-"
CLOUDFLARE_EMAIL = "eedf653449abdca28e865ddf3511dd4c62ed2"
DATABASE_NAME = "mediswitsh-db"
SQL_DIR = "d1_sql_chunks"

PROGRESS_FILE = "upload_progress.txt"

def get_completed_files():
    if not os.path.exists(PROGRESS_FILE):
        return set()
    with open(PROGRESS_FILE, "r") as f:
        return set(line.strip() for line in f if line.strip())

def mark_completed(filename):
    with open(PROGRESS_FILE, "a") as f:
        f.write(filename + "\n")

def upload_chunks():
    env = {
        "CLOUDFLARE_API_TOKEN": CLOUDFLARE_API_TOKEN,
        "CLOUDFLARE_EMAIL": CLOUDFLARE_EMAIL,
        "PATH": os.environ.get("PATH", "")
    }

    if not os.path.exists(SQL_DIR):
        print(f"Directory {SQL_DIR} not found.")
        return

    parser = argparse.ArgumentParser()
    parser.add_argument("--start-index", type=int, default=0, help="Index of the chunk to start from")
    args = parser.parse_args()

    files = sorted([f for f in os.listdir(SQL_DIR) if f.endswith(".sql")])
    if not files:
        print(f"❌ Error: No SQL files found in {SQL_DIR}!")
        exit(1)
        
    print(f"Found {len(files)} SQL chunks to process. Starting from index {args.start_index}.")
    
    completed_files = get_completed_files()
    
    for i, filename in enumerate(files):
        # Calculate numeric index logic if needed, but simple list index is easier regarding the 'start input' context
        # The user sees "Start from file number". 
        if i < args.start_index:
             print(f"[{i+1}/{len(files)}] Skipping {filename} (Index {i} < {args.start_index})")
             continue

        if filename in completed_files:
            print(f"[{i+1}/{len(files)}] Skipping {filename} (Already uploaded)")
            continue

        print(f"[{i+1}/{len(files)}] Uploading {filename}...")
        path = os.path.join(SQL_DIR, filename)
        
        # Use npx wrangler d1 execute
        cmd = f"npx wrangler d1 execute {DATABASE_NAME} --file={path} --remote"
        
        success = False
        for attempt in range(3):
            try:
                result = subprocess.run(
                    cmd, 
                    shell=True, 
                    check=True, 
                    stdout=subprocess.PIPE, 
                    stderr=subprocess.PIPE, 
                    text=True, 
                    env=env
                )
                print(f"  ✅ Success")
                mark_completed(filename)
                success = True
                time.sleep(3)  # تأخير 3 ثوان لتجنب قيود معدل الطلبات
                break
            except subprocess.CalledProcessError as e:
                print(f"  ❌ Attempt {attempt+1} failed: {e.stderr[:200]}")
                time.sleep(2)
        
        if not success:
            print(f"  🛑 Stopping due to persistent failure in {filename}")
            break

if __name__ == "__main__":
    upload_chunks()
