#!/usr/bin/env python3
"""
MediSwitch High-Performance Scraper (Async)
Fetches full drug details concurrently from dwaprices.com.
"""

import aiohttp
import asyncio
import aiofiles
import pandas as pd
from bs4 import BeautifulSoup
import re
import time
import json
import sys
import os
import random
from datetime import datetime
from typing import List, Dict

# --- Configuration ---
LOGIN_URL = "https://dwaprices.com/signin.php"
SERVER_URL = "https://dwaprices.com/server.php"
BASE_URL = "https://dwaprices.com/med.php?id="
MEDS_CSV = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'assets', 'meds.csv')
OUTPUT_FILE = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'assets', 'meds_scraped_new.jsonl')
LOG_FILE = "scraper_async.log"

# Credentials
PHONE = "01558166440"
TOKEN = "bfwh2025-03-17"

# Performance Settings
CONCURRENCY = 10 # Number of simultaneous requests
REQUEST_TIMEOUT = 30

USER_AGENTS = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
]

def log(message):
    ts = datetime.now().strftime('%H:%M:%S')
    print(f"[{ts}] {message}", flush=True)
    with open(LOG_FILE, 'a', encoding='utf-8') as f:
        f.write(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {message}\n")

def clean_text(text):
    if not text: return ""
    return re.sub(r'\s+', ' ', text).strip()

def parse_drug_page(html: str, drug_id: str) -> Dict:
    """Parses the HTML content."""
    soup = BeautifulSoup(html, 'html.parser')
    text = soup.get_text("\n")
    data = {'id': drug_id}
    
    # 1. Arabic Name (Extract FIRST for form guessing)
    h1 = soup.find('h1')
    if h1:
        raw_ar = clean_text(h1.text)
        data['arabic_name'] = raw_ar.replace('سعر', '').strip()
    else:
        data['arabic_name'] = ""

    # 2. Regex Extraction
    patterns = {
        'trade_name': r'الاسم التجاري.*?[:]?\s*\n+(.*?)\n',
        'active': r'الاسم العلمي.*?[:]?\s*\n+(.*?)\n',
        'company': r'الشركة المنتجة.*?[:]?\s*\n+(.*?)\n',
        'price': r'السعر الجديد الحالي.*?[:]?\s*\n+(\d+(?:\.\d+)?)',
        'old_price': r'السعر القديم.*?[:]?\s*\n+(\d+(?:\.\d+)?)',
        'category': r'التصنيف الدوائي.*?[:]?\s*\n+(.*?)\n',
        'last_update': r'آخر تحديث.*?[:]?\s*\n+(.*?)\n',
        'units': r'عدد الوحدات.*?[:]?\s*\n+(.*?)\n',
        'unit_price': r'سعر الوحدة.*?[:]?\s*\n+(\d+(?:\.\d+)?)',
        'barcode': r'رمز الباركود.*?[:]?\s*\n+(\d+)',
        'qr_code': r'رمز الكيو آر كود.*?[:]?\s*\n+(.*?)\n',
        'pharmacology': r'الفارماكولوجي.*?[:]?\s*\n+(.*?)\n',
        'usage': r'دواعي استعمال.*?[:]?\s*\n+(.*?)\n',
    }
    
    for key, pat in patterns.items():
        match = re.search(pat, text)
        data[key] = clean_text(match.group(1)) if match else ""

    # Safety: clean active (sometimes leaks headers)
    if "التصنيف" in data['active']: data['active'] = "" 

    # Visits
    visits_match = re.search(r'قام عدد.*?(\d+).*?شخص', text, re.DOTALL)
    data['visits'] = visits_match.group(1) if visits_match else ""

    # 3. Derived Fields
    # Concentration from Trade Name
    conc_match = re.search(r'(\d+(?:\.\d+)?)\s*(?:mg|gm|ml|mcg|unit|iu|%)', data.get('trade_name', ''), re.IGNORECASE)
    data['concentration'] = conc_match.group(0) if conc_match else ""
    
    # Dosage Form Guessing
    trade_lower = data.get('trade_name', '').lower()
    arabic = data.get('arabic_name', '')
    
    form = 'Unknown'
    if 'tab' in trade_lower or 'اقراص' in arabic: form = 'Tablet'
    elif 'cap' in trade_lower or 'كبسول' in arabic: form = 'Capsule'
    elif 'syr' in trade_lower or 'شراب' in arabic: form = 'Syrup'
    elif 'vial' in trade_lower or 'amp' in trade_lower or 'حقن' in arabic: form = 'Vial/Amp'
    elif 'cream' in trade_lower or 'كريم' in arabic: form = 'Cream'
    elif 'oint' in trade_lower or 'مرهم' in arabic: form = 'Ointment'
    elif 'drop' in trade_lower or 'نقط' in arabic: form = 'Drops'
    elif 'supp' in trade_lower or 'لبوس' in arabic: form = 'Suppository'
    elif 'eff' in trade_lower or 'فوار' in arabic: form = 'Effervescent'
    
    data['dosage_form'] = form

    return data

async def login_async(session):
    """Async Login with Loose JSON Parsing."""
    try:
        ua = random.choice(USER_AGENTS)
        # Step 1
        data1 = {'checkLoginForPrices': 1, 'phone': PHONE, 'tokenn': TOKEN}
        async with session.post(SERVER_URL, data=data1, headers={'User-Agent': ua}) as r1:
            # FIX: content_type=None allows parsing text/html as JSON
            resp1 = await r1.json(content_type=None)
            
        if resp1.get('numrows', 0) > 0 and 'data' in resp1:
            u = resp1['data'][0]
            log(f"Login Step 1 OK: {u.get('name')}")
            
            # Step 2
            data2 = {
                'accessgranted': 1, 'namepricesub': u.get('name'),
                'phonepricesub': u.get('phone'), 'tokenpricesub': u.get('token'),
                'grouppricesub': u.get('usergroup'), 'approvedsub': u.get('approved'),
                'IDpricesub': u.get('id')
            }
            async with session.post(LOGIN_URL, data=data2, headers={'User-Agent': ua}) as r2:
                if r2.status == 200:
                    log("Login Step 2 OK. Session secured.")
                    return True
    except Exception as e:
        log(f"Login Failed: {e}")
    return False

async def fetch_drug(sem, session, drug_id, attempt=0):
    """Fetches a single drug page with concurrency control."""
    url = f"{BASE_URL}{drug_id}"
    async with sem: # Limit concurrency
        try:
            async with session.get(url, timeout=REQUEST_TIMEOUT) as response:
                if response.status == 200:
                    html = await response.text()
                    data = parse_drug_page(html, drug_id)
                    # Validate: MUST have a Trade Name to be valid
                    if data.get('trade_name'):
                        return data
                    else:
                        return None # Empty/Invalid Page
                elif response.status in [500, 502, 503, 504] and attempt < 3:
                     await asyncio.sleep(2)
                     return await fetch_drug(sem, session, drug_id, attempt + 1)
        except Exception as e:
            if attempt < 2:
                # Retry on network error
                await asyncio.sleep(1)
                return await fetch_drug(sem, session, drug_id, attempt + 1)
            # log(f"Failed ID {drug_id}: {e}")
    return None

async def main():
    if not os.path.exists(MEDS_CSV):
        print("meds.csv missing")
        return

    # 1. Load IDs
    df = pd.read_csv(MEDS_CSV, dtype=str)
    all_ids = [str(x) for x in df['id'].unique() if str(x).isdigit()]
    log(f"Total IDs to scrape: {len(all_ids)}")

    # 2. Check Existing (Resume vs Reset)
    if '--reset' in sys.argv:
        log("🔄 RESET MODE: Wiping existing scraped data to start fresh.")
        if os.path.exists(OUTPUT_FILE):
             os.remove(OUTPUT_FILE)
    
    processed_ids = set()
    if os.path.exists(OUTPUT_FILE):
        try:
            with open(OUTPUT_FILE, 'r') as f:
                for line in f:
                    if line.strip():
                        try:
                            rec = json.loads(line)
                            processed_ids.add(str(rec['id']))
                        except: pass
        except: pass
    
    log(f"Already processed: {len(processed_ids)}")
    remaining_ids = [mid for mid in all_ids if mid not in processed_ids]
    log(f"Remaining: {len(remaining_ids)}")
    
    if not remaining_ids:
        log("Everything scraped already! Exiting.")
        return

    # 3. Setup Async
    sem = asyncio.Semaphore(CONCURRENCY)
    async with aiohttp.ClientSession() as session:
        if not await login_async(session):
            print("Login failed. Check internet/credentials.")
            return
            
        tasks = []
        save_buffer = []
        
        # Batch processing to manage memory and saves
        BATCH_SIZE = 100
        total = len(remaining_ids)
        
        for i in range(0, total, BATCH_SIZE):
            batch_ids = remaining_ids[i : i + BATCH_SIZE]
            batch_tasks = [fetch_drug(sem, session, mid) for mid in batch_ids]
            
            results = await asyncio.gather(*batch_tasks)
            
            # Filter None
            valid_results = [r for r in results if r]
            
            # Save
            if valid_results:
                async with aiofiles.open(OUTPUT_FILE, 'a', encoding='utf-8') as f:
                    for rec in valid_results:
                        await f.write(json.dumps(rec, ensure_ascii=False) + '\n')
                        
            cnt = i + len(batch_ids)
            print(f"Progress: {cnt}/{total} (New Records: {len(valid_results)})")
            
    log("Scraping Session Finished.")

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("Scraper stopped by User.")
