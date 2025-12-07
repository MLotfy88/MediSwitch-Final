import requests
import json

try:
    url = "https://mediswitch-api.m-m-lotfy-88.workers.dev/api/interactions?limit=1"
    response = requests.get(url, timeout=10)
    if response.status_code == 200:
        data = response.json()
        print("KEYS:", json.dumps(data, indent=2))
    else:
        print(f"Error: {response.status_code} - {response.text}")
except Exception as e:
    print(f"Exception: {e}")
