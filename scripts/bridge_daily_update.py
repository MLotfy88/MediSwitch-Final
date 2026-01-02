#!/usr/bin/env python3
"""
Bridge Daily Update Script - DATA-CENTRIC VERSION (NO FETCH-BY-ID)
1. Finds latest update date from local meds.csv.
2. Fetches recently updated drugs from server.php (lastprices) until local date is reached.
3. Maps the rich JSON data (15+ columns) directly to the local meds.csv.
4. Updates local CSV and syncs incremental changes to Cloudflare D1.
"""

import os
import sys
import json
import csv
import subprocess
import requests
import time
import re
from datetime import datetime

# Configuration
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MEDS_CSV = os.path.join(BASE_DIR, 'assets', 'meds.csv')
LOG_FILE = os.path.join(BASE_DIR, 'daily_update.log')

# API & D1 Config
SERVER_URL = "https://dwaprices.com/server.php"
D1_DB_NAME = "mediswitsh-db"

# Credentials
PHONE = "01558166440"
TOKEN = "bfwh2025-03-17"
USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'

def log(msg):
    ts = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    print(f"[{ts}] {msg}")
    with open(LOG_FILE, 'a', encoding='utf-8') as f:
        f.write(f"[{ts}] {msg}\n")

def get_latest_local_date():
    """Find the latest date in last_price_update from meds.csv"""
    log("📅 Finding latest local update date...")
    if not os.path.exists(MEDS_CSV):
        return "2000-01-01"
    
    max_date = "2000-01-01"
    try:
        with open(MEDS_CSV, 'r', encoding='utf-8-sig') as f:
            reader = csv.DictReader(f)
            for row in reader:
                dt = row.get('last_price_update', '').strip()
                if dt and dt > max_date:
                    max_date = dt
    except Exception as e:
        log(f"⚠️ Error reading local date: {e}")
    
    log(f"✅ Latest local date: {max_date}")
    return max_date

def perform_login():
    """Simple handshake/check for dwaprices.com"""
    session = requests.Session()
    session.headers.update({'User-Agent': USER_AGENT})
    try:
        r1 = session.post(SERVER_URL, data={'checkLoginForPrices': 1, 'phone': PHONE, 'tokenn': TOKEN})
        if r1.status_code == 200:
            log("✅ API Handshake successful.")
            return session
    except Exception as e:
        log(f"❌ Login Handshake failed: {e}")
    return None

def fetch_and_map_updates(session, latest_date_str):
    """Fetch updates from server and map to the 18-column schema"""
    log(f"🔍 Fetching updates since {latest_date_str}...")
    mapped_updates = []
    offset = 0
    cutoff_ts = int(time.mktime(time.strptime(latest_date_str, "%Y-%m-%d"))) * 1000
    seen_ids = set()
    
    while True:
        r = session.post(SERVER_URL, data={'lastprices': offset})
        try:
            resp = r.json()
            data = resp.get('data', [])
            if not data: break
            
            finished = False
            for item in data:
                # 1. Check timestamp to know when to stop
                ts = int(item.get('Date_updated', 0))
                if ts <= cutoff_ts:
                    finished = True
                    break
                
                mid = str(item.get('id', ''))
                if not mid or mid in seen_ids: continue
                seen_ids.add(mid)

                # 2. Map JSON fields to our 18-column schema
                # Current schema: id, trade_name, arabic_name, active, category, company, 
                # price, old_price, last_price_update, units, barcode, qr_code, 
                # pharmacology, usage, visits, concentration, dosage_form, dosage_form_ar
                
                # Format date
                update_date = datetime.fromtimestamp(ts/1000).strftime('%Y-%m-%d')
                
                # Inferred fields (dosage_form_ar, concentration)
                tn = item.get('name', '')
                conc_match = re.search(r'(\d+(?:\.\d+)?)\s*(?:%|mg|gm|ml|mcg)', tn, re.I)
                concentration = conc_match.group(0) if conc_match else ""
                
                mapped = {
                    'id': mid,
                    'trade_name': tn,
                    'arabic_name': item.get('arabic', ''),
                    'active': item.get('active', ''),
                    'category': '', # Not in JSON, keep existing or empty
                    'company': item.get('company', ''),
                    'price': item.get('price', ''),
                    'old_price': item.get('oldprice', ''),
                    'last_price_update': update_date,
                    'units': item.get('units', ''),
                    'barcode': item.get('barcode', ''),
                    'qr_code': item.get('qrcode', ''),
                    'pharmacology': item.get('pharmacology', ''),
                    'usage': item.get('uses', ''),
                    'visits': item.get('visits', '0'),
                    'concentration': concentration,
                    'dosage_form': item.get('dosage_form', ''),
                    'dosage_form_ar': '' # Optional mapping if needed
                }
                mapped_updates.append(mapped)
            
            if finished or len(data) < 100: break
            offset += 100
            log(f"  Processed {offset} records from list...")
        except Exception as e:
            log(f"  ❌ Error parsing batch: {e}")
            break
            
    log(f"📊 Collected {len(mapped_updates)} rich updates directly from server list.")
    return mapped_updates

