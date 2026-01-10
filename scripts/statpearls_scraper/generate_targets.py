#!/usr/bin/env python3
"""
NCBI Target Generator
Maps local ingredients (from SQLite) to NCBI StatPearls Books via E-Utilities API.
Generates a targets.csv file for the scraper.
"""

import sqlite3
import requests
import csv
import time
import os
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

# Configuration
DB_PATH = Path(__file__).parents[2] / "assets/database/mediswitch.db"
OUTPUT_FILE = Path(__file__).parent / "targets.csv"
CACHE_FILE = Path(__file__).parent / "targets_cache.json"

# NCBI E-Utilities
ESEARCH_URL = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi"
API_KEY = "" # Optional: Add API key if available for higher rate limits
USER_AGENT = "MediSwitch ETL Bot (admin@mediswitch.com)"

def get_db_ingredients():
    """Fetch distinct ingredients from local DB"""
    print(f"📂 Connecting to database: {DB_PATH}")
    if not DB_PATH.exists():
        raise FileNotFoundError(f"Database not found at {DB_PATH}")
        
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("SELECT DISTINCT ingredient FROM med_ingredients WHERE ingredient IS NOT NULL AND ingredient != ''")
    ingredients = [row[0] for row in cursor.fetchall()]
    conn.close()
    print(f"✅ Found {len(ingredients)} unique ingredients.")
    return ingredients

def search_ncbi(ingredient):
    """Search NCBI Bookshelf for StatPearls book matching the ingredient"""
    query = f"StatPearls [Book] AND {ingredient} [Title]"
    params = {
        "db": "books",
        "term": query,
        "retmode": "json",
    }
    
    try:
        # Rate limit (3 requests/sec without API key)
        time.sleep(0.34) 
        
        response = requests.get(ESEARCH_URL, params=params, headers={"User-Agent": USER_AGENT}, timeout=10)
        response.raise_for_status()
        data = response.json()
        
        id_list = data.get("esearchresult", {}).get("idlist", [])
        
        if id_list:
            # Return the first match. In a more complex version, we might fetch summaries
            # to verify exact title match, but usually top result for specific query is good.
            # However, ESearch gives UIDs (numbers). We need the NBK ID (e.g., NBK5678).
            # We can't get NBK ID directly from ESearch JSON easily without ESummary.
            # Actually, let's try a different approach: ESummary on the ID.
            
            uid = id_list[0]
            return fetch_nbk_id(uid)
            
        return None
        
    except Exception as e:
        print(f"❌ Error searching {ingredient}: {e}")
        return None

def fetch_nbk_id(uid):
    """Fetch Summary to get the visible NBK ID (Book Accession ID)"""
    ESUMMARY_URL = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi"
    params = {
        "db": "books",
        "id": uid,
        "retmode": "json"
    }
    
    try:
        response = requests.get(ESUMMARY_URL, params=params, headers={"User-Agent": USER_AGENT}, timeout=10)
        data = response.json()
        result = data.get("result", {}).get(uid, {})
        
        # Accession ID is usually the book ID like NBK...
        accession = result.get("accession") # This might be the book ID or article ID
        # StatPearls chapters often have IDs starting with NBK
        
        # Let's check 'bookaccession' or similar fields if 'accession' isn't right.
        # But commonly 'accession' or 'uids' list contains it.
        # Actually, for books db, the article ID (NBK...) is often the accession.
        
        if accession:
            return accession
        return None
        
    except Exception as e:
        print(f"❌ Error fetching summary for {uid}: {e}")
        return None

def process_batch(ingredients, max_workers=5):
    """Process ingredients in parallel (careful with rate limits)"""
    results = []
    
    print(f"🚀 Starting NCBI mapping for {len(ingredients)} ingredients...")
    
    # Check for existing results to resume
    existing_map = {}
    if OUTPUT_FILE.exists():
        with open(OUTPUT_FILE, 'r', encoding='utf-8') as f:
            reader = csv.reader(f)
            next(reader, None) # header
            for row in reader:
                if len(row) >= 2:
                    existing_map[row[0]] = row[1]
    
    print(f"⏭️  Skipping {len(existing_map)} already mapped ingredients.")
    
    to_process = [i for i in ingredients if i not in existing_map]
    
    # We will use a sequential loop for now to strict adherence to rate limits
    # Multi-threading E-Utils without API key is risky (IP ban).
    # "Up to 3 requests per second" -> 0.34s delay per request.
    
    count = 0
    with open(OUTPUT_FILE, 'a', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        if OUTPUT_FILE.stat().st_size == 0:
            writer.writerow(["ingredient", "nbk_id", "url"])
            
        for ingredient in to_process:
            nbk_id = search_ncbi(ingredient)
            if nbk_id:
                url = f"https://www.ncbi.nlm.nih.gov/books/{nbk_id}/"
                print(f"✅ Mapped: {ingredient} -> {nbk_id}")
                writer.writerow([ingredient, nbk_id, url])
                f.flush() # Ensure it's written
            else:
                print(f"⚠️  No match: {ingredient}")
                # We could write a "null" record to avoid re-searching?
                # For now let's just log it.
            
            count += 1
            if count % 10 == 0:
                print(f"📊 Progress: {count}/{len(to_process)}")

    print("🏁 Mapping complete.")

if __name__ == "__main__":
    ingredients = get_db_ingredients()
    process_batch(ingredients)
