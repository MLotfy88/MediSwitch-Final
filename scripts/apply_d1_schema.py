#!/usr/bin/env python3
"""
Apply D1 Schema via Cloudflare API
Alternative to wrangler CLI
"""

import requests
import sys
import os
import argparse

# Cloudflare configuration (from wrangler.toml)
ACCOUNT_ID = "9f7fd7dfef294f26d47d62df34726367"
DATABASE_ID = "77da23cd-a8cc-40bf-9c0f-f0effe7eeaa0"

# Get API token from environment or argument
parser = argparse.ArgumentParser(description='Apply D1 schema')
parser.add_argument('--api-token', help='Cloudflare API Token')
args = parser.parse_args()

API_TOKEN = args.api_token or os.environ.get('CLOUDFLARE_API_TOKEN')

if not API_TOKEN:
    print("❌ Error: CLOUDFLARE_API_TOKEN not found!")
    print("Set it via:")
    print("  export CLOUDFLARE_API_TOKEN=your_token")
    print("  or")
    print("  python3 scripts/apply_d1_schema.py --api-token YOUR_TOKEN")
    sys.exit(1)

BASE_URL = f"https://api.cloudflare.com/client/v4/accounts/{ACCOUNT_ID}/d1/database/{DATABASE_ID}/query"

headers = {
    "Authorization": f"Bearer {API_TOKEN}",
    "Content-Type": "application/json"
}

# Read schema
with open('cloudflare-worker/schema_interactions.sql', 'r') as f:
    schema = f.read()

# Split into individual statements
statements = [s.strip() + ';' for s in schema.split(';') if s.strip() and not s.strip().startswith('--')]

print("=" * 60)
print("Applying D1 Schema for Drug Interactions")
print("=" * 60)
print(f"\nFound {len(statements)} SQL statements\n")

success_count = 0
for i, sql in enumerate(statements, 1):
    # Skip comments
    if sql.strip().startswith('--') or len(sql.strip()) < 5:
        continue
    
    print(f"[{i}/{len(statements)}] Executing... ", end='')
    
    payload = {"sql": sql}
    
    try:
        response = requests.post(BASE_URL, headers=headers, json=payload)
        response.raise_for_status()
        result = response.json()
        
        if result.get('success'):
            print("✅")
            success_count += 1
        else:
            print(f"⚠️  {result.get('errors', 'Unknown error')}")
    except Exception as e:
        print(f"❌ {e}")

print(f"\n✅ Applied {success_count}/{len(statements)} statements successfully")
print("\n" + "=" * 60)
print("Schema application complete!")
print("=" * 60)
