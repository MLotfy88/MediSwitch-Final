#!/usr/bin/env python3
"""
MediSwitch Production Scraper - FIXED VERSION
Uses verified table-based extraction with all corrections applied.
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
import argparse
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
CONCURRENCY = 10
REQUEST_TIMEOUT = 30

# User Agents
USER_AGENTS = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (iPhone; CPU iPhone OS 17_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/120.0.6099.119 Mobile/15E148 Safari/604.1',
]

def log(message):
    ts = datetime.now().strftime('%H:%M:%S')
    print(f"[{ts}] {message}", flush=True)
    with open(LOG_FILE, 'a', encoding='utf-8') as f:
        f.write(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {message}\n")

def clean_text(text):
    if not text: return ""
    return re.sub(r'\s+', ' ', text).strip()

def extract_from_table(soup):
    """Extract data from HTML table (VERIFIED LOGIC)"""
    data = {}
    rows = soup.find_all('tr')
    
    field_map = {
        'الاسم التجاري': 'trade_name',
        'الاسم العلمي': 'active',
        'التصنيف': 'category',
        'الشركة المنتجة': 'company',
        'السعر الجديد الحالي': 'price',
        'السعر القديم': 'old_price',
        'آخر تحديث للسعر': 'last_price_update',
        'عدد الوحدات': 'units',
        'رمز الباركود': 'barcode',
        'رمز': 'qr_code',
        'الفارماكولوجي': 'pharmacology',
        'الفارماكولوجى': 'pharmacology',
        'Pharmacology': 'pharmacology',
        'الوصف': 'pharmacology', # Sometimes description is used here
        'Description': 'pharmacology',
    }
    
    for row in rows:
        cells = row.find_all(['td', 'th'])
        if len(cells) >= 2:
            label = clean_text(cells[0].get_text())
            value = clean_text(cells[1].get_text())
            
            for ar_label, en_key in field_map.items():
                if ar_label in label:
                    data[en_key] = value
                    break
    
    return data

def parse_drug_page(html: str, drug_id: str) -> Dict:
    """Parse drug page using VERIFIED table-based extraction"""
    soup = BeautifulSoup(html, 'html.parser')
    data = {'id': drug_id}
    
    # 1. Arabic Name from H1
    h1 = soup.find('h1')
    if h1:
        arabic_name = clean_text(h1.text).replace('سعر', '').strip()
        data['arabic_name'] = arabic_name
    else:
        data['arabic_name'] = ""
    
    # 2. Extract from HTML table
    table_data = extract_from_table(soup)
    data.update(table_data)
    
    # Post-processing: Clean Barcode (Keep digits only)
    if 'barcode' in data:
         # Extract first sequence of digits 5+ chars long to avoid small numbers
         bc_match = re.search(r'\d{5,}', data['barcode'])
         if bc_match:
             data['barcode'] = bc_match.group(0)
         else:
             # Fallback cleanup
             data['barcode'] = re.sub(r'[^\d]', '', data['barcode'])

    # 3. Extract usage from text section (Broader Regex)
    text = soup.get_text("\n")
    # Debug info logic kept hidden or minimal unless needed
    
    # Regex refinement: Look for usage keyword, optional colon, newlines, then capture text until next SECTION HEADER
    # Stop keywords: "نموذج إبلاغ", "الاسم", "السعر", "الشركة", "التصنيف", "عدد الوحدات", "رمز"
    stop_pattern = r'(?=\n\s*(?:نموذج إبلاغ|الاسم|السعر|الشركة|التصنيف|عدد الوحدات|رمز|\Z))'
    
    usage_match = re.search(r'(?:دواع[ب-ي]|استخدامات?)\s*(?:ال)?(?:استعم?ال|استخدام).*?[:\n]+(.*?)' + stop_pattern, 
                           text, re.DOTALL | re.IGNORECASE)
    
    if usage_match:
        usage_text = usage_match.group(1).strip()
        
        # If captured text is very short/header-like, try fuzzy search for next block
        if len(usage_text) < 10 or usage_text.endswith(':'):
             # Try capturing the next block
             next_match = re.search(r'(?:دواع[ب-ي]|استخدامات?)\s*(?:ال)?(?:استعم?ال|استخدام).*?[:\n]+.*?\n+(.*?)' + stop_pattern, 
                                    text, re.DOTALL | re.IGNORECASE)
             if next_match:
                 usage_text = next_match.group(1).strip()
                 
        # Clean up newlines: Keep single newlines for list items, remove excessive spacing
        usage_text = re.sub(r'\n{3,}', '\n\n', usage_text)
        data['usage'] = usage_text.strip()
    else:
        data['usage'] = ""
    
    # 4. Extract visits (Broader Regex)
    # Matches "قام 11897 شخص" or "قام عدد 11897 زائر" etc.
    visits_match = re.search(r'قام.*?\s+(\d+)\s+', text)
    data['visits'] = visits_match.group(1) if visits_match else ""
    
    # 5. Extract concentration from trade_name
    # Fix: Catch "0.03%" (no \b needed after %) OR "500 mg" (needs \b)
    if data.get('trade_name'):
        conc_match = re.search(r'(\d+(?:\.\d+)?)\s*(?:%|(?:mg|gm|ml|mcg|unit|iu)\b)', 
                              data['trade_name'], re.IGNORECASE)
        # Verify it actually looks like a concentration
        if conc_match:
             # Capture the full match including unit
             full_conc = conc_match.group(0)
             data['concentration'] = full_conc
        else:
             data['concentration'] = ""
    else:
        data['concentration'] = ""
    
    # 6. Infer dosage form
    trade_lower = data.get('trade_name', '').lower()
    arabic = data.get('arabic_name', '')
    
    form = 'Unknown'
    if 'tab' in trade_lower or 'اقراص' in arabic or 'قرص' in arabic: form = 'Tablet'
    elif 'cap' in trade_lower or 'كبسول' in arabic: form = 'Capsule'
    elif 'syr' in trade_lower or 'شراب' in arabic: form = 'Syrup'
    elif 'vial' in trade_lower or 'amp' in trade_lower or 'حقن' in arabic or 'امبول' in arabic: form = 'Vial/Amp'
    elif 'cream' in trade_lower or 'كريم' in arabic: form = 'Cream'
    elif 'oint' in trade_lower or 'مرهم' in arabic: form = 'Ointment'
    elif 'drop' in trade_lower or 'نقط' in arabic: form = 'Drops'
    elif 'supp' in trade_lower or 'لبوس' in arabic: form = 'Suppository'
    elif 'eff' in trade_lower or 'فوار' in arabic: form = 'Effervescent'
    
    data['dosage_form'] = form
    
    return data

async def perform_login(session):
    """Performs login and returns success status"""
    try:
        # Step 1
        async with session.post(SERVER_URL, data={
            'checkLoginForPrices': 1,
            'phone': PHONE,
            'tokenn': TOKEN
        }) as response:
            # Check if response is JSON (lax check for misconfigured servers)
            content_type = response.headers.get('Content-Type', '')
            text = await response.text()
            
            try:
                if 'application/json' in content_type:
                    resp1 = await response.json()
                else:
                    # Fallback: Try to parse text as JSON even if header is wrong
                     resp1 = json.loads(text)
            except json.JSONDecodeError:
                log(f"❌ Login Step 1 failed: Expected JSON, got {content_type}")
                log(f"Response preview: {text[:500]}")
                return False
            
            if resp1.get('numrows', 0) > 0 and 'data' in resp1:
                u = resp1['data'][0]
                log(f"✅ Login Step 1: {u.get('name')}")
                
                # Step 2
                async with session.post(LOGIN_URL, data={
                    'accessgranted': 1,
                    'namepricesub': u.get('name'),
                    'phonepricesub': u.get('phone'),
                    'tokenpricesub': u.get('token'),
                    'grouppricesub': u.get('usergroup'),
                    'approvedsub': u.get('approved'),
                    'IDpricesub': u.get('id')
                }) as r2:
                    if r2.status == 200:
                        log("✅ Login Step 2: Session secured")
                        return True
                    else:
                        log(f"❌ Login Step 2 failed: HTTP {r2.status}")
                        return False
            else:
                log(f"❌ Login Step 1 failed: Invalid response data")
                log(f"Response: {resp1}")
                return False
    except Exception as e:
        log(f"❌ Login failed: {type(e).__name__}: {e}")
    
    return False

async def fetch_drug(sem, session, drug_id, attempt=0):
    """Fetches a single drug page with concurrency control"""
    url = f"{BASE_URL}{drug_id}"
    
    # Human-like delay (5-10 seconds as requested)
    await asyncio.sleep(random.uniform(5.0, 10.0))
    
    async with sem:
        try:
            async with session.get(url, timeout=REQUEST_TIMEOUT) as response:
                if response.status == 200:
                    html = await response.text()
                    data = parse_drug_page(html, drug_id)
                    # Validate: Must have trade_name
                    if data.get('trade_name'):
                        return data
                    else:
                        return None
                elif response.status in [500, 502, 503, 504] and attempt < 3:
                    await asyncio.sleep(2)
                    return await fetch_drug(sem, session, drug_id, attempt + 1)
        except Exception as e:
            if attempt < 2:
                await asyncio.sleep(1)
                return await fetch_drug(sem, session, drug_id, attempt + 1)
    return None

async def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--reset', action='store_true', help='Delete existing output before scraping')
    parser.add_argument('--test-mode', action='store_true', help='Run verification test (ID 11196 + 10 random)')
    parser.add_argument('--limit', type=int, default=None, help='Limit number of drugs to scrape (for testing)')
    args = parser.parse_args()
    
    # User Correction: Source IDs from BACKUP, Wipe MAIN CSV
    INPUT_CSV = os.path.join(os.path.dirname(MEDS_CSV), 'meds_backup.csv')
    
    if not os.path.exists(INPUT_CSV):
        print(f"❌ Input file {INPUT_CSV} not found")
        # Fallback to main if backup missing, but warn
        if os.path.exists(MEDS_CSV):
             log(f"⚠️ Backup missing, falling back to {MEDS_CSV}")
             INPUT_CSV = MEDS_CSV
        else:
             return

    # ✨ CRITICAL FIX: Load IDs FIRST, before any wiping/resetting
    all_ids = []
    try:
        df = pd.read_csv(INPUT_CSV, dtype=str, encoding='utf-8-sig', on_bad_lines='skip')
        # Normalize columns (strip whitespace, lowercase)
        df.columns = [c.strip().lower() for c in df.columns]
        
        if 'id' not in df.columns:
            # Try to find a column that might be ID
            potential = [c for c in df.columns if 'id' in c]
            if potential:
                df.rename(columns={potential[0]: 'id'}, inplace=True)
                log(f"⚠️ Renamed '{potential[0]}' to 'id'")
            else:
                # Fallback: use index or first column
                log(f"❌ No ID column found in CSV! Columns: {df.columns.tolist()}")
                return
        
        # Extract valid IDs
        for idx, row in df.iterrows():
            id_val = str(row.get('id', '')).strip()
            if id_val and id_val.isdigit():
                all_ids.append(id_val)
        
        all_ids = list(set(all_ids))  # Remove duplicates
        log(f"📊 Total IDs loaded: {len(all_ids):,}")
        
    except Exception as e:
        log(f"❌ Error reading CSV: {e}")
        return

    # NOW we can wipe meds.csv if --reset or --test-mode was requested
    if args.test_mode or args.reset:
        if os.path.exists(MEDS_CSV):
            with open(MEDS_CSV, 'w') as f:
                f.write('id,trade_name\n') # Write minimal header to avoid "empty" errors later if needed
            log("🔥 Wiped meds.csv (recreated empty) as requested")
    
    # Check processed IDs
    processed_ids = set()
    if os.path.exists(OUTPUT_FILE) and not args.reset and not args.test_mode:
        with open(OUTPUT_FILE, 'r') as f:
            for line in f:
                if line.strip():
                    try:
                        rec = json.loads(line)
                        processed_ids.add(str(rec.get('id', '')))
                    except: pass
        log(f"✅ Found {len(processed_ids)} already processed")
    elif args.reset and os.path.exists(OUTPUT_FILE):
        os.remove(OUTPUT_FILE)
        log("🗑️  Reset: Deleted existing output file")
        
    pending_ids = [id for id in all_ids if id not in processed_ids]
    
    if args.test_mode:
        # TEST MODE SELECTION
        target_ids = []
        # 1. Verification ID 11196
        if '11196' in all_ids:
            target_ids.append('11196')
        else:
            log("⚠️ ID 11196 not found in CSV! Adding manually for test.")
            target_ids.append('11196')
            
        # 2. Add 10 random others
        remaining = [x for x in pending_ids if x != '11196']
        sample_size = min(10, len(remaining))
        target_ids.extend(random.sample(remaining, sample_size))
        
        pending_ids = target_ids
        log(f"🧪 Testing with {len(pending_ids)} IDs: {pending_ids}")
    elif args.limit:
        # LIMIT MODE: Take first N pending IDs
        pending_ids = pending_ids[:args.limit]
        log(f"📊 Limit mode: Scraping {len(pending_ids)} drugs")
    
    log(f"🎯 Pending IDs to scrape: {len(pending_ids)}")
    
    if not pending_ids:
        log("✅ Nothing to scrape")
        return
    
    # Performance Settings
    CONCURRENCY = 10
    REQUEST_TIMEOUT = 60
    
    # Setup session with FULL browser-like headers
    connector = aiohttp.TCPConnector(limit=CONCURRENCY)
    timeout = aiohttp.ClientTimeout(total=REQUEST_TIMEOUT)
    
    # Complete browser headers to avoid bot detection
    # MIMIC REAL XHR REQUEST for server.php
    headers = {
        'User-Agent': random.choice(USER_AGENTS),
        'Accept': 'application/json, text/javascript, */*; q=0.01', # Expected for XHR
        'Accept-Language': 'ar-EG,ar;q=0.9,en-US;q=0.8,en;q=0.7',
        'Accept-Encoding': 'gzip, deflate, br',
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        'X-Requested-With': 'XMLHttpRequest', # Critical for PHP backends identifying AJAX
        'DNT': '1',
        'Connection': 'keep-alive',
        'Sec-Fetch-Dest': 'empty', # Standard for XHR
        'Sec-Fetch-Mode': 'cors',
        'Sec-Fetch-Site': 'same-origin',
        'Referer': 'https://dwaprices.com/',
        'Origin': 'https://dwaprices.com'
    }
    
    async with aiohttp.ClientSession(connector=connector, timeout=timeout, headers=headers) as session:
        # Add small delay before login (human behavior)
        log("⏳ Waiting 2 seconds before login (anti-bot measure)...")
        await asyncio.sleep(2)
        
        # Login
        if not await perform_login(session):
            log("❌ Login failed, aborting")
            return
        
        # Scrape
        sem = asyncio.Semaphore(CONCURRENCY)
        tasks = [fetch_drug(sem, session, drug_id) for drug_id in pending_ids]
        
        # Process in batches with progress
        BATCH_SIZE = 100
        total_scraped = 0
        
        for i in range(0, len(tasks), BATCH_SIZE):
            batch = tasks[i:i+BATCH_SIZE]
            results = await asyncio.gather(*batch)
            
            # Save results
            # Synchronous batch write to ensure newline integrity and atomicity
            batch_lines = []
            for data in results:
                if data:
                    batch_lines.append(json.dumps(data, ensure_ascii=False))
                    # DEBUG: Print ID 11196 for verification
                    if args.test_mode and str(data.get('id')) == '11196':
                         print("\n🔍 --- VERIFICATION RECORD [11196] ---")
                         print(json.dumps(data, indent=2, ensure_ascii=False))
                         print("----------------------------------------\n")
            
            if batch_lines:
                # Use append mode with utf-8 encoding
                with open(OUTPUT_FILE, 'a', encoding='utf-8') as f:
                    f.write('\n'.join(batch_lines) + '\n')
                    total_scraped += len(batch_lines)
            
            log(f"✅ Batch {i//BATCH_SIZE + 1}: {len([r for r in results if r])}/{len(batch)} scraped (Total: {total_scraped})")
            
            # Random pause between batches (10-25s)
            if i + BATCH_SIZE < len(tasks):
                pause = random.uniform(10, 25)
                log(f"⏸️  Pausing {pause:.1f}s before next batch...")
                await asyncio.sleep(pause)
        
        log(f"🎉 Scraping complete! Total: {total_scraped} drugs")


if __name__ == "__main__":
    asyncio.run(main())
