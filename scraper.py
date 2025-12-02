#!/usr/bin/env python3
"""
MediSwitch Drug Scraper
Automated tool to scrape drug prices from dwaprices.com
"""

import requests
from bs4 import BeautifulSoup
import pandas as pd
import re
import time
import json
import sys
import random
from datetime import datetime

# --- Configuration ---
LOGIN_URL = "https://dwaprices.com/signin.php"
SERVER_URL = "https://dwaprices.com/server.php"
OUTPUT_FILE = "meds_updated.csv"
LOG_FILE = "scraper_log.txt"

# User Credentials
PHONE = "01558166440"
TOKEN = "bfwh2025-03-17"

# Scraping Settings
BATCH_SIZE = 100  # Number of records per request
MAX_RECORDS = None  # Maximum records to fetch (set to None for all records)
MIN_DELAY = 2.0   # Minimum delay between requests (seconds)
MAX_DELAY = 5.0   # Maximum delay between requests (seconds)
LONG_PAUSE_EVERY = 10  # Add longer pause every N batches
LONG_PAUSE_MIN = 8.0   # Minimum long pause duration
LONG_PAUSE_MAX = 15.0  # Maximum long pause duration
MAX_RETRIES = 3   # Max retry attempts for failed requests

# User Agents Pool (for rotation)
USER_AGENTS = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
]

# Regex for Concentration Extraction
CONCENTRATION_REGEX = re.compile(
    r"""
    (                          # Start capturing group 1
        \d+ (?:[.,]\d+)?       # Match number (integer or decimal with . or ,)
        \s*                    # Optional whitespace
        (?:mg|mcg|g|kg|ml|l|iu|%) # Match common units (case-insensitive)
        (?:                    # Optional second part for compound units (e.g., /ml)
            \s* / \s*          # Match '/' surrounded by optional spaces
            (?:ml|mg|g|kg|l)   # Match second unit (case-insensitive)
        )?
    )                          # End capturing group 1
    """,
    re.IGNORECASE | re.VERBOSE
)

