#!/usr/bin/env python3
"""
Bulk NCBI StatPearls Catalog Fetcher
Strategy: Fetch ENTIRE StatPearls catalog first, then match locally
This is MUCH faster and more accurate than searching one-by-one!
"""
import sqlite3
import requests
import csv
import time
import re
from pathlib import Path
from difflib import get_close_matches

# Config
DB_PATH = Path(__file__).parents[2] / "assets/database/mediswitch.db"
OUTPUT_FILE = Path(__file__).parent / "bulk_matched_targets.csv"
CATALOG_CACHE = Path(__file__).parent / "ncbi_full_catalog.csv"
USER_AGENT = "MediSwitch Research Bot (admin@mediswitch.com)"

session = requests.Session()
session.headers.update({"User-Agent": USER_AGENT})

def fetch_full_statpearls_catalog():
    """
    Fetch ENTIRE StatPearls catalog from NCBI
    This is ONE request instead of thousands!
    """
    print("📚 Fetching complete StatPearls catalog from NCBI...")
    
    # Use ESearch to get ALL StatPearls book IDs
    search_url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi"
    params = {
        "db": "books",
        "term": "StatPearls[Book]",
        "retmax": 10000,  # Get up to 10,000 results
        "retmode": "json"
    }
    
    time.sleep(1)
    response = session.get(search_url, params=params, timeout=30)
    data = response.json()
    
    id_list = data.get("esearchresult", {}).get("idlist", [])
    total_count = data.get("esearchresult", {}).get("count", 0)
    
    print(f"   Found {total_count} StatPearls articles")
    print(f"   Retrieved {len(id_list)} IDs")
    
    # Fetch summaries in batches
    catalog = []
    batch_size = 200
    
    for i in range(0, len(id_list), batch_size):
        batch = id_list[i:i+batch_size]
        print(f"   Fetching batch {i//batch_size + 1}/{(len(id_list)-1)//batch_size + 1}...")
        
        time.sleep(1)  # Rate limiting
        summary_url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi"
        summary_params = {
            "db": "books",
            "id": ",".join(batch),
            "retmode": "json"
        }
        
        try:
            response = session.get(summary_url, params=summary_params, timeout=30)
            data = response.json()
            
            for uid in batch:
                result = data.get("result", {}).get(uid, {})
                title = result.get("title", "")
                nbk = result.get("chapteraccessionid") or result.get("rid") or result.get("accession")
                
                if nbk and nbk.startswith("NBK"):
                    catalog.append({
                        "nbk_id": nbk,
                        "title": title,
                        "url": f"https://www.ncbi.nlm.nih.gov/books/{nbk}/"
                    })
        except Exception as e:
            print(f"   ⚠️ Error in batch: {e}")
            continue
    
    print(f"✅ Fetched {len(catalog)} StatPearls articles\n")
    return catalog

def save_catalog(catalog):
    """Save catalog to CSV for caching"""
    with open(CATALOG_CACHE, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=["nbk_id", "title", "url"])
        writer.writeheader()
        writer.writerows(catalog)
    print(f"💾 Saved catalog to {CATALOG_CACHE}\n")

