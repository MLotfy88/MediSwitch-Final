import requests
import json
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

session = requests.Session()
headers = {
    "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "X-Requested-With": "XMLHttpRequest",
    "Accept": "application/json, text/javascript, */*; q=0.01",
    "Referer": "https://ddinter2.scbdd.com/server/drug-detail/DDInter20/"
}

url = "https://ddinter2.scbdd.com/server/interact-with/DDInter20/"

print(f"Testing POST to {url} with Session...")
try:
    # First, visit the drug page to get any cookies
    session.get("https://ddinter2.scbdd.com/server/drug-detail/DDInter20/", headers=headers, verify=False, timeout=10)
    
    # Then POST to AJAX
    # Datatables often sends some data like 'draw', 'start', 'length'
    payload = {
        "draw": "1",
        "start": "0",
        "length": "10",
        "search[value]": "",
        "search[regex]": "false"
    }
    
    res = session.post(url, headers=headers, data=payload, verify=False, timeout=15)
    print(f"Status: {res.status_code}")
    if res.status_code == 200:
        data = res.json()
        print(f"Found {len(data.get('data', []))} interactions.")
        print("Sample:", json.dumps(data.get('data', [])[:1], indent=2))
    else:
        print("Response:", res.text[:200])
except Exception as e:
    print(f"Error: {e}")
