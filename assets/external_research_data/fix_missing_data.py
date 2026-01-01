import asyncio
import aiohttp
import sqlite3
import time
import json
import logging
import sys
from bs4 import BeautifulSoup
from asyncio import Semaphore

# Configuration
DB_PATH = 'ddinter_complete.db'
BASE_URL = 'https://ddinter2.scbdd.com'
CONCURRENCY_LIMIT = 50           # High concurrency for speed
HEADERS_GET = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
}

# Logging Setup
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.FileHandler("fix_data_log.txt"),
        logging.StreamHandler(sys.stdout)
    ]
)

# Shared Resources
db_queue = asyncio.Queue()

async def db_writer():
    """Single thread for database writes to avoid locking."""
    conn = sqlite3.connect(DB_PATH, check_same_thread=False)
    cursor = conn.cursor()
    conn.execute("PRAGMA journal_mode=WAL;")
    conn.execute("PRAGMA synchronous=NORMAL;")
    
    batch_size = 100
    batch = []
    
    while True:
        try:
            op, data = await db_queue.get()
            if op == 'STOP':
                if batch:
                    _exec_batch(conn, batch)
                break
            
            batch.append((op, data))
            if len(batch) >= batch_size:
                _exec_batch(conn, batch)
                batch = []
                
            db_queue.task_done()
        except Exception as e:
            logging.error(f"DB Writer Error: {e}")

    conn.close()

def _exec_batch(conn, batch):
    try:
        cursor = conn.cursor()
        for op, data in batch:
            if op == 'UPDATE_DRUG':
                # data: (atc_codes, structure_svg, drug_id)
                cursor.execute("UPDATE drugs SET atc_codes=?, structure_2d_svg=? WHERE ddinter_id=?", data)
            elif op == 'UPDATE_DDI':
                # data: (description, interaction_id)
                cursor.execute("UPDATE drug_drug_interactions SET interaction_description=? WHERE interaction_id=?", data)
        conn.commit()
    except Exception as e:
        logging.error(f"Batch Commit Error: {e}")

async def fetch_html(session, url):
    """Fetch HTML with retries"""
    for attempt in range(3):
        try:
            async with session.get(url, headers=HEADERS_GET, timeout=20) as resp:
                if resp.status == 200:
                    return await resp.text()
                elif resp.status == 404:
                    return None
        except Exception:
            await asyncio.sleep(1)
    return None

async def process_drug(session, sem, drug_id):
    async with sem:
        url = f"{BASE_URL}/server/drug-detail/{drug_id}/"
        html = await fetch_html(session, url)
        if not html: return

        soup = BeautifulSoup(html, 'html.parser')

        # 1. ATC Codes (Look for Table Row 'ATC Classification')
        atc_codes = []
        atc_key = soup.find('td', class_='key', string=lambda s: s and 'ATC Classification' in s)
        if atc_key:
            atc_val = atc_key.find_next_sibling('td')
            if atc_val:
                # Spans with badge class
                atc_codes = [s.get_text(strip=True) for s in atc_val.find_all('span', class_='badge')]
        
        # 2. SVG (First SVG in document)
        svg_tag = soup.find('svg')
        svg_str = str(svg_tag) if svg_tag else None

        if atc_codes or svg_str:
            await db_queue.put(('UPDATE_DRUG', (json.dumps(atc_codes), svg_str, drug_id)))

async def process_ddi(session, sem, interaction_id):
    async with sem:
        url = f"{BASE_URL}/server/interact/{interaction_id}/"
        html = await fetch_html(session, url)
        if not html: return

        soup = BeautifulSoup(html, 'html.parser')

        # 1. Description (Labeled as 'Interaction' in HTML)
        description = None
        key_td = soup.find('td', class_='key', string=lambda s: s and 'Interaction' in s)
        if key_td:
            val_td = key_td.find_next_sibling('td', class_='value')
            if val_td:
                description = val_td.get_text(strip=True)

        if description:
            await db_queue.put(('UPDATE_DDI', (description, interaction_id)))

async def main():
    if not os.path.exists(DB_PATH):
        print("Database not found!")
        return

    # Start DB Writer
    writer_task = asyncio.create_task(db_writer())
    
    # 1. Identify Missing Drugs
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    
    print("🔍 Scanning for incomplete Drugs...")
    # Check for empty ATC or empty SVG
    c.execute("SELECT ddinter_id FROM drugs WHERE (atc_codes IS NULL OR atc_codes = '[]') OR (structure_2d_svg IS NULL)")
    drugs_to_fix = [r[0] for r in c.fetchall()]
    print(f"📋 Found {len(drugs_to_fix)} drugs to repair.")

    # 2. Identify Missing DDIs
    print("🔍 Scanning for incomplete Interactions (Description)...")
    # Check for empty description
    c.execute("SELECT interaction_id FROM drug_drug_interactions WHERE interaction_description IS NULL OR interaction_description = '' OR interaction_description = 'null'")
    ddis_to_fix = [r[0] for r in c.fetchall()]
    print(f"📋 Found {len(ddis_to_fix)} interactions to repair.")
    
    conn.close()

    sem = Semaphore(CONCURRENCY_LIMIT)
    
    async with aiohttp.ClientSession() as session:
        # Process Drugs
        if drugs_to_fix:
            print(f"🚀 Starting Drug Repairs ({len(drugs_to_fix)})...")
            tasks = [process_drug(session, sem, did) for did in drugs_to_fix]
            # Use gather with tqdm or manual logging? manual for simplicity
            for i, f in enumerate(asyncio.as_completed(tasks)):
                await f
                if i % 100 == 0:
                    print(f"   Processed Drugs: {i}/{len(drugs_to_fix)}", end='\r')
            print("\n✅ Drug Repairs Completed.")

        # Process DDIs
        if ddis_to_fix:
            print(f"🚀 Starting Interaction Repairs ({len(ddis_to_fix)})...")
            tasks = [process_ddi(session, sem, iid) for iid in ddis_to_fix]
            count = 0
            total = len(ddis_to_fix)
            
            # Start in chunks to avoid memory explosion with 300k tasks
            chunk_size = 5000
            for i in range(0, total, chunk_size):
                chunk = tasks[i:i+chunk_size]
                await asyncio.gather(*chunk)
                print(f"   Processed Interactions: {min(i+chunk_size, total)}/{total}", end='\r')
                
            print("\n✅ Interaction Repairs Completed.")

    # Stop DB Writer
    await db_queue.put(('STOP', None))
    await writer_task
    print("🎉 All repairs finished!")

if __name__ == '__main__':
    import os
    asyncio.run(main())
