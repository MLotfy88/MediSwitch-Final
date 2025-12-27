import requests
import urllib3
import json

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Test if we can get interaction IDs for a drug via the AJAX endpoint
def test_api(drug_id):
    url = f"https://ddinter2.scbdd.com/server/interact-with/{drug_id}/"
    headers = {
        "User-Agent": "Mozilla/5.0",
        "X-Requested-With": "XMLHttpRequest"
    }
    # Try empty POST
    try:
        response = requests.post(url, headers=headers, verify=False, timeout=10)
        print(f"Status Code: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print("API SUCCESS!")
            print(f"Data Sample: {json.dumps(data.get('data', [])[:2], indent=2)}")
            return True
        else:
            print(f"Response Body: {response.text[:200]}")
    except Exception as e:
        print(f"Error: {e}")
    return False

if __name__ == "__main__":
    test_api("DDInter1")
