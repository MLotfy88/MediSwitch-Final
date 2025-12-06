import requests
import os
import sys

# Configuration
ACCOUNT_ID = "9f7fd7dfef294f26d47d62df34726367"
DATABASE_ID = "77da23cd-a8cc-40bf-9c0f-f0effe7eeaa0"
API_TOKEN = os.environ.get('CLOUDFLARE_API_TOKEN') or 'yy-vk8KC4yth3Cn2lpva1AgrP2kGMJrQQrGIUM1-'

def apply_schema(filename):
    print(f"Applying schema from {filename}...")
    with open(filename, 'r') as f:
        sql = f.read()

    url = f"https://api.cloudflare.com/client/v4/accounts/{ACCOUNT_ID}/d1/database/{DATABASE_ID}/query"
    headers = {
        "Authorization": f"Bearer {API_TOKEN}",
        "Content-Type": "application/json"
    }
    
    # Split by semicolon to execute multiple statements (if API supports it, or one by one)
    # Cloudflare D1 API supports multiple statements in one query usually
    payload = {"sql": sql}
    
    response = requests.post(url, headers=headers, json=payload)
    if response.status_code == 200:
        result = response.json()
        if result.get('success'):
            print("✅ Schema applied successfully!")
        else:
            print(f"❌ Failed: {result.get('errors')}")
    else:
        print(f"❌ HTTP Error: {response.text}")

if __name__ == "__main__":
    apply_schema('schema_analytics.sql')
