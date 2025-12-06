
import os
import requests
import sys

API_TOKEN = 'yy-vk8KC4yth3Cn2lpva1AgrP2kGMJrQQrGIUM1-'
ACCOUNT_ID = '9f7fd7dfef294f26d47d62df34726367'
DB_ID = '77da23cd-a8cc-40bf-9c0f-f0effe7eeaa0'

headers = {
    'Authorization': f'Bearer {API_TOKEN}',
    'Content-Type': 'application/json'
}

print(f"Loading schema from schema_config.sql...")
with open('schema_config.sql', 'r') as f:
    sql_content = f.read()

# Cloudflare D1 HTTP API endpoint
url = f"https://api.cloudflare.com/client/v4/accounts/{ACCOUNT_ID}/d1/database/{DB_ID}/query"

# Split SQL by semicolon safely-ish (naïve split)
statements = [s.strip() for s in sql_content.split(';') if s.strip()]

print(f"Found {len(statements)} statements to execute.")

for i, stmt in enumerate(statements):
    print(f"Executing statement {i+1}...")
    try:
        payload = {"sql": stmt}
        response = requests.post(url, headers=headers, json=payload)
        
        if response.status_code == 200 and response.json().get('success'):
            print(f"✅ Statement {i+1} executed successfully.")
        else:
            print(f"❌ Error in statement {i+1}: {response.text}")
    except Exception as e:
        print(f"❌ Exception: {e}")

print("Done.")
