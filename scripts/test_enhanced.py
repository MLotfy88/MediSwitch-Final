#!/usr/bin/env python3
"""
Enhanced Test Script - Saves HTML and uses flexible patterns
"""

import requests
from bs4 import BeautifulSoup
import re
import json
import sys

# Configuration
LOGIN_URL = "https://dwaprices.com/signin.php"
SERVER_URL = "https://dwaprices.com/server.php"
BASE_URL = "https://dwaprices.com/med.php?id="
PHONE = "01558166440"
TOKEN = "bfwh2025-03-17"

USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'

def clean_text(text):
    if not text: return ""
    return re.sub(r'\s+', ' ', text).strip()

def login(session):
    try:
        data1 = {'checkLoginForPrices': 1, 'phone': PHONE, 'tokenn': TOKEN}
        r1 = session.post(SERVER_URL, data=data1, headers={'User-Agent': USER_AGENT})
        resp1 = r1.json()
        
        if resp1.get('numrows', 0) > 0 and 'data' in resp1:
            u = resp1['data'][0]
            print(f"✅ Login: {u.get('name')}\n")
            
            data2 = {
                'accessgranted': 1, 'namepricesub': u.get('name'),
                'phonepricesub': u.get('phone'), 'tokenpricesub': u.get('token'),
                'grouppricesub': u.get('usergroup'), 'approvedsub': u.get('approved'),
                'IDpricesub': u.get('id')
            }
            r2 = session.post(LOGIN_URL, data=data2, headers={'User-Agent': USER_AGENT})
            return r2.status_code == 200
    except Exception as e:
        print(f"❌ Login Failed: {e}")
    return False

def fetch_and_analyze(session, drug_id):
    url = f"{BASE_URL}{drug_id}"
    response = session.get(url, headers={'User-Agent': USER_AGENT})
    
    if response.status_code != 200:
        print(f"❌ Failed to fetch")
        return None
    
    # Save HTML for inspection
    html_file = f"debug_drug_{drug_id}.html"
    with open(html_file, 'w', encoding='utf-8') as f:
        f.write(response.text)
    print(f"💾 Saved HTML to: {html_file}\n")
    
    soup = BeautifulSoup(response.text, 'html.parser')
    text = soup.get_text("\n")
    
    # Save text dump
    text_file = f"debug_drug_{drug_id}_text.txt"
    with open(text_file, 'w', encoding='utf-8') as f:
        f.write(text)
    print(f"💾 Saved Text to: {text_file}\n")
    
    data = {'id': str(drug_id)}
    
    # Get Arabic Name from H1
    h1 = soup.find('h1')
    if h1:
        data['arabic_name'] = clean_text(h1.text).replace('سعر', '').strip()
    
    # UPDATED PATTERNS - More flexible with whitespace
    patterns = {
        'trade_name': r'Tarolimus.*?topical.*?gm',  # Direct English match for now
        'active': r'الاسم العلمي.*?[:]?\s*\n+(.+?)(?:\n|$)',
        'company': r'الشركة المنتجة.*?[:]?\s*\n+(.+?)(?:\n|$)',
        'price': r'السعر الجديد الحالي.*?[:]?\s*\n+.*?(\d+(?:\.\d+)?)',
        'old_price': r'السعر القديم.*?[:]?\s*\n+.*?(\d+)',
        'category': r'التصنيف الدوائي.*?[:]?\s*\n+(.+?)(?:\n|$)',
        'last_update': r'آخر تحديث.*?[:]?\s*\n+(.+?)(?:\n|$)',
        'units': r'عدد الوحدات.*?[:]?\s*\n+.*?(\d+)',
        'unit_price': r'سعر.*?الوحدة.*?[:]?\s*\n+.*?(\d+(?:\.\d+)?)',
        'barcode': r'رمز الباركود.*?[:]?\s*\n+(.+?)(?:\n|$)',
    }
    
    print("="*80)
    print("EXTRACTION RESULTS:")
    print("="*80)
    
    for key, pat in patterns.items():
        match = re.search(pat, text, re.DOTALL)
        if match:
            value = clean_text(match.group(1) if match.lastindex else match.group(0))
            data[key] = value
            print(f"✅ {key:15} = {value}")
        else:
            data[key] = ""
            print(f"❌ {key:15} = (not found)")
    
    print("\n" + "="*80)
    print("JSON OUTPUT:")
    print("="*80)
    print(json.dumps(data, ensure_ascii=False, indent=2))
    
    return data

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python test_enhanced.py <drug_id>")
        sys.exit(1)
    
    drug_id = sys.argv[1]
    session = requests.Session()
    
    if login(session):
        fetch_and_analyze(session, drug_id)