def load_catalog():
    """Load catalog from cache if exists"""
    if CATALOG_CACHE.exists():
        print(f"📂 Loading cached catalog from {CATALOG_CACHE}...")
        with open(CATALOG_CACHE, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            catalog = list(reader)
        print(f"✅ Loaded {len(catalog)} articles from cache\n")
        return catalog
    return None

def normalize_for_matching(text):
    """Normalize text for fuzzy matching"""
    if not text:
        return ""
    # Convert to lowercase
    text = text.lower()
    # Remove common suffixes/prefixes
    text = re.sub(r'\s+(hydrochloride|hcl|sulfate|acetate|sodium|calcium)\s*$', '', text)
    # Remove doses
    text = re.sub(r'\s*\d+\.?\d*\s*(mg|mcg|gm|ml|iu|%)\s*', '', text)
    # Remove special chars
    text = re.sub(r'[^\w\s]', ' ', text)
    # Normalize spaces
    text = ' '.join(text.split())
    return text.strip()

def get_our_ingredients():
    """Get all ingredients from our database"""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("SELECT DISTINCT ingredient FROM med_ingredients WHERE ingredient IS NOT NULL AND ingredient != ''")
    ingredients = [row[0] for row in cursor.fetchall()]
    conn.close()
    print(f"📊 Loaded {len(ingredients)} ingredients from database\n")
    return ingredients

def smart_match(ingredient, catalog):
    """
    Smart matching algorithm:
    1. Exact match on normalized title
    2. Fuzzy match using difflib
    3. Substring match
    """
    normalized_ingredient = normalize_for_matching(ingredient)
    
    # Create a searchable index
    catalog_index = {}
    for item in catalog:
        normalized_title = normalize_for_matching(item['title'])
        if normalized_title:
            catalog_index[normalized_title] = item
    
    # 1. Try exact match
    if normalized_ingredient in catalog_index:
        return catalog_index[normalized_ingredient]
    
    # 2. Try fuzzy match (80% similarity)
    matches = get_close_matches(normalized_ingredient, catalog_index.keys(), n=1, cutoff=0.8)
    if matches:
        return catalog_index[matches[0]]
    
    # 3. Try substring match (ingredient is IN title)
    for title, item in catalog_index.items():
        if normalized_ingredient in title or title in normalized_ingredient:
            return item
    
    return None

def match_ingredients_to_catalog(ingredients, catalog):
    """Match all our ingredients to NCBI catalog"""
    print("🔍 Matching ingredients to NCBI catalog...\n")
    
    matched = []
    unmatched = []
    
    for idx, ingredient in enumerate(ingredients, 1):
        if idx % 100 == 0:
            print(f"   Progress: {idx}/{len(ingredients)} ({idx/len(ingredients)*100:.1f}%)")
        
        match = smart_match(ingredient, catalog)
        
        if match:
            matched.append({
                "ingredient": ingredient,
                "nbk_id": match["nbk_id"],
                "title": match["title"],
                "url": match["url"]
            })
        else:
            unmatched.append(ingredient)
    
    print(f"\n✅ Matched: {len(matched)}/{len(ingredients)} ({len(matched)/len(ingredients)*100:.1f}%)")
    print(f"❌ Unmatched: {len(unmatched)}/{len(ingredients)} ({len(unmatched)/len(ingredients)*100:.1f}%)\n")
    
    return matched, unmatched

def save_results(matched, unmatched):
    """Save results to CSV"""
    # Save matched
    with open(OUTPUT_FILE, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=["ingredient", "nbk_id", "title", "url"])
        writer.writeheader()
        writer.writerows(matched)
    print(f"✅ Saved {len(matched)} matches to {OUTPUT_FILE}")
    
    # Save unmatched for review
    unmatched_file = Path(__file__).parent / "unmatched_ingredients.txt"
    with open(unmatched_file, 'w', encoding='utf-8') as f:
        for ing in unmatched:
            f.write(f"{ing}\n")
    print(f"📝 Saved {len(unmatched)} unmatched to {unmatched_file}\n")

def main():
    print("="*70)
    print("🚀 NCBI StatPearls Bulk Catalog Matcher")
    print("="*70)
    print()
    
    # Step 1: Get catalog (from cache or fetch)
    catalog = load_catalog()
    if not catalog:
        catalog = fetch_full_statpearls_catalog()
        save_catalog(catalog)
    
    # Step 2: Get our ingredients
    ingredients = get_our_ingredients()
    
    # Step 3: Match them
    matched, unmatched = match_ingredients_to_catalog(ingredients, catalog)
    
    # Step 4: Save results
    save_results(matched, unmatched)
    
    print("="*70)
    print("🎉 DONE!")
    print(f"✅ Total Matches: {len(matched)}")
    print(f"📊 Success Rate: {len(matched)/len(ingredients)*100:.1f}%")
    print("="*70)

if __name__ == "__main__":
    main()
