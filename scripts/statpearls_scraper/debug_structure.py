import requests
from bs4 import BeautifulSoup

url = "https://www.ncbi.nlm.nih.gov/books/NBK576392/"
print(f"Fetching {url}...")

headers = {
    'User-Agent': 'Mozilla/5.0 (MediSwitch ETL Bot; Research/Educational)',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
}

try:
    res = requests.get(url, headers=headers)
    print(f"Status: {res.status_code}")
    
    soup = BeautifulSoup(res.text, 'html.parser')
    
    # 1. Print available IDs
    print("\n--- Main Divs Found ---")
    ids = [div.get('id') for div in soup.find_all('div') if div.get('id')]
    classes = [div.get('class') for div in soup.find_all('div') if div.get('class')]
    
    if 'article-details' in ids: print("✅ Found id='article-details'")
    else: print("❌ NO id='article-details'")
    
    # 2. Print all Headers
    print("\n--- Headers Found ---")
    for h in soup.find_all(['h2', 'h3', 'h4']):
        print(f"[{h.name}] {h.get_text(strip=True)[:50]}")
        
    # 3. Try to extract 'Indications'
    print("\n--- Indications Search ---")
    found = False
    for h in soup.find_all(['h2', 'h3', 'h4']):
        if "indication" in h.get_text(strip=True).lower():
            print(f"✅ Found Header: {h}")
            found = True
            
            # Print next sibling content type
            siblings = list(h.find_next_siblings())
            if siblings:
                print(f"   Next sibling type: {siblings[0].name}")
                print(f"   Next sibling text: {siblings[0].get_text(strip=True)[:100]}...")
            else:
                print("   ⚠️ No siblings!")
                
    if not found:
        print("❌ 'Indications' header NOT found")

except Exception as e:
    print(e)
