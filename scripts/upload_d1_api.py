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

def get_database_id(api_token, account_id, db_name):
    """Get D1 database ID by name"""
    url = f"https://api.cloudflare.com/client/v4/accounts/{account_id}/d1/database"
    headers = {
        "Authorization": f"Bearer {api_token}",
        "Content-Type": "application/json"
    }
    
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

def execute_sql_batch(api_token, account_id, db_id, sql_statements):
    """Execute SQL statements in D1"""
    url = f"https://api.cloudflare.com/client/v4/accounts/{account_id}/d1/database/{db_id}/query"
    headers = {
        "Authorization": f"Bearer {api_token}",
        "Content-Type": "application/json"
    }
    
    data = {
        "sql": sql_statements
    }
    
    response = requests.post(url, headers=headers, json=data)
    return response

def upload_sql_file(api_token, sql_file="d1_import.sql"):
    """Upload SQL file to D1 in batches"""
    
    print(f"📖 Reading SQL file: {sql_file}")
    with open(sql_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    print(f"🔍 Getting database ID...")
    db_id = get_database_id(api_token, ACCOUNT_ID, DATABASE_NAME)
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
        
        response = execute_sql_batch(api_token, ACCOUNT_ID, db_id, sql_batch)
        
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
    response = execute_sql_batch(api_token, ACCOUNT_ID, db_id, verify_sql)
    
    if response.status_code == 200:
        result = response.json()
        count = result.get("result", [{}])[0].get("results", [{}])[0].get("total", 0)
        print(f"✅ Total records in D1: {count}")
    
    return True

if __name__ == '__main__':
    api_token = sys.argv[1] if len(sys.argv) > 1 else None
    
    if not api_token:
        print("Usage: python3 upload_d1_api.py <CLOUDFLARE_API_TOKEN>")
        print("Or set CLOUDFLARE_API_TOKEN environment variable")
        import os
        api_token = os.environ.get('CLOUDFLARE_API_TOKEN')
    
    if not api_token:
        print("❌ No API token provided")
        sys.exit(1)
    
    success = upload_sql_file(api_token)
    sys.exit(0 if success else 1)
