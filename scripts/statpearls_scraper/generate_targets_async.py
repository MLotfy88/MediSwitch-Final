#!/usr/bin/env python3
"""
FAST NCBI StatPearls Target Generator (Async)
Maps med_ingredients to NCBI Book IDs (NBK...)
OPTIMIZED FOR SPEED: 5x-10x faster than synchronous version.
Uses asyncio + aiohttp with smart rate limiting.
"""
import asyncio
import aiohttp
import sqlite3
import csv
import time
import re
import os
from pathlib import Path
from collections import deque

# Import name normalization
from drug_name_corrections import normalize_drug_name, PRECOMPUTED_CORRECTIONS

# Config
DB_PATH = Path(__file__).parents[2] / "assets/database/mediswitch.db"
OUTPUT_FILE = Path(__file__).parent / "targets.csv"
USER_AGENT = "MediSwitch Research Bot (admin@mediswitch.com)"
ESEARCH_URL = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi"
ESUMMARY_URL = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi"

# NCBI Limits: 3 req/sec without API key, 10 req/sec with API key
API_KEY = os.getenv("NCBI_API_KEY")
MAX_CONCURRENT_REQUESTS = 10 if API_KEY else 3

class RateLimiter:
    """Token bucket rate limiter"""
    def __init__(self, rate_limit):
        self.rate_limit = rate_limit
        self.tokens = rate_limit
        self.updated_at = time.monotonic()
        self.lock = asyncio.Lock()

    async def wait(self):
        async with self.lock:
            now = time.monotonic()
            elapsed = now - self.updated_at
            self.tokens = min(self.rate_limit, self.tokens + elapsed * self.rate_limit)
            self.updated_at = now
            
            if self.tokens < 1:
                wait_time = (1 - self.tokens) / self.rate_limit
                await asyncio.sleep(wait_time)
                self.tokens = 0
                self.updated_at = time.monotonic()
            else:
                self.tokens -= 1

def clean_name(ingredient):
    """Smart name cleaning with normalization"""
    if not ingredient: return ""
    lower = ingredient.lower().strip()
    if lower in PRECOMPUTED_CORRECTIONS: return PRECOMPUTED_CORRECTIONS[lower]
    normalized = normalize_drug_name(ingredient)
    return re.sub(r'\(.*?\)', '', normalized).strip()

def get_all_ingredients():
    """Fetch all PHARMACEUTICAL ingredients (enhanced filtering)"""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    # Same optimized query as before
    query = """
    SELECT DISTINCT ingredient FROM med_ingredients 
    WHERE ingredient IS NOT NULL AND ingredient != '' AND LENGTH(ingredient) >= 4
      AND (ingredient GLOB '[A-Z]*' OR ingredient GLOB '[a-z]*')
      AND LOWER(ingredient) NOT LIKE '%protein%'
      AND LOWER(ingredient) NOT LIKE '%flavor%'
      AND LOWER(ingredient) NOT LIKE '%extract%'
      AND LOWER(ingredient) NOT LIKE '%oil%'
      AND LOWER(ingredient) NOT LIKE '%wax%'
      AND LOWER(ingredient) NOT LIKE '%powder%'
      AND LOWER(ingredient) NOT LIKE '%cream%'
      AND LOWER(ingredient) NOT LIKE '%lotion%'
      AND LOWER(ingredient) NOT LIKE '%gel%'
      AND ingredient NOT LIKE '%(%'
      AND ingredient NOT LIKE '%)%'
      AND LOWER(ingredient) NOT LIKE '%tribulus%'
      AND LOWER(ingredient) NOT LIKE '%claw%'
      AND LOWER(ingredient) NOT LIKE '%leaves%'
      AND LENGTH(ingredient) - LENGTH(REPLACE(ingredient, ' ', '')) <= 2
      AND ingredient NOT LIKE '%mg%'
      AND ingredient NOT LIKE '%mcg%'
      AND ingredient NOT LIKE '%gm%'
      AND ingredient NOT LIKE '% ml%'
    """
    cursor.execute(query)
    ingredients = [row[0] for row in cursor.fetchall()]
    conn.close()
    ingredients.sort(key=lambda x: clean_name(x).lower())
    print(f"📊 Total pharma drugs (filtered): {len(ingredients)}")
    return ingredients

