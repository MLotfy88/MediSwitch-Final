#!/usr/bin/env python3
"""
Upload to D1 using Cloudflare API with Global API Key
Usage: python3 upload_d1_global_key.py <EMAIL> <GLOBAL_API_KEY>
"""

import requests
import sys

# Configuration
ACCOUNT_ID = "9f7fd7dfef294f26d47d62df34726367"
DATABASE_NAME = "mediswitch-db"

def get_database_id(email, api_key, account_id, db_name):
    """Get D1 database ID by name"""
    url = f"https://api.cloudflare.com/client/v4/accounts/{account_id}/d1/database"
    headers = {
        "X-Auth-Email": email,
        "X-Auth-Key": api_key,
        "Content-Type": "application/json"
    }
    
    print(f"🔍 Getting database list...")
    response = requests.get(url, headers=headers)
    
    if response.status_code != 200:
        print(f"❌ Error: {response.text}")
        return None
    
    result = response.json()
    if not result.get("success"):
        print(f"❌ API Error: {result.get('errors')}")
        return None
    
    databases = result.get("result", [])
    print(f"✅ Found {len(databases)} databases")
    
    for db in databases:
        print(f"   - {db['name']} ({db['uuid']})")
        if db["name"] == db_name:
            return db["uuid"]
    
    print(f"❌ Database '{db_name}' not found")
    return None

def execute_sql(email, api_key, account_id, db_id, sql):
    """Execute SQL in D1"""
    url = f"https://api.cloudflare.com/client/v4/accounts/{account_id}/d1/database/{db_id}/query"
    headers = {
        "X-Auth-Email": email,
        "X-Auth-Key": api_key,
        "Content-Type": "application/json"
    }
    
    data = {"sql": sql}
    response = requests.post(url, headers=headers, json=data)
    return response

def upload_sql_file(email, api_key, sql_file="d1_import.sql"):
    """Upload SQL file to D1 in batches"""
    
    print(f"📖 Reading SQL file: {sql_file}")
    with open(sql_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    db_id = get_database_id(email, api_key, ACCOUNT_ID, DATABASE_NAME)
    if not db_id:
        return False
    
    print(f"\n✅ Database ID: {db_id}")
    
    # Split into batches
    statements = [s.strip() for s in content.split(';') if s.strip() and not s.strip().startswith('--')]
    print(f"📊 Total statements: {len(statements)}\n")
    
    batch_size = 20  # Smaller batches for reliability
    total_executed = 0
    errors = 0
    
    for i in range(0, len(statements), batch_size):
        batch = statements[i:i+batch_size]
        sql_batch = ';\n'.join(batch) + ';'
        
        batch_num = i//batch_size + 1
        total_batches = (len(statements)-1)//batch_size + 1
        
        print(f"⬆️  Batch {batch_num}/{total_batches} ({len(batch)} statements)...", end=" ")
        
        response = execute_sql(email, api_key, ACCOUNT_ID, db_id, sql_batch)
        
        if response.status_code == 200:
            result = response.json()
            if result.get("success"):
                print("✅")
                total_executed += len(batch)
            else:
                print(f"❌ {result.get('errors')}")
                errors += 1
        else:
            print(f"❌ HTTP {response.status_code}")
            errors += 1
            if errors > 5:
                print("\n❌ Too many errors, stopping...")
                return False
    
    print(f"\n✅ Upload complete!")
    print(f"   Executed: {total_executed}/{len(statements)} statements")
    print(f"   Errors: {errors}")
    
    # Verify
    print(f"\n🔍 Verifying...")
    response = execute_sql(email, api_key, ACCOUNT_ID, db_id, "SELECT COUNT(*) as total FROM drugs")
    
    if response.status_code == 200:
        result = response.json()
        if result.get("success") and result.get("result"):
            count = result["result"][0]["results"][0]["total"]
            print(f"✅ Total records in D1: {count}")
    
    return errors == 0

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: python3 upload_d1_global_key.py <EMAIL> <GLOBAL_API_KEY>")
        print("Example: python3 upload_d1_global_key.py user@example.com abc123...")
        sys.exit(1)
    
    email = sys.argv[1]
    api_key = sys.argv[2]
    
    print(f"📧 Email: {email}")
    print(f"🔑 API Key: {'*' * (len(api_key)-4) + api_key[-4:]}\n")
    
    success = upload_sql_file(email, api_key)
    sys.exit(0 if success else 1)