import re # Need to import re inside if not global

def update_meds_csv(updates):
    """Upsert updates into local meds.csv while maintaining all 18 columns"""
    if not updates: return
    log("💾 Updating local meds.csv...")
    
    db = {}
    fieldnames = []
    
    if os.path.exists(MEDS_CSV):
        with open(MEDS_CSV, 'r', encoding='utf-8-sig') as f:
            reader = csv.DictReader(f)
            fieldnames = reader.fieldnames
            for row in reader:
                db[row['id']] = row
    
    # Apply updates
    for up in updates:
        mid = up['id']
        if mid in db:
            # ONLY update price and name related fields (to preserve stable meta like category)
            # OR update everything available in JSON
            # Given we want "maintain 18 columns", we update what we have.
            for k, v in up.items():
                if v: # Only overwrite if we have a value
                    db[mid][k] = v
        else:
            # New drug found in list!
            db[mid] = up
            
    with open(MEDS_CSV, 'w', encoding='utf-8', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(db.values())
    log("✅ Local CSV updated successfully.")

# Cloudflare API Configuration
CF_API_TOKEN = "yy-vk8KC4yth3Cn2lpva1AgrP2kGMJrQQrGIUM1-"
CF_ACCOUNT_ID = "9f7fd7dfef294f26d47d62df34726367"
CF_D1_DB_ID = "77da23cd-a8cc-40bf-9c0f-f0effe7eeaa0"

def sync_to_d1(updates):
    """Sync updates to Cloudflare D1 using direct API requests"""
    if not updates: return
    log("☁️ Syncing updates to Cloudflare D1 (Direct API)...")
    
    headers = {
        "Authorization": f"Bearer {CF_API_TOKEN}",
        "Content-Type": "application/json"
    }
    url = f"https://api.cloudflare.com/client/v4/accounts/{CF_ACCOUNT_ID}/d1/database/{CF_D1_DB_ID}/query"
    
    batch_size = 20 # Small batches for direct API
    for i in range(0, len(updates), batch_size):
        batch = updates[i:i+batch_size]
        sql_statements = ""
        for r in batch:
            def val(k):
                v = str(r.get(k, '')).replace("'", "''")
                return f"'{v}'"
            
            mid = int(r['id'])
            
            sql = f"""
            INSERT OR REPLACE INTO drugs 
            (id, trade_name, arabic_name, price, old_price, category, active, company, dosage_form, dosage_form_ar, concentration, unit, usage, pharmacology, barcode, qr_code, visits, last_price_update, updated_at, indication, mechanism_of_action, pharmacodynamics, data_source_pharmacology, has_drug_interaction, has_food_interaction, has_disease_interaction)
            VALUES 
            ({mid}, {val('trade_name')}, {val('arabic_name')}, {val('price')}, {val('old_price')}, {val('category')}, {val('active')}, {val('company')}, {val('dosage_form')}, {val('dosage_form_ar')}, {val('concentration')}, {val('unit')}, {val('usage')}, {val('pharmacology')}, {val('barcode')}, {val('qr_code')}, {val('visits')}, {val('last_price_update')}, strftime('%s','now'), {val('indication')}, {val('mechanism_of_action')}, {val('pharmacodynamics')}, {val('data_source_pharmacology')}, {r.get('has_drug_interaction', 0)}, {r.get('has_food_interaction', 0)}, {r.get('has_disease_interaction', 0)});
            """
            sql_statements += sql.strip() + "\n"
        
        try:
            resp = requests.post(url, headers=headers, json={"sql": sql_statements})
            if resp.status_code == 200:
                log(f"  ✅ Batch {i//batch_size + 1} synced successfully.")
            else:
                log(f"  ❌ Batch {i//batch_size + 1} failed: {resp.text}")
        except Exception as e:
            log(f"  ❌ Error syncing batch {i//batch_size + 1}: {e}")

def main():
    latest_date = get_latest_local_date()
    # Reset latest_date for testing if needed: latest_date = "2025-12-18"
    session = perform_login()
    if not session: return
    
    updates = fetch_and_map_updates(session, latest_date)
    if updates:
        update_meds_csv(updates)
        sync_to_d1(updates)
        log(f"🎉 Daily update finished. Applied {len(updates)} updates.")
    else:
        log("✅ No new updates to apply.")

if __name__ == "__main__":
    main()