async def fetch_nbk_id(session, uid, rate_limiter):
    """Extract NBK ID from UID (Async)"""
    params = {"db": "books", "id": uid, "retmode": "json"}
    if API_KEY: params["api_key"] = API_KEY

    retries = 3
    for attempt in range(retries):
        await rate_limiter.wait()
        try:
            async with session.get(ESUMMARY_URL, params=params) as res:
                if res.status == 429:
                    wait_time = 5 * (2 ** attempt)
                    print(f"⚠️ Limit hit (Summary). Waiting {wait_time}s...")
                    await asyncio.sleep(wait_time)
                    continue
                
                if res.status != 200:
                    return None
                    
                data = await res.json()
                result = data.get("result", {}).get(uid, {})
                nbk = result.get("chapteraccessionid") or result.get("rid") or result.get("accession")
                if nbk and nbk.startswith("NBK"):
                    return nbk
                return None
        except Exception:
            return None
    return None

async def process_ingredient(session, ingredient, rate_limiter, writer, file_handle):
    """Process single ingredient: Search -> Fetch NBK -> Write (Async)"""
    cleaned = clean_name(ingredient)
    strategies = [
        f"StatPearls[Book] AND {cleaned}[Title]",
        f"StatPearls[Book] AND {cleaned}[All Fields]"
    ]
    
    found_nbk = None
    
    for query in strategies:
        params = {"db": "books", "term": query, "retmode": "json"}
        if API_KEY: params["api_key"] = API_KEY
        
        retries = 3
        for attempt in range(retries):
            await rate_limiter.wait()
            try:
                async with session.get(ESEARCH_URL, params=params) as res:
                    if res.status == 429:
                        wait_time = 10 * (2 ** attempt) # Backoff: 10, 20, 40s
                        print(f"⚠️ Limit hit (Search). Waiting {wait_time}s...")
                        await asyncio.sleep(wait_time)
                        continue
                        
                    if res.status != 200:
                        break
                        
                    data = await res.json()
                    ids = data.get("esearchresult", {}).get("idlist", [])
                    
                    if ids:
                        # Check top 3 results
                        for uid in ids[:3]:
                            found_nbk = await fetch_nbk_id(session, uid, rate_limiter)
                            if found_nbk:
                                break
                    break # Success or empty result
            except Exception as e:
                print(f"⚠️ Error: {e}")
                
        if found_nbk:
            break
            
    # Write result immediately
    if found_nbk:
        url = f"https://www.ncbi.nlm.nih.gov/books/{found_nbk}/"
        writer.writerow([ingredient, found_nbk, url])
        print(f"✅ {ingredient} -> {found_nbk}")
    else:
        writer.writerow([ingredient, "NO_MATCH", ""])
        print(f"❌ {ingredient}")
    
    file_handle.flush()
    return found_nbk

async def main():
    ingredients = get_all_ingredients()
    
    # Load existing
    existing = set()
    if OUTPUT_FILE.exists():
        with open(OUTPUT_FILE, 'r', encoding='utf-8') as f:
            reader = csv.reader(f)
            headers = next(reader, None)
            for row in reader:
                if row: existing.add(row[0])
    
    remaining = [i for i in ingredients if i not in existing]
    print(f"✅ Already mapped: {len(existing)}")
    print(f"🔍 Remaining: {len(remaining)}")
    
    if not remaining:
        print("🎉 No targets remaining!")
        return

    # Calculate estimated speed
    req_rate = MAX_CONCURRENT_REQUESTS
    est_seconds = len(remaining) / req_rate
    print(f"🚀 Speed mode: {req_rate} items/sec (Limited by NCBI policy)")
    print(f"⏱️  Estimated time: ~{est_seconds/60:.1f} minutes")

    rate_limiter = RateLimiter(MAX_CONCURRENT_REQUESTS)
    
    # Open file in append mode
    # NOTE: We can't use 'async with' for normal file I/O easily without aiofiles, 
    # but csv writer is fast enough for sequential writes if flushed.
    with open(OUTPUT_FILE, 'a', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        if OUTPUT_FILE.stat().st_size == 0:
            writer.writerow(["ingredient", "nbk_id", "url"])
            
        async with aiohttp.ClientSession(headers={"User-Agent": USER_AGENT}) as session:
            # Create tasks with Semaphore to limit concurrency (connections)
            semaphore = asyncio.Semaphore(MAX_CONCURRENT_REQUESTS * 2) 
            
            async def bounded_process(ing):
                async with semaphore:
                    await process_ingredient(session, ing, rate_limiter, writer, f)

            tasks = [bounded_process(ing) for ing in remaining]
            await asyncio.gather(*tasks)

if __name__ == "__main__":
    asyncio.run(main())
