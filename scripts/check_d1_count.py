#!/usr/bin/env python3
"""
Quick check of D1 database record count
"""

import requests
import sys

ACCOUNT_ID = "9f7fd7dfef294f26d47d62df34726367"
DATABASE_ID = "77da23cd-a8cc-40bf-9c0f-f0effe7eeaa0"

def check_d1_count(email, api_key):
    """Check record count in D1"""
    
    url = f"https://api.cloudflare.com/client/v4/accounts/{ACCOUNT_ID}/d1/database/{DATABASE_ID}/query"
    headers = {
        "X-Auth-Email": email,
        "X-Auth-Key": api_key,
        "Content-Type": "application/json"
    }
    
    # Get count
    print("🔍 Checking D1 database...")
    response = requests.post(url, headers=headers, json={"sql": "SELECT COUNT(*) as total FROM drugs"})
    
    if response.status_code == 200:
        result = response.json()
        if result.get("success") and result.get("result"):
            count = result["result"][0]["results"][0]["total"]
            print(f"✅ Total drugs in D1: {count:,}")
            
            # Get sample
            response2 = requests.post(url, headers=headers, json={"sql": "SELECT trade_name, price, last_price_update FROM drugs ORDER BY id DESC LIMIT 5"})
            if response2.status_code == 200:
                result2 = response2.json()
                if result2.get("success") and result2.get("result"):
                    print(f"\n📋 Latest 5 drugs:")
                    for row in result2["result"][0]["results"]:
                        print(f"   - {row['trade_name']}: {row['price']} EGP (updated: {row['last_price_update']})")
            
            return count
        else:
            print(f"❌ Error: {result.get('errors')}")
    else:
        print(f"❌ HTTP {response.status_code}: {response.text}")
    
    return None

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: python3 check_d1_count.py <EMAIL> <GLOBAL_API_KEY>")
        sys.exit(1)
    
    email = sys.argv[1]
    api_key = sys.argv[2]
    
    count = check_d1_count(email, api_key)
    sys.exit(0 if count else 1)
