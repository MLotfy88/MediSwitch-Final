import requests
import sqlite3
import time
import concurrent.futures
import random
import os
import re
from datetime import datetime
import threading
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Configuration
DB_PATH = 'mediswitch.db'
PROCESSED_FILE = 'processed_ids_v8.txt'
BASE_URL = "https://ddinter2.scbdd.com/server/interact/" # Corrected URL based on HTML analysis
START_ID = 1
END_ID = 60000 # Increased range based on user examples
MAX_WORKERS = 30 # High concurrency

# Headers to mimic browser
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
    'Referer': 'https://ddinter2.scbdd.com/',
    'Connection': 'keep-alive',
    'Upgrade-Insecure-Requests': '1'
}

# Thread-safe counters
class Counter:
    def __init__(self):
        self.value = 0
        self.lock = threading.Lock()
    def increment(self):
        with self.lock:
            self.value += 1
            return self.value

processed_count = Counter()
success_count = Counter()
fail_count = Counter()

def init_db():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute('''
        CREATE TABLE IF NOT EXISTS drug_interactions_v8 (
            id INTEGER PRIMARY KEY,
            ddinter_interaction_id INTEGER UNIQUE,
            drug_a_id TEXT,
            drug_b_id TEXT,
            severity TEXT,
            interaction_text TEXT,
            management_text TEXT,
            source TEXT
        )
    ''')
    conn.commit()
    conn.close()

def load_processed_ids():
    if not os.path.exists(PROCESSED_FILE):
        return set()
    with open(PROCESSED_FILE, 'r') as f:
        return set(line.strip() for line in f)

def save_processed_id(interaction_id):
    with open(PROCESSED_FILE, 'a') as f:
        f.write(f"{interaction_id}\n")

def extract_text(html, marker, end_marker="</td>"):
    try:
        start_idx = html.find(marker)
        if start_idx == -1: return None
        # Move past the marker and finding the value cell
        # The HTML structure is <td class="key">Title</td><td class="value">Content</td>
        
        # Find the next class="value" after the marker
        value_search_start = start_idx
        value_tag_start = html.find('class="value"', value_search_start)
        if value_tag_start == -1: return None
        
        content_start = html.find('>', value_tag_start) + 1
        content_end = html.find('</td>', content_start)
        
        if content_start != -1 and content_end != -1:
            raw_text = html[content_start:content_end]
            # Simple cleanup of tags
            clean_text = re.sub(r'<[^>]+>', '', raw_text).strip()
            # Cleanup extra whitespace
            clean_text = re.sub(r'\s+', ' ', clean_text)
            return clean_text
    except Exception:
        return None
    return None

def extract_ids(html):
    # Looking for: href="/server/drug-detail/DDInter20/"
    # Pattern: /server/drug-detail/(DDInter\d+)/
    ids = re.findall(r'/server/drug-detail/(DDInter\d+)/', html)
    if len(ids) >= 2:
        return ids[0], ids[1]
    return None, None

def scrape_interaction(interaction_id):
    url = f"{BASE_URL}{interaction_id}/"
    try:
        r = requests.get(url, headers=HEADERS, timeout=10, verify=False) # Skip SSL verify due to potential cert issues
        
        # Log progress every 50 requests
        total = processed_count.increment()
        if total % 10 == 0:
            print(f"Progress: {total} processed. Success: {success_count.value}, Failed: {fail_count.value}. Last ID: {interaction_id}")

        if r.status_code == 200:
            html = r.text
            
            # Check if valid page (contains "Interaction Information" or similar)
            if "Interaction Information" not in html and "DDInter" not in html:
                fail_count.increment()
                return # Likely empty or error page
            
            # Extract Data using Layout Analysis
            # 1. IDs
            drug_a, drug_b = extract_ids(html)
            if not drug_a or not drug_b:
                fail_count.increment()
                save_processed_id(interaction_id) # Mark as processed (empty/invalid)
                return

            # 2. Severity (Found in badge)
            # <span class="badge rounded-pill" style="background-color:#a8456b">Major</span>
            severity = "Unknown"
            if "Major" in html: severity = "Major"
            elif "Moderate" in html: severity = "Moderate"
            elif "Minor" in html: severity = "Minor"

            # 3. Text Fields
            interaction_text = extract_text(html, '>Interaction<')
            management_text = extract_text(html, '>Management<')

            # Save to DB
            conn = sqlite3.connect(DB_PATH)
            c = conn.cursor()
            c.execute('''
                INSERT OR REPLACE INTO drug_interactions_v8 
                (ddinter_interaction_id, drug_a_id, drug_b_id, severity, interaction_text, management_text, source)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ''', (interaction_id, drug_a, drug_b, severity, interaction_text, management_text, url))
            conn.commit()
            conn.close()

            success_count.increment()
            save_processed_id(interaction_id)
        
        elif r.status_code == 404:
            # Valid processed, just doesn't exist
            save_processed_id(interaction_id)
            fail_count.increment()
        else:
            # Temporary error, do not save as processed to retry later
            fail_count.increment()
            
    except Exception as e:
        fail_count.increment()
        print(f"Error scraping {interaction_id}: {e}")

def main():
    print(f"Starting HTML Scraper v8 for IDs {START_ID}-{END_ID}")
    init_db()
    processed = load_processed_ids()
    print(f"Loaded {len(processed)} previously processed IDs.")
    
    ids_to_scrape = [i for i in range(START_ID, END_ID + 1) if str(i) not in processed]
    print(f"Remaining IDs to scrape: {len(ids_to_scrape)}")
    
    with concurrent.futures.ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        executor.map(scrape_interaction, ids_to_scrape)
        
    print("Scraping completed.")

if __name__ == "__main__":
    main()
