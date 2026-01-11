#!/usr/bin/env python3
"""
NCBI Async Scraper
High-speed asynchronous scraper for StatPearls Books.
Reads from targets.csv and saves JSON data.
"""

import aiohttp
import asyncio
import csv
import json
import time
import os
import random
from pathlib import Path
from bs4 import BeautifulSoup

# Configuration
BASE_DIR = Path(__file__).parent
OUTPUT_DIR = BASE_DIR / "scraped_data"
TARGETS_FILE = BASE_DIR / "targets.csv"
PROGRESS_FILE = BASE_DIR / "progress.json"

# Rate Limiting & Concurrency
MAX_CONCURRENT_REQUESTS = 20
DELAY_RANGE = (0.5, 1.5)  # Seconds

# Headers
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (MediSwitch ETL Bot; Research/Educational)',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.5',
}

async def fetch_url(session, url, retries=3):
    """Fetch URL with retries and exponential backoff"""
    for attempt in range(retries):
        try:
            # Random delay for politeness
            await asyncio.sleep(random.uniform(*DELAY_RANGE))
            
            async with session.get(url, timeout=60) as response:
                if response.status == 200:
                    return await response.text()
                elif response.status == 429:
                    wait = 2 ** attempt * 5
                    print(f"⚠️ 429 Too Many Requests. Waiting {wait}s...")
                    await asyncio.sleep(wait)
                elif response.status == 404:
                    print(f"❌ 404 Not Found: {url}")
                    return None # No retry for 404
                else:
                    print(f"⚠️ Status {response.status} for {url}")
        except Exception as e:
            print(f"❌ Error fetching {url}: {e}")
            await asyncio.sleep(2 ** attempt)
            
    return None

def parse_html(html, drug_name, nbk_id, url):
    """Parse StatPearls HTML structure with improved flexibility"""
    soup = BeautifulSoup(html, 'html.parser')
    
    # Locate main content - Try multiple selectors
    content_div = soup.find('div', {'id': 'article-details'}) or \
                  soup.find('div', class_='content') or \
                  soup.find('article') or \
                  soup.find('div', class_='book-content') # Added selector
                  
    if not content_div:
        # Last resort: try extracting from body if specific div not found
        content_div = soup.body
        if not content_div:
            return None
        
    drug_data = {
        "drug_name": drug_name,
        "nbk_id": nbk_id,
        "url": url,
        "scraped_at": time.strftime("%Y-%m-%dT%H:%M:%S"),
        "sections": {}
    }
    
    target_sections = {
        "Indications": "indications",
        "Administration": "administration",
        "Adverse Effects": "adverse_effects",
        "Contraindications": "contraindications",
        "Monitoring": "monitoring",
        "Mechanism of Action": "mechanism",
        "Toxicity": "toxicity",
        "Clinical Significance": "clinical_significance"
    }
    
    # Analyze Headers (h2, h3, h4) since structure varies
    headers = content_div.find_all(['h2', 'h3', 'h4'])
    
    for header in headers:
        title = header.get_text(strip=True)
        key = None
        
        for k, v in target_sections.items():
            if k.lower() in title.lower():
                key = v
                break
        
        if key and key not in drug_data["sections"]: # Don't overwrite higher level headers
            content = []
            for sibling in header.find_next_siblings():
                if sibling.name in ['h2', 'h3', 'h4'] and sibling.name <= header.name:
                    break # Stop at next header of same or higher level
                
                if sibling.name in ['p', 'ul', 'ol', 'div']:
                    text = sibling.get_text(separator='\n', strip=True)
                    if text:
                        content.append(text)
            
            if content:
                drug_data["sections"][key] = '\n\n'.join(content)
                
    return drug_data if drug_data["sections"] else None

def save_json(data):
    """Save data to sorted subdirectories (A/Amiodarone.json)"""
    name = data['drug_name']
    first_letter = name[0].upper() if name[0].isalpha() else '#'
    
    folder = OUTPUT_DIR / first_letter
    folder.mkdir(parents=True, exist_ok=True)
    
    safe_name = name.replace('/', '_').replace(' ', '_')
    file_path = folder / f"{safe_name}.json"
    
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        
    return file_path

async def worker(queue, session, stats):
    """Worker to process scraping tasks from queue"""
    while True:
        item = await queue.get()
        ingredient, nbk_id, url = item
        
        # Check if already done
        safe_name = ingredient.replace('/', '_').replace(' ', '_')
        first_letter = ingredient[0].upper() if ingredient[0].isalpha() else '#'
        if (OUTPUT_DIR / first_letter / f"{safe_name}.json").exists():
            stats['skipped'] += 1
            queue.task_done()
            continue
            
        print(f"📥 Fetching: {ingredient} ({nbk_id})")
        html = await fetch_url(session, url)
        
        if html:
            data = parse_html(html, ingredient, nbk_id, url)
            if data:
                save_json(data)
                stats['success'] += 1
                print(f"✅ Saved: {ingredient}")
            else:
                stats['empty'] += 1
                print(f"⚠️ Empty content: {ingredient}")
        else:
            stats['failed'] += 1
            print(f"❌ Failed: {ingredient}")
            
        queue.task_done()

async def main():
    if not TARGETS_FILE.exists():
        print("❌ targets.csv found! Run generate_targets.py first.")
        return
        
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    
    # Load targets
    queue = asyncio.Queue()
    total = 0
    with open(TARGETS_FILE, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        next(reader, None) # header
        for row in reader:
            if len(row) >= 3:
                ingredient, nbk_id, url = row[:3]
                if nbk_id == "NO_MATCH" or not url:
                    stats['skipped'] += 1
                    continue
                    
                queue.put_nowait(row)
                total += 1
                
    print(f"🚀 Loaded {total} targets")
    
    stats = {'success': 0, 'failed': 0, 'empty': 0, 'skipped': 0}
    
    async with aiohttp.ClientSession(headers=HEADERS) as session:
        workers = [
            asyncio.create_task(worker(queue, session, stats))
            for _ in range(MAX_CONCURRENT_REQUESTS)
        ]
        
        # Progress reporter
        while not queue.empty():
            done = total - queue.qsize()
            print(f"📊 Progress: {done}/{total} | ✅ {stats['success']} | ⏭️ {stats['skipped']} | ❌ {stats['failed']}")
            await asyncio.sleep(5)
            
        await queue.join()
        
        for w in workers:
            w.cancel()
            
    print("\n🏁 Scraping Complete!")
    print(stats)

if __name__ == "__main__":
    asyncio.run(main())
