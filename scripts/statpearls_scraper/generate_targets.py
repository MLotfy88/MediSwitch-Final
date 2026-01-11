#!/usr/bin/env python3
"""
NCBI StatPearls Target Generator - Production Version  
Maps med_ingredients to NCBI Book IDs (NBK...)
OPTIMIZED FOR HIGH SUCCESS RATE
"""
import sqlite3
import requests
import csv
import time
import re
from pathlib import Path

# Config
DB_PATH = Path(__file__).parents[2] / "assets/database/mediswitch.db"
OUTPUT_FILE = Path(__file__).parent / "targets.csv"
USER_AGENT = "MediSwitch Research Bot (admin@mediswitch.com)"
ESEARCH_URL = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi"
ESUMMARY_URL = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi"

session = requests.Session()
session.headers.update({"User-Agent": USER_AGENT})

def clean_name(ingredient):
    """Remove parentheses and trim"""
    if not ingredient: return ""
    return re.sub(r'\(.*?\)', '', ingredient).strip()

def get_all_ingredients():
    """Fetch all quality ingredients from DB"""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("SELECT DISTINCT ingredient FROM med_ingredients WHERE ingredient IS NOT NULL AND ingredient != ''")
    raw = [row[0] for row in cursor.fetchall()]
    conn.close()
    
    # Quality filter
    quality = []
    for ing in raw:
        cleaned = clean_name(ing)
        if cleaned and len(cleaned) >= 3 and cleaned[0].isalpha():
            # At least 70% letters
            letters = sum(c.isalpha() for c in cleaned)
            if letters / len(cleaned) > 0.7:
                quality.append(ing)
    
    quality.sort(key=lambda x: clean_name(x).lower())
    print(f"📊 Total: {len(raw)} | Quality: {len(quality)}")
    return quality

def search_ncbi(ingredient):
    """Multi-strategy NCBI search"""
    cleaned = clean_name(ingredient)
    
    # Try Title first (most accurate), then All Fields
    strategies = [
        f"StatPearls[Book] AND {cleaned}[Title]",
        f"StatPearls[Book] AND {cleaned}[All Fields]"
    ]
    
    for query in strategies:
        try:
            time.sleep(1.5)  # Conservative delay
            res = session.get(ESEARCH_URL, params={"db": "books", "term": query, "retmode": "json"}, timeout=10)
            
            if res.status_code == 429:
                print(f"⚠️ Rate Limit! Waiting 60s...")
                time.sleep(60)
                return search_ncbi(ingredient)  # Retry once
            
            if res.status_code != 200:
                continue
                
            data = res.json()
            ids = data.get("esearchresult", {}).get("idlist", [])
            
            if ids:
                # Try top 3 results
                for uid in ids[:3]:
                    nbk = fetch_nbk_id(uid)
                    if nbk:
                        return nbk
        except Exception as e:
            print(f"  ⚠️ Error: {e}")
            continue
    
    return None

def fetch_nbk_id(uid):
    """Extract NBK ID from UID"""
    try:
        time.sleep(1)
        res = session.get(ESUMMARY_URL, params={"db": "books", "id": uid, "retmode": "json"}, timeout=10)
        if res.status_code == 429:
            time.sleep(60)
            return fetch_nbk_id(uid)
        
        if res.status_code != 200:
            return None
            
        data = res.json()
        result = data.get("result", {}).get(uid, {})
        nbk = result.get("chapteraccessionid") or result.get("rid") or result.get("accession")
        
        if nbk and nbk.startswith("NBK"):
            return nbk
    except Exception:
        pass
    return None

def main():
    ingredients = get_all_ingredients()
    
    # Load existing
    existing = set()
    if OUTPUT_FILE.exists():
        with open(OUTPUT_FILE, 'r', encoding='utf-8') as f:
            reader = csv.reader(f)
            next(reader, None)  # skip header
            for row in reader:
                if row: existing.add(row[0])
    
    remaining = [i for i in ingredients if i not in existing]
    print(f"✅ Already mapped: {len(existing)}")
    print(f"🔍 Remaining: {len(remaining)}")
    print(f"⏱️  Estimated time: ~{len(remaining) * 3 / 60:.1f} minutes\n")
    
    # Process
    with open(OUTPUT_FILE, 'a', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        if OUTPUT_FILE.stat().st_size == 0:
            writer.writerow(["ingredient", "nbk_id", "url"])
        
        for idx, ing in enumerate(remaining, 1):
            print(f"[{idx}/{len(remaining)}] {ing}...", end=" ")
            nbk = search_ncbi(ing)
            
            if nbk:
                url = f"https://www.ncbi.nlm.nih.gov/books/{nbk}/"
                writer.writerow([ing, nbk, url])
                f.flush()
                print(f"✅ {nbk}")
            else:
                print("❌ No match")
            
            # Progress report every 10
            if idx % 10 == 0:
                print(f"\n📊 Progress: {idx}/{len(remaining)} ({idx/len(remaining)*100:.1f}%)\n")

if __name__ == "__main__":
    main()
