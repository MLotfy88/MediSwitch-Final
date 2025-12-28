
import requests
import sqlite3
import concurrent.futures
import time
import sys
import os
import threading

# --- CONFIGURATION (GITHUB ACTION OPTIMIZED) ---
MAX_WORKERS = 50                    # Increased for Cloud Environments
DB_PATH = "mediswitch.db"           # Output DB
PROCESSED_FILE = "processed_ids.txt" # Resume file
BASE_URL = "http://ddinter.scbdd.com/ddinter/api/interaction/detail/"
START_ID = 1
END_ID = 40000                      # Estimated max ID

# --- GLOBAL STATS ---
lock = threading.Lock()
stats = {
    "scanned": 0,
    "success": 0,
    "empty": 0,
    "failed": 0,
    "start_time": time.time()
}

def get_processed_ids():
    if not os.path.exists(PROCESSED_FILE):
        return set()
    with open(PROCESSED_FILE, "r") as f:
        return set(line.strip() for line in f if line.strip())

def save_processed_id(drug_id):
    with lock:
        with open(PROCESSED_FILE, "a") as f:
            f.write(f"{drug_id}\n")

def init_db():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS drug_interactions
                 (id INTEGER PRIMARY KEY AUTOINCREMENT,
                  ingredient1 TEXT,
                  ingredient2 TEXT,
                  severity TEXT,
                  effect TEXT,
                  source TEXT,
                  updated_at INTEGER)''')
    conn.commit()
    conn.close()

def log_progress(current_id):
    with lock:
        elapsed = time.time() - stats["start_time"]
        speed = stats["scanned"] / elapsed if elapsed > 0 else 0
        
        # Consistent format with local script
        sys.stdout.write(
            f"\r🚀 [GitHub Turbo] ID: {current_id} | "
            f"✅ Found: {stats['success']} | "
            f"❌ Fail/Empty: {stats['empty'] + stats['failed']} | "
            f"Speed: {speed:.1f} req/s"
        )
        sys.stdout.flush()

def scrape_interaction(drug_id):
    url = f"{BASE_URL}{drug_id}/"
    try:
        # NO TIMEOUT DELAY - Go as fast as possible
        response = requests.get(url, timeout=5) 
        
        with lock:
            stats["scanned"] += 1
            
        if response.status_code == 200:
            data = response.json()
            if data and 'drug_a' in data and 'drug_b' in data:
                # Valid interaction found
                ing1 = data['drug_a']
                ing2 = data['drug_b']
                severity = data.get('level', 'Unknown')
                effect = data.get('desc', 'No description')
                
                # Save to DB
                conn = sqlite3.connect(DB_PATH)
                c = conn.cursor()
                c.execute("INSERT INTO drug_interactions (ingredient1, ingredient2, severity, effect, source, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
                          (ing1, ing2, severity, effect, 'ddinter', int(time.time())))
                conn.commit()
                conn.close()
                
                with lock:
                    stats["success"] += 1
                
                save_processed_id(drug_id)
                log_progress(drug_id)
                return True
            else:
                with lock:
                    stats["empty"] += 1
                save_processed_id(drug_id) # Mark as processed even if empty to skip next time
                log_progress(drug_id)
                return False
        else:
            with lock:
                stats["failed"] += 1
            # Don't save ID if failed (allows retry)
            log_progress(drug_id)
            return False
            
    except Exception as e:
        with lock:
            stats["failed"] += 1
        log_progress(drug_id)
        return False

def main():
    print("⚡ Starting GITHUB TURBO Scraper (DDInter)...")
    init_db()
    
    processed = get_processed_ids()
    print(f"📖 Loaded {len(processed)} processed IDs. Resuming...")
    
    ids_to_scrape = [i for i in range(START_ID, END_ID + 1) if str(i) not in processed]
    print(f"🎯 Target: {len(ids_to_scrape)} IDs remaining.")
    
    if not ids_to_scrape:
        print("✅ All done!")
        return

    # ThreadPool for concurrency
    with concurrent.futures.ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        # Map IDs to the scraper function
        executor.map(scrape_interaction, ids_to_scrape)
        
    print("\n✅ Scraping Session Finished.")

if __name__ == "__main__":
    main()
