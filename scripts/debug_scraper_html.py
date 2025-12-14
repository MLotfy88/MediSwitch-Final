import requests
from bs4 import BeautifulSoup
import re
import random

LOGIN_URL = "https://dwaprices.com/signin.php"
SERVER_URL = "https://dwaprices.com/server.php"
BASE_URL = "https://dwaprices.com/med.php?id="
PHONE = "01558166440"
TOKEN = "bfwh2025-03-17"

USER_AGENTS = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
]

def login(session):
    print("Attempting to login...")
    session.headers.update({'User-Agent': random.choice(USER_AGENTS)})
    
    payload_step1 = {'checkLoginForPrices': 1, 'phone': PHONE, 'tokenn': TOKEN}
    r1 = session.post(SERVER_URL, data=payload_step1)
    data1 = r1.json()
    
    if data1.get('numrows', 0) > 0 and 'data' in data1:
        user_data = data1['data'][0]
        print(f"User: {user_data.get('name')}")
        
        payload_step2 = {
            'accessgranted': 1,
            'namepricesub': user_data.get('name'),
            'phonepricesub': user_data.get('phone'),
            'tokenpricesub': user_data.get('token'),
            'grouppricesub': user_data.get('usergroup'),
            'approvedsub': user_data.get('approved'),
            'IDpricesub': user_data.get('id')
        }
        r2 = session.post(LOGIN_URL, data=payload_step2)
        print(f"Session set: {r2.status_code}")
        return True
    return False

def check_id(session, text_id):
    url = f"{BASE_URL}{text_id}"
    print(f"Fetching {url}...")
    r = session.get(url)
    filename = f"debug_page_{text_id}.html"
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(r.text)
    print(f"Saved to {filename}")
    
    # Try Parse
    soup = BeautifulSoup(r.text, 'html.parser')
    text = soup.get_text("\n")
    
    trade_match = re.search(r'الاسم التجاري.*?:\s*\n(.*?)\n', text)
    if trade_match:
        print(f"Matched Trade: {trade_match.group(1)}")
    else:
        print("Failed to match Trade Name regex!")
        print("Snippet around expected area:")
        # Find "الاسم التجاري" index
        idx = text.find("الاسم التجاري")
        if idx != -1:
            print(text[idx:idx+200])
        else:
            print("String 'الاسم التجاري' not found in text dump.")

session = requests.Session()
if login(session):
    check_id(session, "22455")
