#!/usr/bin/env python3
"""
Incremental Drug Scraper for GitHub Actions
Fetches only drugs updated after a specific date
"""

import requests
import pandas as pd
import re
import time
import json
import sys
import random
import os
from datetime import datetime

# --- Configuration from Environment Variables ---
PHONE = os.getenv('PHONE', '01558166440')
TOKEN = os.getenv('TOKEN', 'bfwh2025-03-17')
LAST_UPDATE_DATE = os.getenv('LAST_UPDATE_DATE', '01/01/2020')  # Format: dd/mm/yyyy

LOGIN_URL = "https://dwaprices.com/signin.php"
SERVER_URL = "https://dwaprices.com/server.php"
OUTPUT_FILE = "new_drugs.csv"

# Scraping Settings
BATCH_SIZE = 100
MIN_DELAY = 2.0
MAX_DELAY = 4.0
MAX_RETRIES = 3

USER_AGENTS = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
]

CONCENTRATION_REGEX = re.compile(
    r"""
    (
        \d+ (?:[.,]\d+)?
        \s*
        (?:mg|mcg|g|kg|ml|l|iu|%)
        (?:
            \s* / \s*
            (?:ml|mg|g|kg|l)
        )?
    )
    """,
    re.IGNORECASE | re.VERBOSE
)

def log(message):
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {message}")

def extract_concentration(name):
    if not isinstance(name, str):
        return None
    match = CONCENTRATION_REGEX.search(name)
    return match.group(1).strip() if match else None

def parse_date(date_str):
    """Parse date string in dd/mm/yyyy format"""
    try:
        return datetime.strptime(date_str, '%d/%m/%Y')
    except:
        return None

def login(session):
    log("Logging in...")
    session.headers.update({
        'User-Agent': random.choice(USER_AGENTS),
        'Accept': 'application/json, text/javascript, */*; q=0.01',
        'X-Requested-With': 'XMLHttpRequest',
        'Referer': 'https://dwaprices.com/lastmore.php'
    })
    
    payload = {
        'checkLoginForPrices': 1,
        'phone': PHONE,
        'tokenn': TOKEN
    }
    
    try:
        response = session.post(SERVER_URL, data=payload, timeout=15)
        data = response.json()
        
        if data.get('numrows', 0) > 0 and 'data' in data:
            user_data = data['data'][0]
            log(f"✓ Logged in as: {user_data.get('name')}")
            
            session.post(LOGIN_URL, data={
                'accessgranted': 1,
                'namepricesub': user_data.get('name'),
                'phonepricesub': user_data.get('phone'),
                'tokenpricesub': user_data.get('token'),
                'grouppricesub': user_data.get('usergroup'),
                'approvedsub': user_data.get('approved'),
                'IDpricesub': user_data.get('id')
            }, timeout=15)
            return True
    except Exception as e:
        log(f"✗ Login failed: {e}")
    return False

def fetch_batch(session, offset):
    try:
        response = session.post(SERVER_URL, data={'lastprices': offset}, timeout=20)
        return response.json()
    except:
        return None

def is_newer_than_cutoff(item, cutoff_date):
    """Check if drug was updated after the cutoff date"""
    date_updated = item.get('Date_updated')
    if not date_updated:
        return False
    
    try:
        timestamp = int(date_updated) / 1000
        drug_date = datetime.fromtimestamp(timestamp)
        return drug_date > cutoff_date
    except:
        return False

def scrape_incremental(session, cutoff_date):
    log(f"Fetching drugs updated after: {cutoff_date.strftime('%d/%m/%Y')}")
    
    new_meds = []
    offset = 0
    stop_scraping = False
    batch_num = 1
    
    # First batch
    first_batch = fetch_batch(session, offset)
    if not first_batch or 'data' not in first_batch:
        log("✗ Failed to fetch data")
        return []
    
    total_available = first_batch.get('numrows', 0)
    log(f"Total drugs in database: {total_available}")
    
    # Process first batch
    for item in first_batch['data']:
        if is_newer_than_cutoff(item, cutoff_date):
            new_meds.append(item)
        else:
            stop_scraping = True
            break
    
    log(f"Batch {batch_num}: Found {len(new_meds)} new drugs")
    
    if stop_scraping:
        log("✓ Reached cutoff date, stopping.")
        return new_meds
    
    time.sleep(random.uniform(MIN_DELAY, MAX_DELAY))
    
    # Continue with remaining batches
    while not stop_scraping and len(new_meds) < total_available:
        offset += BATCH_SIZE
        batch_num += 1
        
        batch_data = fetch_batch(session, offset)
        if not batch_data or 'data' not in batch_data:
            break
        
        batch_new_count = 0
        for item in batch_data['data']:
            if is_newer_than_cutoff(item, cutoff_date):
                new_meds.append(item)
                batch_new_count += 1
            else:
                stop_scraping = True
                break
        
        log(f"Batch {batch_num}: Found {batch_new_count} new drugs (Total: {len(new_meds)})")
        
        if stop_scraping:
            log("✓ Reached cutoff date, stopping.")
            break
        
        time.sleep(random.uniform(MIN_DELAY, MAX_DELAY))
        
        # Safety: stop after 50 batches (5000 drugs)
        if batch_num >= 50:
            log("⚠ Safety limit reached (50 batches)")
            break
    
    log(f"✓ Scraping complete. Found {len(new_meds)} new/updated drugs")
    return new_meds

def process_and_save(raw_data):
    if not raw_data:
        log("No new data to save")
        return
    
    processed_meds = []
    for item in raw_data:
        trade_name = item.get('name', '')
        concentration = extract_concentration(trade_name)
        date_updated = item.get('Date_updated')
        
        if date_updated:
            try:
                timestamp = int(date_updated) / 1000
                date_str = datetime.fromtimestamp(timestamp).strftime('%d/%m/%Y')
            except:
                date_str = ''
        else:
            date_str = ''
        
        processed_meds.append({
            'trade_name': trade_name,
            'arabic_name': item.get('arabic', ''),
            'price': item.get('price', ''),
            'old_price': item.get('oldprice', ''),
            'active': item.get('active', ''),
            'company': item.get('company', ''),
            'description': item.get('description', ''),
            'dosage_form': item.get('dosage_form', ''),
            'concentration': concentration,
            'last_price_update': date_str,
            'visits': item.get('visits', ''),
            'id': item.get('id', '')
        })
    
    df = pd.DataFrame(processed_meds)
    df.to_csv(OUTPUT_FILE, index=False, encoding='utf-8-sig')
    log(f"✓ Saved {len(df)} drugs to {OUTPUT_FILE}")

def main():
    log("=== Incremental Drug Scraper ===")
    
    # Parse cutoff date
    cutoff_date = parse_date(LAST_UPDATE_DATE)
    if not cutoff_date:
        log(f"✗ Invalid date format: {LAST_UPDATE_DATE}")
        return 1
    
    session = requests.Session()
    
    if not login(session):
        log("✗ Login failed")
        return 1
    
    new_data = scrape_incremental(session, cutoff_date)
    process_and_save(new_data)
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
