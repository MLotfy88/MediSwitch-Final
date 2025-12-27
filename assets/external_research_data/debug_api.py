import requests
import json
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

drug_id = "DDInter20"
headers = {
    "User-Agent": "Mozilla/5.0",
    "X-Requested-With": "XMLHttpRequest"
}

endpoints = [
    f"https://ddinter2.scbdd.com/server/interact-with/{drug_id}/",
    f"https://ddinter2.scbdd.com/server/interact-with-food/{drug_id}/",
    f"https://ddinter2.scbdd.com/server/interact-with-disease/{drug_id}/",
    f"https://ddinter2.scbdd.com/server/linkmarker/{drug_id}/"
]

results = {}

for url in endpoints:
    print(f"Testing {url}...")
    results[url] = {}
    
    # Try GET
    try:
        r_get = requests.get(url, headers=headers, verify=False, timeout=10)
        results[url]["GET_status"] = r_get.status_code
        if r_get.status_code == 200:
            try: results[url]["GET_json_sample"] = r_get.json().get("data", r_get.json())[:2]
            except: results[url]["GET_text_sample"] = r_get.text[:100]
    except Exception as e:
        results[url]["GET_error"] = str(e)
        
    # Try POST
    try:
        r_post = requests.post(url, headers=headers, verify=False, timeout=10)
        results[url]["POST_status"] = r_post.status_code
        if r_post.status_code == 200:
            try: results[url]["POST_json_sample"] = r_post.json().get("data", r_post.json())[:2]
            except: results[url]["POST_text_sample"] = r_post.text[:100]
    except Exception as e:
        results[url]["POST_error"] = str(e)

print(json.dumps(results, indent=2))
