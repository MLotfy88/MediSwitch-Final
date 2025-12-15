#!/usr/bin/env python3
"""
FINAL Production Scraper - Extracts ALL Available Fields Correctly
Based on actual HTML table structure analysis
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

def extract_from_table(soup):
    """
    Extract data from HTML table structure
    The table has rows with Arabic labels in first column, values in second
    """
    data = {}
    
    # Find all table rows
    rows = soup.find_all('tr')
    
    # Field mapping: Arabic Label -> English Key
    field_map = {
        'الاسم التجاري': 'trade_name',
        'الاسم العلمي': 'active',
        'التصنيف': 'category',
        'الشركة المنتجة': 'company',
        'السعر الجديد الحالي': 'price',
        'السعر القديم': 'old_price',
        'آخر تحديث للسعر': 'last_price_update',
        'عدد الوحدات': 'units',
        'رمز الباركود': 'barcode',
        'رمز': 'qr_code',
        'الفارماكولوجي': 'pharmacology',
        'دواعي استعمال': 'usage',
    }
    
    for row in rows:
        cells = row.find_all(['td', 'th'])
        if len(cells) >= 2:
            label = clean_text(cells[0].get_text())
            value = clean_text(cells[1].get_text())
            
            # Match against our field map
            for ar_label, en_key in field_map.items():
                if ar_label in label:
                    data[en_key] = value
                    break
    
    return data

def fetch_drug(session, drug_id):
    """Fetch and parse drug page using table extraction"""
    url = f"{BASE_URL}{drug_id}"
    response = session.get(url, headers={'User-Agent': USER_AGENT})
    
    if response.status_code != 200:
        print(f"❌ Failed to fetch ID {drug_id}")
        return None
    
    soup = BeautifulSoup(response.text, 'html.parser')
    
    data = {'id': str(drug_id)}
    
    # Get Arabic Name from H1
    h1 = soup.find('h1')
    if h1:
        arabic_name = clean_text(h1.text).replace('سعر', '').strip()
        data['arabic_name'] = arabic_name
    else:
        data['arabic_name'] = ""
    
    # Extract from table
    table_data = extract_from_table(soup)
    data.update(table_data)
    
    # Extract usage (دواعي استعمال) - appears in a separate section
    text = soup.get_text("\n")
    usage_match = re.search(r'دواعي استعمال.*?:\s*\n+(.*?)(?=\n\n\n|\nنموذج إبلاغ|$)', 
                           text, re.DOTALL)
    if usage_match:
        usage_text = usage_match.group(1).strip()
        # Clean up excessive newlines but keep structure
        usage_text = re.sub(r'\n{3,}', '\n\n', usage_text)
        data['usage'] = usage_text
    else:
        data['usage'] = ""

    
    # Extract concentration from trade_name
    if data.get('trade_name'):
        conc_match = re.search(r'(\d+(?:\.\d+)?%?)\s*(?:mg|gm|ml|mcg|unit|iu|%)', 
                               data['trade_name'], re.IGNORECASE)
        data['concentration'] = conc_match.group(0) if conc_match else ""
    else:
        data['concentration'] = ""
    
    # Guess dosage form from trade name and arabic name
    trade_lower = data.get('trade_name', '').lower()
    arabic = data.get('arabic_name', '')
    
    form = 'Unknown'
    if 'tab' in trade_lower or 'اقراص' in arabic or 'قرص' in arabic: form = 'Tablet'
    elif 'cap' in trade_lower or 'كبسول' in arabic: form = 'Capsule'
    elif 'syr' in trade_lower or 'شراب' in arabic: form = 'Syrup'
    elif 'vial' in trade_lower or 'amp' in trade_lower or 'حقن' in arabic or 'امبول' in arabic: form = 'Vial/Amp'
    elif 'cream' in trade_lower or 'كريم' in arabic: form = 'Cream'
    elif 'oint' in trade_lower or 'مرهم' in arabic: form = 'Ointment'
    elif 'drop' in trade_lower or 'نقط' in arabic: form = 'Drops'
    elif 'supp' in trade_lower or 'لبوس' in arabic: form = 'Suppository'
    elif 'eff' in trade_lower or 'فوار' in arabic: form = 'Effervescent'
    
    data['dosage_form'] = form
    
    # Get visits count
    text = soup.get_text()
    visits_match = re.search(r'قام عدد.*?(\d+).*?شخص', text, re.DOTALL)
    data['visits'] = visits_match.group(1) if visits_match else ""
    
    return data

def main():
    if len(sys.argv) < 2:
        print("Usage: python scraper_final.py <drug_id>")
        sys.exit(1)
    
    drug_id = sys.argv[1]
    session = requests.Session()
    
    if not login(session):
        print("❌ Login failed")
        sys.exit(1)
    
    result = fetch_drug(session, drug_id)
    
    if result:
        print("="*80)
        print("EXTRACTED DATA:")
        print("="*80)
        for key, value in result.items():
            status = "✅" if value else "⚠️ "
            print(f"{status} {key:20} = {value}")
        
        print("\n" + "="*80)
        print("JSON OUTPUT:")
        print("="*80)
        print(json.dumps(result, ensure_ascii=False, indent=2))
        print("\n✅ Extraction complete!")
    else:
        print("\n❌ Extraction failed!")

if __name__ == "__main__":
    main()
