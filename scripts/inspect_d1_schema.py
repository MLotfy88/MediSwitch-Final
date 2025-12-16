#!/usr/bin/env python3
"""
Query Cloudflare D1 Database Schema
Fetches current table structures from live D1 database
"""

import requests
import json
import sys

# Credentials
ACCOUNT_ID = "9f7fd7dfef294f26d47d62df34726367"
DATABASE_ID = "77da23cd-a8cc-40bf-9c0f-f0effe7eeaa0"
API_TOKEN = "yy-vk8KC4yth3Cn2lpva1AgrP2kGMJrQQrGIUM1-"

BASE_URL = f"https://api.cloudflare.com/client/v4/accounts/{ACCOUNT_ID}/d1/database/{DATABASE_ID}/query"

headers = {
    "Authorization": f"Bearer {API_TOKEN}",
    "Content-Type": "application/json"
}

def query_d1(sql):
    """Execute SQL query on D1"""
    payload = {"sql": sql}
    try:
        response = requests.post(BASE_URL, headers=headers, json=payload)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        print(f"❌ Error: {e}")
        if hasattr(e, 'response') and hasattr(e.response, 'text'):
            print(f"Response: {e.response.text}")
        return None

def get_table_info(table_name):
    """Get column information for a table"""
    print(f"\n{'='*60}")
    print(f"📊 Table: {table_name}")
    print('='*60)
    
    result = query_d1(f"PRAGMA table_info({table_name});")
    
    if not result or not result.get('success'):
        print(f"❌ Failed to fetch {table_name}")
        print(json.dumps(result, indent=2))
        return None
    
    # Extract columns from result
    columns = result.get('result', [{}])[0].get('results', [])
    
    if not columns:
        print(f"⚠️  Table {table_name} not found or has no columns")
        return None
    
    print(f"\nColumns ({len(columns)}):")
    print(f"{'Index':<6} {'Name':<25} {'Type':<15} {'NotNull':<8} {'Default':<15} {'PK'}")
    print('-' * 90)
    
    for col in columns:
        print(f"{col['cid']:<6} {col['name']:<25} {col['type']:<15} {col['notnull']:<8} {str(col['dflt_value']):<15} {col['pk']}")
    
    return columns

def get_full_schema(table_name):
    """Get CREATE TABLE statement"""
    result = query_d1(f"SELECT sql FROM sqlite_master WHERE type='table' AND name='{table_name}';")
    
    if result and result.get('success'):
        try:
            sql = result['result'][0]['results'][0]['sql']
            print(f"\n📝 CREATE TABLE Statement:")
            print(sql)
            return sql
        except:
            pass
    return None

# Main execution
if __name__ == "__main__":
    print("🔍 Inspecting D1 Database Schema...")
    print(f"Database ID: {DATABASE_ID}\n")
    
    tables = ['drugs', 'med_dosages', 'drug_interactions']
    
    for table in tables:
        columns = get_table_info(table)
        if columns:
            get_full_schema(table)
    
    print(f"\n{'='*60}")
    print("✅ Schema inspection complete")
    print('='*60)
