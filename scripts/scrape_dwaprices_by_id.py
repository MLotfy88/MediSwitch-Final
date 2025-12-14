#!/usr/bin/env python3
"""
MediSwitch ID-Based Scraper
Fetches full drug details by iterating through IDs (from meds.csv or range).
"""

import requests
from bs4 import BeautifulSoup
import pandas as pd
import re
import time
import json
import sys
import os
import random
from datetime import datetime

# --- Configuration ---
LOGIN_URL = "https://dwaprices.com/signin.php"
SERVER_URL = "https://dwaprices.com/server.php"
BASE_URL = "https://dwaprices.com/med.php?id="
MEDS_CSV = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'assets', 'meds.csv')
OUTPUT_FILE = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'assets', 'meds_scraped_new.csv')
LOG_FILE = "scraper_id_log.txt"

# User Credentials (from original scraper)
PHONE = "01558166440"
TOKEN = "bfwh2025-03-17"

# Settings
BATCH_SIZE = 50
DELAY_MIN = 1.0
DELAY_MAX = 2.5

USER_AGENTS = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
]

def log(message):
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {message}")
    with open(LOG_FILE, 'a', encoding='utf-8') as f:
        f.write(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {message}\n")

def get_random_user_agent():
    return random.choice(USER_AGENTS)

def login(session):
    """Performs the two-step login process (Copied from scraper.py)."""
    log("Attempting to login...")
    session.headers.update({'User-Agent': get_random_user_agent()})
    
    # Step 1: Check Credentials
    payload_step1 = {'checkLoginForPrices': 1, 'phone': PHONE, 'tokenn': TOKEN}
    try:
        r1 = session.post(SERVER_URL, data=payload_step1, timeout=15)
        r1.raise_for_status()
        data1 = r1.json()
        
        if data1.get('numrows', 0) > 0 and 'data' in data1:
            user_data = data1['data'][0]
            log(f"✓ Verified user: {user_data.get('name')}")
            
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
            r2 = session.post(LOGIN_URL, data=payload_step2, timeout=15)
            r2.raise_for_status()
            log("✓ Session established.")
            return True
        else:
            log("❌ Login failed (Invalid credentials)")
            return False
    except Exception as e:
        log(f"❌ Login Error: {e}")
        return False

def clean_text(text):
    if not text: return ""
    return re.sub(r'\s+', ' ', text).strip()

def parse_drug_page(html, drug_id):
    """Parses the med.php page content."""
    soup = BeautifulSoup(html, 'html.parser')
    text = soup.get_text("\n")
    
    data = {'id': drug_id}
    
    # Extract using Regex patterns based on the text structure seen
    # "الاسم التجاري ... :\nVALUE"
    
    # Trade Name (English)
    # Pattern: الاسم التجاري [optional colon] \n+ Value \n
    trade_match = re.search(r'الاسم التجاري.*?[:]?\s*\n+(.*?)\n', text)
    data['trade_name'] = clean_text(trade_match.group(1)) if trade_match else ""
    
    # Active Ingredient (Matches "الاسم العلمي" OR "الاسم العلمي او التركيبة...")
    active_match = re.search(r'الاسم العلمي.*?[:]?\s*\n+(.*?)\n', text)
    active = clean_text(active_match.group(1)) if active_match else ""
    if "التصنيف" in active: active = "" # Safety check
    data['active'] = active
    
    # Company
    company_match = re.search(r'الشركة المنتجة.*?[:]?\s*\n+(.*?)\n', text)
    data['company'] = clean_text(company_match.group(1)) if company_match else ""
    
    # Price
    price_match = re.search(r'السعر الجديد الحالي.*?[:]?\s*\n+(\d+(?:\.\d+)?)', text)
    data['price'] = price_match.group(1) if price_match else ""
    
    # Old Price
    old_price_match = re.search(r'السعر القديم.*?[:]?\s*\n+(\d+(?:\.\d+)?)', text)
    data['old_price'] = old_price_match.group(1) if old_price_match else ""
    
    # Main Category
    cat_match = re.search(r'التصنيف الدوائي.*?[:]?\s*\n+(.*?)\n', text)
    data['category'] = clean_text(cat_match.group(1)) if cat_match else ""
    
    # Last Update Date
    date_match = re.search(r'آخر تحديث.*?[:]?\s*\n+(.*?)\n', text)
    data['last_update'] = clean_text(date_match.group(1)) if date_match else ""
    
    # Number of Units (Pack Size)
    units_match = re.search(r'عدد الوحدات.*?[:]?\s*\n+(.*?)\n', text)
    data['units'] = clean_text(units_match.group(1)) if units_match else ""
    
    # Unit Price
    unit_price_match = re.search(r'سعر الوحدة.*?[:]?\s*\n+(\d+(?:\.\d+)?)', text)
    data['unit_price'] = unit_price_match.group(1) if unit_price_match else ""
    
    # Barcode
    barcode_match = re.search(r'رمز الباركود.*?[:]?\s*\n+(\d+)', text)
    data['barcode'] = barcode_match.group(1) if barcode_match else ""
    
    # QR Code
    qr_match = re.search(r'رمز الكيو آر كود.*?[:]?\s*\n+(.*?)\n', text)
    data['qr_code'] = clean_text(qr_match.group(1)) if qr_match else ""
    
    # Pharmacology
    pharma_match = re.search(r'الفارماكولوجي.*?[:]?\s*\n+(.*?)\n', text)
    data['pharmacology'] = clean_text(pharma_match.group(1)) if pharma_match else ""
    
    # Indications (Uses)
    usage_match = re.search(r'دواعي استعمال.*?[:]?\s*\n+(.*?)\n', text)
    data['usage'] = clean_text(usage_match.group(1)) if usage_match else ""

    # Visits
    # Pattern: قام عدد ... 1406 ... شخص
    visits_match = re.search(r'قام عدد.*?(\d+).*?شخص', text, re.DOTALL)
    data['visits'] = visits_match.group(1) if visits_match else ""
    
    # Form and Concentration (Derived from Name if empty)
    # This is useful because the site embeds them in the name.
    # Regex from original scraper for Concentration
    conc_match = re.search(r'(\d+(?:\.\d+)?)\s*(?:mg|gm|ml|mcg|unit|iu)', data['trade_name'], re.IGNORECASE)
    data['concentration'] = conc_match.group(0) if conc_match else ""
    
    # Simple form guess (can be improved)
    if 'tab' in data['trade_name'].lower() or 'اقراص' in data['arabic_name']:
        data['dosage_form'] = 'Tablet'
    elif 'cap' in data['trade_name'].lower() or 'كبسول' in data['arabic_name']:
        data['dosage_form'] = 'Capsule'
    elif 'syr' in data['trade_name'].lower() or 'شراب' in data['arabic_name']:
        data['dosage_form'] = 'Syrup'
    elif 'vial' in data['trade_name'].lower() or 'حقن' in data['arabic_name']:
        data['dosage_form'] = 'Vial/Amp'
    elif 'cream' in data['trade_name'].lower() or 'كريم' in data['arabic_name']:
        data['dosage_form'] = 'Cream'
    elif 'drop' in data['trade_name'].lower() or 'نقط' in data['arabic_name']:
        data['dosage_form'] = 'Drops'
    
    # Arabic Name? Usually title or header?
    # Header 1: سعر دي اوليه نقط فم 30 مل
    h1 = soup.find('h1')
    if h1:
        raw_ar = clean_text(h1.text)
        # Remove "سعر" prefix
        data['arabic_name'] = raw_ar.replace('سعر', '').strip()
    else:
        # Fallback to Title tag
        data['arabic_name'] = ""
        
    return data

def main():
    if not os.path.exists(MEDS_CSV):
        log("❌ meds.csv not found!")
        return
        
    # 1. Load IDs
    log("Loading IDs from meds.csv...")
    df = pd.read_csv(MEDS_CSV, dtype=str)
    ids = [x for x in df['id'].unique() if str(x).isdigit()]
    
    # DEBUG: Test specific ID as requested
    # ids = ['22455']
    
    log(f"Found {len(ids)} unique IDs to scrape.")
    
    # 2. Init Session
    session = requests.Session()
    if not login(session):
        return
        
    scraped_data = []
    processed = 0
    save_interval = 50
    
    # 3. Scrape Loop
    for i, mid in enumerate(ids):
        url = f"{BASE_URL}{mid}"
        try:
            r = session.get(url, timeout=10)
            if r.status_code == 200:
                d = parse_drug_page(r.text, mid)
                # Fallback: if trade_name is empty, maybe invalid ID or redurect?
                if d['trade_name']:
                    scraped_data.append(d)
                    log(f"✅ [{i+1}/{len(ids)}] {mid}: {d['trade_name']} ({d['price']} EGP)")
                else:
                    log(f"⚠️ [{i+1}/{len(ids)}] {mid}: Empty data/Parse failed")
            else:
                log(f"❌ [{i+1}/{len(ids)}] {mid}: HTTP {r.status_code}")
                
        except Exception as e:
            log(f"❌ [{i+1}/{len(ids)}] {mid}: Error {e}")
            
        processed += 1
        time.sleep(random.uniform(DELAY_MIN, DELAY_MAX))
        
        # Incremental Save
        if processed % save_interval == 0:
            pd.DataFrame(scraped_data).to_csv(OUTPUT_FILE, index=False)
            log(f"💾 Saved {len(scraped_data)} records to {OUTPUT_FILE}")
            
    # Final Save
    pd.DataFrame(scraped_data).to_csv(OUTPUT_FILE, index=False)
    log("🎉 Scraping Complete.")

if __name__ == "__main__":
    main()
