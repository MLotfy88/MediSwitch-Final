import requests
from bs4 import BeautifulSoup
import json
import re

# Configuration
LOGIN_URL = "https://dwaprices.com/signin.php"
SERVER_URL = "https://dwaprices.com/server.php"
LASTMORE_URL = "https://dwaprices.com/lastmore.php"
PHONE = "01558166440"
TOKEN = "bfwh2025-03-17"
USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'

def login_and_fetch_lastmore():
    session = requests.Session()
    session.headers.update({'User-Agent': USER_AGENT})
    
    # Step 1: Server check
    print("Logging in (Step 1)...")
    payload1 = {'checkLoginForPrices': 1, 'phone': PHONE, 'tokenn': TOKEN}
    r1 = session.post(SERVER_URL, data=payload1)
    data1 = r1.json()
    
    if data1.get('numrows', 0) > 0 and 'data' in data1:
        u = data1['data'][0]
        print(f"User: {u.get('name')}")
        
        # Step 2: Signin session
        print("Logging in (Step 2)...")
        payload2 = {
            'accessgranted': 1,
            'namepricesub': u.get('name'),
            'phonepricesub': u.get('phone'),
            'tokenpricesub': u.get('token'),
            'grouppricesub': u.get('usergroup'),
            'approvedsub': u.get('approved'),
            'IDpricesub': u.get('id')
        }
        session.post(LOGIN_URL, data=payload2)
        
        # Step 3: Fetch LastPrices via AJAX simulation
        print(f"Simulating AJAX to server.php with lastprices=0...")
        payload_ajax = {'lastprices': 0}
        r_ajax = session.post(SERVER_URL, data=payload_ajax)
        
        try:
            results = r_ajax.json()
            print(f"Success! Found {results.get('numrows', 0)} total records.")
            data = results.get('data', [])
            print(f"Received {len(data)} items in first batch.")
            
            if data:
                print("Sample updated drug data:")
                for item in data[:5]:
                    print(f"ID: {item.get('id')}, Name: {item.get('name')}, Price: {item.get('price')}, Date: {item.get('Date_updated')}")
                
                # Save IDs to a file for reference
                with open("updated_ids.json", "w", encoding="utf-8") as f:
                    json.dump(data, f, ensure_ascii=False, indent=2)
                print("Saved batch data to updated_ids.json")
        except Exception as e:
            print(f"Failed to parse AJAX response: {e}")
            print(f"Response preview: {r_ajax.text[:500]}")

if __name__ == "__main__":
    login_and_fetch_lastmore()
