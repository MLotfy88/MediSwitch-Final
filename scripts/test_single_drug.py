#!/usr/bin/env python3
"""
Test Single Drug Scraper
Fetches data for a single drug ID and displays the extracted fields
"""

import requests
from bs4 import BeautifulSoup
import re
import json

# Configuration
LOGIN_URL = "https://dwaprices.com/signin.php"
SERVER_URL = "https://dwaprices.com/server.php"
BASE_URL = "https://dwaprices.com/med.php?id="
PHONE = "01558166440"
TOKEN = "bfwh2025-03-17"

USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'

def clean_text(text):
    if not text: return ""
    return re.sub(r'\s+', ' ', text).strip()

def login(session):
    """Login to dwaprices.com"""
    try:
        # Step 1
        data1 = {'checkLoginForPrices': 1, 'phone': PHONE, 'tokenn': TOKEN}
        r1 = session.post(SERVER_URL, data=data1, headers={'User-Agent': USER_AGENT})
        resp1 = r1.json()
        
        if resp1.get('numrows', 0) > 0 and 'data' in resp1:
            u = resp1['data'][0]
            print(f"✅ Login Step 1 OK: {u.get('name')}")
            
            # Step 2
            data2 = {
                'accessgranted': 1, 'namepricesub': u.get('name'),
                'phonepricesub': u.get('phone'), 'tokenpricesub': u.get('token'),
                'grouppricesub': u.get('usergroup'), 'approvedsub': u.get('approved'),
                'IDpricesub': u.get('id')
            }
            r2 = session.post(LOGIN_URL, data=data2, headers={'User-Agent': USER_AGENT})
            if r2.status_code == 200:
                print("✅ Login Step 2 OK. Session secured.\n")
                return True
    except Exception as e:
        print(f"❌ Login Failed: {e}")
    return False

def fetch_drug(session, drug_id):
    """Fetch and parse drug page"""
    url = f"{BASE_URL}{drug_id}"
    response = session.get(url, headers={'User-Agent': USER_AGENT})
    
    if response.status_code != 200:
        print(f"❌ Failed to fetch ID {drug_id}")
        return None
    
    soup = BeautifulSoup(response.text, 'html.parser')
    text = soup.get_text("\n")
    
    print("="*80)
    print(f"RAW TEXT EXTRACTION (First 2000 chars):")
    print("="*80)
    print(text[:2000])
    print("\n" + "="*80)
    print("PARSED FIELDS:")
    print("="*80)
    
    data = {'id': str(drug_id)}
    
    # 1. Arabic Name
    h1 = soup.find('h1')
    if h1:
        raw_ar = clean_text(h1.text)
        data['arabic_name'] = raw_ar.replace('سعر', '').strip()
        print(f"✅ arabic_name: {data['arabic_name']}")
    
    # 2. Extract fields using regex
    patterns = {
        'trade_name': r'الاسم التجاري.*?[:]?\\s*\\n+(.*?)\\n',
        'active': r'الاسم العلمي.*?[:]?\\s*\\n+(.*?)\\n',
        'company': r'الشركة المنتجة.*?[:]?\\s*\\n+(.*?)\\n',
        'price': r'السعر الجديد الحالي.*?[:]?\\s*\\n+(\\d+(?:\\.\\d+)?)',
        'old_price': r'السعر القديم.*?[:]?\\s*\\n+(\\d+(?:\\.\\d+)?)',
        'category': r'التصنيف الدوائي.*?[:]?\\s*\\n+(.*?)\\n',
        'last_update': r'آخر تحديث.*?[:]?\\s*\\n+(.*?)\\n',
        'units': r'عدد الوحدات.*?[:]?\\s*\\n+(.*?)\\n',
        'unit_price': r'سعر الوحدة.*?[:]?\\s*\\n+(\\d+(?:\\.\\d+)?)',
        'barcode': r'رمز الباركود.*?[:]?\\s*\\n+(\\d+)',
        'qr_code': r'رمز الكيو آر كود.*?[:]?\\s*\\n+(.*?)\\n',
        'pharmacology': r'الفارماكولوجي.*?[:]?\\s*\\n+(.*?)\\n',
        'usage': r'دواعي استعمال.*?[:]?\\s*\\n+(.*?)\\n',
    }
    
    for key, pat in patterns.items():
        match = re.search(pat, text)
        value = clean_text(match.group(1)) if match else ""
        data[key] = value
        
        # Color code output
        if value:
            print(f"✅ {key}: {value}")
        else:
            print(f"⚠️  {key}: (empty)")
    
    print("\n" + "="*80)
    print("JSON OUTPUT:")
    print("="*80)
    print(json.dumps(data, ensure_ascii=False, indent=2))
    
    return data

def main():
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: python test_single_drug.py <drug_id>")
        sys.exit(1)
    
    drug_id = sys.argv[1]
    
    session = requests.Session()
    
    if not login(session):
        print("❌ Login failed")
        sys.exit(1)
    
    result = fetch_drug(session, drug_id)
    
    if result:
        print("\n✅ Extraction complete!")
    else:
        print("\n❌ Extraction failed!")

if __name__ == "__main__":
    main()