def log(message):
    """Log message to console and file"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_msg = f"[{timestamp}] {message}"
    print(log_msg)
    with open(LOG_FILE, 'a', encoding='utf-8') as f:
        f.write(log_msg + '\n')

def extract_concentration(name):
    """Extracts concentration from drug name using regex."""
    if not isinstance(name, str):
        return None
    match = CONCENTRATION_REGEX.search(name)
    if match:
        return match.group(1).strip()
    return None

def get_random_user_agent():
    """Return a random user agent from the pool"""
    return random.choice(USER_AGENTS)

def random_delay(is_long=False):
    """Sleep for a random duration to avoid detection"""
    if is_long:
        delay = random.uniform(LONG_PAUSE_MIN, LONG_PAUSE_MAX)
        log(f"⏸ Taking a longer break ({delay:.1f}s) to simulate natural behavior...")
    else:
        delay = random.uniform(MIN_DELAY, MAX_DELAY)
    time.sleep(delay)

def login(session):
    """Performs the two-step login process."""
    log("Attempting to login...")
    
    # Update User-Agent
    session.headers.update({'User-Agent': get_random_user_agent()})
    
    # Step 1: Check Credentials
    payload_step1 = {
        'checkLoginForPrices': 1,
        'phone': PHONE,
        'tokenn': TOKEN
    }
    
    try:
        response1 = session.post(SERVER_URL, data=payload_step1, timeout=15)
        response1.raise_for_status()
        
        try:
            data1 = response1.json()
        except json.JSONDecodeError:
            log("ERROR: Failed to parse JSON response from server.php")
            log(f"Response text: {response1.text[:200]}")
            return False

        if data1.get('numrows', 0) > 0 and 'data' in data1:
            user_data = data1['data'][0]
            log(f"✓ Credentials verified for user: {user_data.get('name')}")
            
            # Step 2: Set Session
            payload_step2 = {
                'accessgranted': 1,
                'namepricesub': user_data.get('name'),
                'phonepricesub': user_data.get('phone'),
                'tokenpricesub': user_data.get('token'),
                'grouppricesub': user_data.get('usergroup'),
                'approvedsub': user_data.get('approved'),
                'IDpricesub': user_data.get('id')
            }
            
            response2 = session.post(LOGIN_URL, data=payload_step2, timeout=15)
            response2.raise_for_status()
            
            log("✓ Session established successfully.")
            return True
        else:
            log("ERROR: Login failed - Invalid credentials or no data returned.")
            return False
            
    except requests.RequestException as e:
        log(f"ERROR: Login failed - {e}")
        return False

def fetch_batch(session, offset, retry_count=0):
    """Fetch a batch of records using AJAX call"""
    try:
        # Rotate User-Agent occasionally
        if offset % 500 == 0 and offset > 0:
            session.headers.update({'User-Agent': get_random_user_agent()})
        
        payload = {
            'lastprices': offset
        }
        
        response = session.post(SERVER_URL, data=payload, timeout=20)
        response.raise_for_status()
        
        data = response.json()
        return data
        
    except requests.RequestException as e:
        if retry_count < MAX_RETRIES:
            log(f"⚠ Request failed (attempt {retry_count + 1}/{MAX_RETRIES}): {e}")
            time.sleep(2 ** retry_count)  # Exponential backoff
            return fetch_batch(session, offset, retry_count + 1)
        else:
            log(f"ERROR: Failed to fetch batch at offset {offset} after {MAX_RETRIES} retries")
            return None
    except json.JSONDecodeError as e:
        log(f"ERROR: Failed to parse JSON at offset {offset}: {e}")
        return None

def save_incremental(all_meds, batch_num):
    """Save data incrementally to the same file to avoid data loss"""
    if not all_meds:
        return
    
    output_file = "meds_updated.csv"
    processed_meds = []
    
    for item in all_meds:
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
        
        med_data = {
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
        }
        processed_meds.append(med_data)
    
    df = pd.DataFrame(processed_meds)
    df.to_csv(output_file, index=False, encoding='utf-8-sig')
    log(f"💾 Auto-saved {len(df)} records to {output_file} (Batch {batch_num})")

def scrape_all_data(session):
    """Scrapes all data from the website using pagination"""
    log("Starting data scraping...")
    
    all_meds = []
    offset = 0
    total_records = None
    
    # First request to get total count
    first_batch = fetch_batch(session, offset)
    if not first_batch:
        log("ERROR: Failed to fetch initial batch")
        return []
    
    total_records = first_batch.get('numrows', 0)
    log(f"✓ Total records available: {total_records}")
    
    # Apply MAX_RECORDS limit if set
    if MAX_RECORDS and MAX_RECORDS < total_records:
        log(f"⚠ Limiting scrape to {MAX_RECORDS} records (user setting)")
        total_records = MAX_RECORDS
    
    if 'data' in first_batch and first_batch['data']:
        all_meds.extend(first_batch['data'])
        log(f"✓ Fetched batch 1: {len(first_batch['data'])} records (Total: {len(all_meds)}/{total_records})")
        # Auto-save after first batch
        save_incremental(all_meds, 1)
    
    random_delay()
    
    # Continue fetching remaining batches
    batch_num = 2
    while len(all_meds) < total_records:
        offset += BATCH_SIZE
        
        batch_data = fetch_batch(session, offset)
        if not batch_data or 'data' not in batch_data or not batch_data['data']:
            log(f"⚠ No more data at offset {offset}, stopping.")
            break
        
        all_meds.extend(batch_data['data'])
        log(f"✓ Fetched batch {batch_num}: {len(batch_data['data'])} records (Total: {len(all_meds)}/{total_records})")
        
        # Auto-save after each batch
        save_incremental(all_meds, batch_num)
        
        # Check if we reached the limit
        if len(all_meds) >= total_records:
            log(f"✓ Reached target of {total_records} records, stopping.")
            break
        
        batch_num += 1
        
        # Add longer pause every N batches to simulate natural behavior
        if batch_num % LONG_PAUSE_EVERY == 0:
            random_delay(is_long=True)
        else:
            random_delay()
        
        # Safety break if we exceed expected total
        if len(all_meds) > total_records + 100:
            log("⚠ Warning: Fetched more records than expected, stopping.")
            break
    
    log(f"✓ Scraping complete. Total records fetched: {len(all_meds)}")
    return all_meds

def process_and_save(raw_data):
    """Process raw data and save to CSV"""
    log("Processing data...")
    
    processed_meds = []
    
    for item in raw_data:
        # Extract concentration from name
        trade_name = item.get('name', '')
        concentration = extract_concentration(trade_name)
        
        # Convert date_updated (Unix timestamp in milliseconds)
        date_updated = item.get('Date_updated')
        if date_updated:
            try:
                timestamp = int(date_updated) / 1000  # Convert to seconds
                date_str = datetime.fromtimestamp(timestamp).strftime('%d/%m/%Y')
            except:
                date_str = ''
        else:
            date_str = ''
        
        med_data = {
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
        }
        processed_meds.append(med_data)
    
    # Create DataFrame
    df = pd.DataFrame(processed_meds)
    
    # Save to CSV
    log(f"Saving {len(df)} records to {OUTPUT_FILE}...")
    df.to_csv(OUTPUT_FILE, index=False, encoding='utf-8-sig')
    log(f"✓ Data saved successfully to {OUTPUT_FILE}")
    
    # Display summary statistics
    log("\n" + "="*60)
    log("SUMMARY STATISTICS")
    log("="*60)
    log(f"Total drugs scraped: {len(df)}")
    log(f"Drugs with concentration extracted: {df['concentration'].notna().sum()}")
    log(f"Drugs with price updates: {df['last_price_update'].notna().sum()}")
    log(f"Unique companies: {df['company'].nunique()}")
    log("="*60)
    
    # Show sample
    log("\nSample of scraped data (first 5 records):")
    log(df[['trade_name', 'price', 'old_price', 'concentration', 'last_price_update']].head().to_string())
    
    return df

def main():
    """Main execution function"""
    log("="*60)
    log("MediSwitch Drug Scraper - Starting")
    log("="*60)
    
    session = requests.Session()
    session.headers.update({
        'User-Agent': get_random_user_agent(),
        'Accept': 'application/json, text/javascript, */*; q=0.01',
        'Accept-Language': 'ar,en-US;q=0.9,en;q=0.8',
        'X-Requested-With': 'XMLHttpRequest',  # Important for AJAX
        'Referer': 'https://dwaprices.com/lastmore.php'
    })
    
    if login(session):
        raw_data = scrape_all_data(session)
        
        if raw_data:
            df = process_and_save(raw_data)
            log(f"\n✓ SUCCESS: Scraping completed! {len(df)} records saved to {OUTPUT_FILE}")
            return 0
        else:
            log("\nERROR: No data was scraped.")
            return 1
    else:
        log("\nERROR: Aborting due to login failure.")
        return 1

if __name__ == "__main__":
    try:
        exit_code = main()
        sys.exit(exit_code)
    except KeyboardInterrupt:
        log("\n⚠ Scraping interrupted by user.")
        sys.exit(130)
    except Exception as e:
        log(f"\n✗ FATAL ERROR: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
