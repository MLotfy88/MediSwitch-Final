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
parser.add_argument('--api-token', help='Cloudflare API Token')
parser.add_argument('--email', help='Cloudflare Email (for Global Key)')
parser.add_argument('--global-key', help='Cloudflare Global API Key')
parser.add_argument('--file', help='SQL Schema file to apply', default='cloudflare-worker/schema_interactions.sql')
args = parser.parse_args()

# Try Token First
API_TOKEN = args.api_token or os.environ.get('CLOUDFLARE_API_TOKEN')

# Try Global Key Second
EMAIL = args.email or os.environ.get('CLOUDFLARE_EMAIL')
GLOBAL_KEY = args.global_key or os.environ.get('CLOUDFLARE_GLOBAL_API_KEY')

headers = {}

if API_TOKEN:
    print("🔑 Using API Token")
    headers = {
        "Authorization": f"Bearer {API_TOKEN}",
        "Content-Type": "application/json"
    }
elif EMAIL and GLOBAL_KEY:
    print(f"🔑 Using Global API Key for {EMAIL}")
    headers = {
        "X-Auth-Email": EMAIL,
        "X-Auth-Key": GLOBAL_KEY,
        "Content-Type": "application/json"
    }
else:
    print("❌ Error: No authentication credentials found!")
    print("\nOption 1: API Token (Preferred)")
    print("  export CLOUDFLARE_API_TOKEN=your_token")
    print("\nOption 2: Global API Key (Fallback)")
    print("  export CLOUDFLARE_EMAIL=your@email.com")
    print("  export CLOUDFLARE_GLOBAL_API_KEY=your_key")
    sys.exit(1)

BASE_URL = f"https://api.cloudflare.com/client/v4/accounts/{ACCOUNT_ID}/d1/database/{DATABASE_ID}/query"

# Read schema
schema_file = args.file
print(f"Reading schema from {schema_file}...")
with open(schema_file, 'r') as f:
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
