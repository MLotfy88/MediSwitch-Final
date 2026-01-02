import asyncio
import aiohttp
from bs4 import BeautifulSoup
import sqlite3
import json

BASE_URL = "https://ddinter2.scbdd.com"
DB_PATH = "assets/external_research_data/ddinter_complete.db"

async def fetch(session, url):
    try:
        async with session.get(url, timeout=15) as response:
            if response.status == 200:
                return await response.text()
    except Exception as e:
        print(f"Error fetching {url}: {e}")
    return None

async def fix_drug(session, drug_id, db_conn):
    url = f"{BASE_URL}/server/drug-detail/{drug_id}/"
    html = await fetch(session, url)
    if not html:
        return False
    
    soup = BeautifulSoup(html, 'html.parser')
    # Correct selector for drug name: usually <h1> or similar
    name_tag = soup.find('h1')
    if not name_tag:
        return False
    
    drug_name = name_tag.get_text(strip=True)
    if drug_name == "DDInter 2.0":
        # Sometimes the title is inside a specific div or table
        # Let's try to find the actual name
        title_tag = soup.find('div', class_='title')
        if title_tag:
            drug_name = title_tag.get_text(strip=True)
    
    # If still "DDInter 2.0", check the breadcrumbs or other elements
    if drug_name == "DDInter 2.0":
        breadcrumb = soup.find('li', class_='active')
        if breadcrumb:
            drug_name = breadcrumb.get_text(strip=True)

    print(f"Fixed {drug_id}: {drug_name}")
    
    cursor = db_conn.cursor()
    cursor.execute("UPDATE drugs SET drug_name = ? WHERE ddinter_id = ?", (drug_name, drug_id))
    db_conn.commit()
    return True

async def main():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("SELECT ddinter_id FROM drugs WHERE drug_name = 'DDInter 2.0'")
    drug_ids = [row[0] for row in cursor.fetchall()]
    
    print(f"Found {len(drug_ids)} drugs to fix.")
    
    async with aiohttp.ClientSession() as session:
        tasks = []
        # Process in chunks to avoid overwhelming the server
        for i in range(0, len(drug_ids), 20):
            batch = drug_ids[i:i+20]
            tasks = [fix_drug(session, d_id, conn) for d_id in batch]
            await asyncio.gather(*tasks)
            await asyncio.sleep(1) # Be nice
            
    conn.close()
    print("Optimization/Fix complete.")

if __name__ == "__main__":
    asyncio.run(main())
