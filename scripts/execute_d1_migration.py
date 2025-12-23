import os
import sys
import requests
import json

# Credentials (from codebase)
ACCOUNT_ID = "9f7fd7dfef294f26d47d62df34726367"
DATABASE_ID = "77da23cd-a8cc-40bf-9c0f-f0effe7eeaa0"
API_TOKEN = "yy-vk8KC4yth3Cn2lpva1AgrP2kGMJrQQrGIUM1-"

def execute_sql(sql_file):
    if not API_TOKEN:
        print("❌ CLOUDFLARE_API_TOKEN is not set.")
        sys.exit(1)

    print(f"🚀 Executing migration from {sql_file}...")
    
    with open(sql_file, 'r') as f:
        sql_content = f.read()

    # Cloudflare D1 API for batch execution
    # We split by semicolon but be careful with strings. 
    # Better to send the whole thing if the API supports it, or use the query endpoint per statement.
    # The 'query' endpoint supports multiple statements in one call.
    
    url = f"https://api.cloudflare.com/client/v4/accounts/{ACCOUNT_ID}/d1/database/{DATABASE_ID}/query"
    headers = {
        "Authorization": f"Bearer {API_TOKEN}",
        "Content-Type": "application/json"
    }
    
    payload = {
        "sql": sql_content
    }
    
    try:
        response = requests.post(url, headers=headers, json=payload)
        response.raise_for_status()
        result = response.json()
        
        if result.get("success"):
            print("✅ Migration successful!")
            # print(json.dumps(result["result"], indent=2))
        else:
            print("❌ Migration failed:")
            print(json.dumps(result.get("errors", []), indent=2))
            sys.exit(1)
            
    except Exception as e:
        print(f"❌ Error during API call: {e}")
        if hasattr(e, 'response') and e.response is not None:
            print(e.response.text)
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 execute_d1_migration.py <sql_file>")
        sys.exit(1)
    
    execute_sql(sys.argv[1])
