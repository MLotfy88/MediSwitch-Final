
import asyncio
import aiohttp
import sqlite3
import json
import time
import os
import signal
import sys
from bs4 import BeautifulSoup
from datetime import datetime

# --- Configuration ---
# Optimal concurrency for local wifi/mobile data usually around 20-50
# Too high might trigger WAF bans or timeouts
CONCURRENCY_LIMIT = 20 
DB_PATH = 'ddinter_complete.db'
BASE_URL = 'https://ddinter2.scbdd.com'

# Standard Browser Headers (for GET)
HEADERS_GET = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.5',
    'Connection': 'keep-alive',
    'Upgrade-Insecure-Requests': '1',
    'Sec-Fetch-Dest': 'document',
    'Sec-Fetch-Mode': 'navigate',
    'Sec-Fetch-Site': 'none',
    'Sec-Fetch-User': '?1'
}

# AJAX Headers (for POST APIs)
HEADERS_POST = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'application/json, text/javascript, */*; q=0.01',
    'X-Requested-With': 'XMLHttpRequest',
    'Origin': BASE_URL,
    'Referer': f'{BASE_URL}/',
    'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'
}
TIMEOUT = aiohttp.ClientTimeout(total=60, connect=20)

# --- Database Setup (Sync for Writer Thread) ---
def init_db():
    conn = sqlite3.connect(DB_PATH, check_same_thread=False) # Allow efficient writing
    c = conn.cursor()
    
    # 1. Checkpoint / Status Table
    c.execute('''
        CREATE TABLE IF NOT EXISTS scrap_status (
            item_type TEXT, -- 'drug_list', 'drug_details'
            item_id TEXT,
            status TEXT, -- 'pending', 'processing', 'completed', 'error'
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (item_type, item_id)
        )
    ''')

    # 2. Main Data Tables (Matching v10 Schema)
    c.execute('''
        CREATE TABLE IF NOT EXISTS drugs (
            ddinter_id TEXT PRIMARY KEY,
            drug_name TEXT,
            drug_type TEXT,
            molecular_formula TEXT,
            molecular_weight TEXT,
            cas_number TEXT,
            description TEXT,
            iupac_name TEXT,
            inchi TEXT,
            smiles TEXT,
            atc_codes TEXT,
            external_links TEXT,
            structure_2d_svg TEXT,
            scraped_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')

    c.execute('''
        CREATE TABLE IF NOT EXISTS drug_drug_interactions (
            interaction_id INTEGER PRIMARY KEY,
            drug_a_id TEXT,
            drug_b_id TEXT,
            severity TEXT,
            mechanism_flags TEXT,
            interaction_description TEXT,
            management_text TEXT,
            alternative_drugs_a TEXT,
            alternative_drugs_b TEXT,
            metabolism_info TEXT,
            reference_text TEXT,
            source_url TEXT
        )
    ''')
    
    # Indices for speed
    c.execute('CREATE INDEX IF NOT EXISTS idx_ddi_drug_a ON drug_drug_interactions(drug_a_id)')
    c.execute('CREATE INDEX IF NOT EXISTS idx_ddi_drug_b ON drug_drug_interactions(drug_b_id)')

    c.execute('''
        CREATE TABLE IF NOT EXISTS drug_disease_interactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            drug_id TEXT,
            disease_name TEXT,
            severity TEXT,
            interaction_text TEXT,
            reference_text TEXT,
            UNIQUE(drug_id, disease_name)
        )
    ''')

    c.execute('''
        CREATE TABLE IF NOT EXISTS drug_food_interactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            drug_id TEXT,
            food_name TEXT,
            severity TEXT,
            description TEXT,
            management_text TEXT,
            mechanism_flags TEXT,
            reference_text TEXT,
            UNIQUE(drug_id, food_name)
        )
    ''')
    
    c.execute('''
        CREATE TABLE IF NOT EXISTS compound_preparations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            drug_id TEXT,
            preparation_name TEXT,
            components TEXT,
            interaction_info TEXT,
            UNIQUE(drug_id, preparation_name)
        )
    ''')

    conn.commit()
    conn.close()
    print("Database initialized.")

# --- Writer Worker ---
async def db_writer_worker(queue):
    """
    Dedicated worker to handle all DB writes sequentially.
    This avoids SQLite lock errors and ensures data safety.
    """
    print("DB Writer started...")
    conn = sqlite3.connect(DB_PATH, check_same_thread=False)
    # Enable WAL mode for better concurrency
    conn.execute('PRAGMA journal_mode=WAL;')
    conn.execute('PRAGMA synchronous=NORMAL;')
    cursor = conn.cursor()
    
    count = 0
    
    while True:
        try:
            item = await queue.get()
            if item is None: # Sentinel to stop
                break
            
            op_type, data = item
            
            try:
                if op_type == 'insert_drug':
                    cursor.execute('''
                        INSERT OR REPLACE INTO drugs (
                            ddinter_id, drug_name, drug_type, molecular_formula, 
                            molecular_weight, cas_number, description, iupac_name,
                            inchi, smiles, atc_codes, external_links, structure_2d_svg
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    ''', data)
                    
                elif op_type == 'insert_ddi':
                    cursor.execute('''
                        INSERT OR REPLACE INTO drug_drug_interactions (
                            interaction_id, drug_a_id, drug_b_id, severity, 
                            mechanism_flags, interaction_description, management_text,
                            alternative_drugs_a, alternative_drugs_b, metabolism_info,
                            reference_text, source_url
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    ''', data)
                    
                elif op_type == 'insert_disease':
                    cursor.execute('''
                        INSERT OR IGNORE INTO drug_disease_interactions 
                        (drug_id, disease_name, severity, interaction_text, reference_text)
                        VALUES (?, ?, ?, ?, ?)
                    ''', data)

                elif op_type == 'insert_food':
                    cursor.execute('''
                        INSERT OR IGNORE INTO drug_food_interactions 
                        (drug_id, food_name, severity, description, management_text, mechanism_flags, reference_text)
                        VALUES (?, ?, ?, ?, ?, ?, ?)
                    ''', data)
                    
                elif op_type == 'insert_compound':
                    cursor.execute('''
                        INSERT OR IGNORE INTO compound_preparations 
                        (drug_id, preparation_name, components, interaction_info)
                        VALUES (?, ?, ?, ?)
                    ''', data)
                    
                elif op_type == 'update_ddi_details':
                    cursor.execute('''
                        UPDATE drug_drug_interactions
                        SET interaction_description = ?,
                            management_text = ?,
                            alternative_drugs_a = ?,
                            alternative_drugs_b = ?,
                            reference_text = ?
                        WHERE interaction_id = ?
                    ''', data)

                elif op_type == 'update_status':
                    cursor.execute('''
                        INSERT OR REPLACE INTO scrap_status (item_type, item_id, status)
                        VALUES (?, ?, ?)
                    ''', data)

                count += 1
                if count % 100 == 0: # Commit every 100 ops
                    conn.commit()
                    # print(f"DB Saved {count} operations.")
                    
            except Exception as e:
                print(f"DB Write Error ({op_type}): {e}")
            
            queue.task_done()
            
        except Exception as e:
            print(f"Writer Loop Error: {e}")

    conn.commit()
    conn.close()
    print("DB Writer stopped.")

# --- Async Fetching Logic ---
class TurboScraper:
    def __init__(self):
        self.session = None
        self.db_queue = asyncio.Queue()
        self.sem = asyncio.Semaphore(CONCURRENCY_LIMIT) 
        self.writer_task = None
        self.running = True

    async def start(self):
        init_db()
        self.writer_task = asyncio.create_task(db_writer_worker(self.db_queue))
        
        # Use a single session for connection pooling
        connector = aiohttp.TCPConnector(limit=CONCURRENCY_LIMIT, ssl=False)
        async with aiohttp.ClientSession(headers=HEADERS_GET, timeout=TIMEOUT, connector=connector) as session:
            self.session = session
            await self.main_loop()
        
        # Cleanup
        await self.db_queue.put(None) # Signal writer to stop
        await self.writer_task
        print("Scraping Session Finished.")

    async def fetch(self, url, method='GET', data=None):
        if not self.running: return None
        
        # Select Headers
        headers = None # Use session default (GET)
        if method == 'POST':
            headers = HEADERS_POST

        for attempt in range(3):
            try:
                async with self.sem: # Rate limit
                    if method == 'GET':
                        async with self.session.get(url, headers=headers) as resp:
                            if resp.status == 200:
                                return await resp.text()
                            elif resp.status == 429:
                                print(f"Rate limited (429) on {url}. Sleeping...")
                                await asyncio.sleep(5)
                                continue
                            else:
                                print(f"GET Fail {resp.status} on {url}")
                    else:
                        async with self.session.post(url, data=data, headers=headers) as resp:
                            if resp.status == 200:
                                return await resp.json()
                            elif resp.status == 429:
                                await asyncio.sleep(5)
                                continue
                            else:
                                print(f"POST Fail {resp.status} on {url}")
            except Exception as e:
                print(f"Fetch Error ({url}): {e}")
                await asyncio.sleep(1)
            
            await asyncio.sleep(1 * (attempt+1)) # Backoff
            
        return None

    # --- Specific Scrapers ---

    def load_drug_ids_from_file(self):
        try:
            # Try same directory first
            path = 'unique_drugs.json'
            if not os.path.exists(path):
                # Try relative to script location if different
                script_dir = os.path.dirname(os.path.abspath(__file__))
                path = os.path.join(script_dir, 'unique_drugs.json')
            
            if os.path.exists(path):
                with open(path, 'r') as f:
                    data = json.load(f)
                    return data.get('unique_drugs', [])
            return []
        except Exception as e:
            print(f"File Load Error: {e}")
            return []

    async def get_all_drug_ids(self):
        # 1. Try Local File
        local_ids = await asyncio.to_thread(self.load_drug_ids_from_file)
        if local_ids:
            print(f"Loaded {len(local_ids)} drugs from local file.")
            return local_ids

        # 2. Fallback to API Fetching
        print("Fetching Drug List from API...")
        
        all_drugs = []
        page = 1
        
        while True and self.running:
            url = f"{BASE_URL}/server/drug_list/"
            
            params = {
                'draw': str(page),
                'start': str((page - 1) * 100),
                'length': '100',
                'search[value]': '',
                'search[regex]': 'false',
                'order[0][column]': '0',
                'order[0][dir]': 'asc'
            }
            
            result = await self.fetch(url, method='POST', data=params)
            
            if not result or 'data' not in result or not result['data']:
                print("No more data in drug list (or API failed).")
                break
                
            batch = result['data']
            print(f"Fetched Page {page}: {len(batch)} drugs.")
            
            for item in batch:
                d_id = item.get('ddinter_id')
                if d_id:
                    all_drugs.append(d_id)
            
            if len(batch) < 100:
                break
                
            page += 1
            
        print(f"Total Drugs Found: {len(all_drugs)}")
        return all_drugs

    async def process_drug(self, drug_id):
        # Check status
        # We want to skip if 'completed'
        # BUT user said "Turbo script to MATCH workflow exactly".
        # Workflow v10 pulls: Basic Info, Mechanisms, Alternatives, Diseases, Foods.
        
        # 1. Basic Info & Details
        # 2. Interactions (DDI + disease + food)
        
        print(f"Processing {drug_id}...")
        
        # A. Basic Info
        html = await self.fetch(f"{BASE_URL}/ddinter/drug/{drug_id}/")
        if html:
             await self.parse_and_save_drug_info(drug_id, html)
        else:
             print(f"Skipping {drug_id}: Could not fetch Basic Info HTML.")
        
        # B. DDI (The heavy part)
        # Fetching List of Interactions
        await self.fetch_and_save_ddi(drug_id)

        # C. Disease
        await self.fetch_and_save_disease(drug_id)

        # D. Food
        await self.fetch_and_save_food(drug_id)

        # E. Compound Preparations
        await self.fetch_and_save_compound(drug_id)

        # Mark done
        await self.db_queue.put(('update_status', ('drug_full', drug_id, 'completed')))

    async def parse_and_save_drug_info(self, drug_id, html):
        soup = BeautifulSoup(html, 'html.parser')
        
        def get_val(label):
            row = soup.find('td', string=lambda t: t and label in t)
            if row:
                sib = row.find_next_sibling('td')
                return sib.get_text(strip=True) if sib else None
            return None

        # SVGs, ATC, etc
        atc_links = soup.select('a[href*="whocc.no"]')
        atc_codes = [a.get_text(strip=True) for a in atc_links]
        
        ext_links = []
        # External links logic (simplified)
        
        drug_data = (
            drug_id,
            soup.find('h1').get_text(strip=True) if soup.find('h1') else 'Unknown',
            get_val('Drug Type'),
            get_val('Molecular Formula'),
            get_val('Molecular Weight'),
            get_val('CAS Number'),
            get_val('Description'),
            get_val('IUPAC Name'),
            get_val('InChI'),
            get_val('Canonical SMILES'),
            json.dumps(atc_codes),
            json.dumps(ext_links),
            None # svg - skipping for speed/size unless critical
        )
        
        await self.db_queue.put(('insert_drug', drug_data))

    async def fetch_and_save_ddi(self, drug_id):
        # API: /server/interact-with/{drug_id}/
        # This returns JSON with mechanisms!
        # This is where v10 gets Mechanism info.
        
        url = f"{BASE_URL}/server/interact-with/{drug_id}/"
        params = {
            'draw': 1, 'start': 0, 'length': 5000, # Try to get all at once
            'severity': '', 'mechanism': ''
        }
        
        res = await self.fetch(url, method='POST', data=params)
        if not res or 'data' not in res: return

        for item in res['data']:
            # item has: interaction_id, drug_id (the OTHER drug), level, metabolism, etc.
            
            # Extract Mechanisms
            mechs = []
            if item.get('metabolism') == '1': mechs.append('Metabolism')
            if item.get('synergistic_effect') == '1': mechs.append('Synergism')
            if item.get('antagonistic_effect') == '1': mechs.append('Antagonism')
            if item.get('absorption') == '1': mechs.append('Absorption')
            if item.get('distribution') == '1': mechs.append('Distribution')
            if item.get('excretion') == '1': mechs.append('Excretion')
            if item.get('others') == '1': mechs.append('Others')
            
            level_map = {'1': 'Minor', '2': 'Moderate', '3': 'Major'}
            severity = level_map.get(str(item.get('level')), 'Unknown')
            
            # NOW: We need Details (Manage, Desc) AND Alternatives for this interaction.
            # v10 fetches individual interaction page for Alternatives.
            # That is 299k requests. Too slow?
            # User said "Match exactly". So we must do it.
            # But we can be smart. Only fetch details if we haven't already.
            
            interaction_id = item.get('interaction_id')
            
            # We schedule a detail fetch job
            # To be efficient, we put basic info first
            
            ddi_data = (
                interaction_id,
                drug_id,
                item.get('drug_id'), # The other drug
                severity,
                json.dumps(mechs),
                None, # Desc (pending)
                None, # Management (pending)
                None, # Alt A (pending)
                None, # Alt B (pending)
                None,
                None,
                f"{BASE_URL}/server/interact/{interaction_id}/"
            )
            await self.db_queue.put(('insert_ddi', ddi_data))
            
            # Queue the Detail Fetch
            # This will explode the queue.
            # Better: fetch details right here? No, concurrency limits apply.
            # We can create a separate "Task" for details?
            
            # For "Turbo" script, we want to fetch details.
            asyncio.create_task(self.fetch_interaction_details(interaction_id))

    async def fetch_interaction_details(self, interaction_id):
        # Rate limit check happening inside fetch
        # This fetches description, management, and ALTERNATIVES
        
        url = f"{BASE_URL}/server/interact/{interaction_id}/"
        html = await self.fetch(url)
        if not html: return
        
        soup = BeautifulSoup(html, 'html.parser')
        
        # Extract Text
        def get_text(k):
            t = soup.find('td', class_='key', string=lambda s: s and k in s)
            if t: 
                v = t.find_next_sibling('td', class_='value')
                return v.get_text(strip=True) if v else None
            return None
            
        desc = get_text('Description')
        manage = get_text('Management')
        refs = get_text('References')
        
        # Extract Alternatives
        alt_a = []
        alt_b = []
        
        # Logic: Find "Alternative for..."
        # This needs careful parsing as per v10 logic
        rows = soup.find_all('td', class_='key')
        for r in rows:
            txt = r.get_text(strip=True)
            if 'Alternative for' in txt:
                val = r.find_next_sibling('td', class_='value')
                if val:
                    alts = [x.get_text(strip=True) for x in val.find_all('a')]
                    if not alt_a: alt_a = alts
                    else: alt_b = alts
        
        # Update DB
        # We re-insert (REPLACE) or we assume basic info is there.
        # But wait, replacing overwrites missing fields?
        # SQLite REPLACE deletes and inserts row.
        # If we fetched basic info before, we lose it?
        # Basic info (Mechanisms) came from LIST.
        # Detail info comes from PAGE.
        # Page does NOT have mechanisms usually in same format.
        # Ideally we UPDATE.
        
        # Since we use `drug_drug_interactions` table, we should use UPDATE for details.
        
        # Actually, let's just make the writer handle updates or better yet:
        # Since REPLACE overwrites, we must provide ALL data.
        # But we don't have Mechanism here easily (unless we pass it).
        
        # Solution: Change Writer to support UPDATE_DETAILS
        # Or, fetch details, then construct full object? No mechanisms are from List.
        
        # Let's add 'update_ddi_details' to writer.
        
        update_data = (
            desc,
            manage,
            json.dumps(alt_a) if alt_a else None,
            json.dumps(alt_b) if alt_b else None,
            refs,
            interaction_id
        )
        
        # We need to implement this op in writer.
        # For now, let's assume we add it.
        await self.db_queue.put(('update_ddi_details', update_data))

    async def fetch_and_save_disease(self, drug_id):
        url = f"{BASE_URL}/server/interact-with-dis/{drug_id}/"
        params = { 'draw': 1, 'start': 0, 'length': 1000 }
        res = await self.fetch(url, method='POST', data=params)
        
        if res and 'data' in res:
            for item in res['data']:
                data = (
                    drug_id,
                    item.get('diseaseName'),
                    item.get('level'), # Map to text later or keep raw
                    item.get('text'),
                    item.get('references')
                )
                await self.db_queue.put(('insert_disease', data))

    async def fetch_and_save_food(self, drug_id):
        url = f"{BASE_URL}/server/interact-with-food/{drug_id}/"
        page = 0
        page_size = 100
        
        while True:
            params = {
                'draw': page + 1,
                'start': page * page_size,
                'length': page_size,
                'severity': '',
                'mechanism': ''
            }
            
            res = await self.fetch(url, method='POST', data=params)
            if not res or 'data' not in res or not res['data']:
                break
                
            for item in res['data']:
                data = (
                    drug_id,
                    item.get('foodName'),
                    {1: 'Minor', 2: 'Moderate', 3: 'Major'}.get(int(item.get('level', 0)), 'Unknown'),
                    item.get('newInteraction'), # description
                    item.get('newManagement'),
                    item.get('mechanisms'), # Sometimes here? v10 says 'magnesium'? Check keys carefully.
                    None # Refs
                )
                await self.db_queue.put(('insert_food', data))
            
            if len(res['data']) < page_size:
                break
            page += 1
            
    async def fetch_and_save_compound(self, drug_id):
        url = f"{BASE_URL}/server/interact-with-multi/{drug_id}/"
        page = 0
        page_size = 100
        
        while True:
            params = {
                'draw': page + 1,
                'start': page * page_size,
                'length': page_size
            }
            
            res = await self.fetch(url, method='POST', data=params)
            if not res or 'data' not in res or not res['data']:
                break
                
            for item in res['data']:
                data = (
                    drug_id,
                    item.get('trade_name'),
                    json.dumps(item.get('multi_drug', [])),
                    item.get('warning')
                )
                await self.db_queue.put(('insert_compound', data))
            
            if len(res['data']) < page_size:
                break
            page += 1
        
    def get_pending_drugs_sync(self, all_ids):
        conn = sqlite3.connect(DB_PATH)
        c = conn.cursor()
        c.execute("SELECT item_id FROM scrap_status WHERE item_type='drug_full' AND status='completed'")
        completed = set(r[0] for r in c.fetchall())
        conn.close()
        
        pending = [d for d in all_ids if d not in completed]
        print(f"Skipping {len(completed)} completed drugs. {len(pending)} remaining.")
        return pending

    async def main_loop(self):
        # 1. Get List
        all_ids = await self.get_all_drug_ids()
        
        # 2. Filter Pending
        pending_ids = await asyncio.to_thread(self.get_pending_drugs_sync, all_ids)
        
        # 3. Create Tasks
        tasks = []
        for d_id in pending_ids:
            tasks.append(self.process_drug(d_id))
            
            # Batch execution to respect semaphore
            if len(tasks) >= CONCURRENCY_LIMIT * 2:
                await asyncio.gather(*tasks)
                tasks = []
        
        if tasks:
            await asyncio.gather(*tasks)

if __name__ == '__main__':
    scraper = TurboScraper()
    try:
        if sys.platform == 'win32':
             asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
        asyncio.run(scraper.start())
    except KeyboardInterrupt:
        print("Stopping...")

