#!/usr/bin/env python3
"""
Upload to D1 using Cloudflare API directly (bypassing wrangler)
Requires: CLOUDFLARE_API_TOKEN and ACCOUNT_ID
"""

import requests
import sys
import json
from pathlib import Path

# Configuration
ACCOUNT_ID = "9f7fd7dfef294f26d47d62df34726367"
DATABASE_NAME = "mediswitch-db"

def get_database_id(api_token, account_id, db_name, **kwargs):
    """Get D1 database ID by name"""
    url = f"https://api.cloudflare.com/client/v4/accounts/{account_id}/d1/database"
    headers = {}
    if api_token:
        headers = {
            "Authorization": f"Bearer {api_token}",
            "Content-Type": "application/json"
        }
    elif 'email' in kwargs and 'global_key' in kwargs:
        headers = {
            "X-Auth-Email": kwargs['email'],
            "X-Auth-Key": kwargs['global_key'],
            "Content-Type": "application/json"
        }
    else:
        print("❌ Authentication missing")
        return None
    
    response = requests.get(url, headers=headers)
    if response.status_code != 200:
        print(f"❌ Error getting databases: {response.text}")
        return None
    
    databases = response.json().get("result", [])
    for db in databases:
        if db["name"] == db_name:
            return db["uuid"]
    
    print(f"❌ Database '{db_name}' not found")
    return None

def execute_sql_batch(api_token, account_id, db_id, sql_statements, **kwargs):
    """Execute SQL statements in D1"""
    url = f"https://api.cloudflare.com/client/v4/accounts/{account_id}/d1/database/{db_id}/query"
    headers = {}
    if api_token:
        headers = {
            "Authorization": f"Bearer {api_token}",
            "Content-Type": "application/json"
        }
    elif 'email' in kwargs and 'global_key' in kwargs:
        headers = {
            "X-Auth-Email": kwargs['email'],
            "X-Auth-Key": kwargs['global_key'],
            "Content-Type": "application/json"
        }
    
    data = {
        "sql": sql_statements
    }
    
    response = requests.post(url, headers=headers, json=data)
    return response

def upload_sql_file(api_token=None, sql_file="d1_import.sql", **kwargs):
    """Upload SQL file to D1 in batches"""
    
    print(f"📖 Reading SQL file: {sql_file}")
    with open(sql_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    print(f"🔍 Getting database ID...")
    db_id = get_database_id(api_token, ACCOUNT_ID, DATABASE_NAME, **kwargs)
    if not db_id:
        return False
    
    print(f"✅ Database ID: {db_id}")
    
    # Split into batches (D1 API limit ~1MB per request)
    statements = [s.strip() for s in content.split(';') if s.strip()]
    print(f"📊 Total statements: {len(statements)}")
    
    batch_size = 50  # Execute 50 statements at a time
    total_executed = 0
    
    for i in range(0, len(statements), batch_size):
        batch = statements[i:i+batch_size]
        sql_batch = ';\n'.join(batch) + ';'
        
        print(f"⬆️  Executing batch {i//batch_size + 1}/{(len(statements)-1)//batch_size + 1}...")
        
        response = execute_sql_batch(api_token, ACCOUNT_ID, db_id, sql_batch, **kwargs)
        
        if response.status_code != 200:
            print(f"❌ Error: {response.text}")
            return False
        
        total_executed += len(batch)
        print(f"   Executed {total_executed}/{len(statements)} statements")
    
    print(f"\n✅ Upload complete!")
    print(f"   Total statements executed: {total_executed}")
    
    # Verify
    print(f"\n🔍 Verifying...")
    verify_sql = "SELECT COUNT(*) as total FROM drugs"
    response = execute_sql_batch(api_token, ACCOUNT_ID, db_id, verify_sql, **kwargs)
    
    if response.status_code == 200:
        result = response.json()
        count = result.get("result", [{}])[0].get("results", [{}])[0].get("total", 0)
        print(f"✅ Total records in D1: {count}")
    
    return True

if __name__ == '__main__':
    api_token = sys.argv[1] if len(sys.argv) > 1 and not sys.argv[1].startswith('-') else None
    
    if not api_token:
        # Check env var
        import os
        api_token = os.environ.get('CLOUDFLARE_API_TOKEN')
    
    email = os.environ.get('CLOUDFLARE_EMAIL')
    global_key = os.environ.get('CLOUDFLARE_GLOBAL_API_KEY')
    
    if not api_token and (not email or not global_key):
        print("❌ Authentication missing")
        print("Usage: ")
        print("  1. python3 upload_d1_api.py <CLOUDFLARE_API_TOKEN>")
        print("  2. set CLOUDFLARE_API_TOKEN env var")
        print("  3. set CLOUDFLARE_EMAIL and CLOUDFLARE_GLOBAL_API_KEY env vars")
        sys.exit(1)
    
    success = upload_sql_file(api_token, sql_file="d1_import.sql", email=email, global_key=global_key)
    sys.exit(0 if success else 1)
