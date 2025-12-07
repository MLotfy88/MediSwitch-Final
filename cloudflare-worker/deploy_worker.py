#!/usr/bin/env python3
"""
Deploy Cloudflare Worker via API
Direct deployment without wrangler CLI
"""

import requests
import os
import sys
import base64

# Cloudflare configuration
ACCOUNT_ID = "9f7fd7dfef294f26d47d62df34726367"
WORKER_NAME = "mediswitch-api"

# Get credentials from environment or use provided values
API_TOKEN = os.environ.get('CLOUDFLARE_API_TOKEN')
EMAIL = os.environ.get('CLOUDFLARE_EMAIL')
GLOBAL_KEY = os.environ.get('CLOUDFLARE_GLOBAL_API_KEY')

# Setup headers
headers = {}
if API_TOKEN:
    print("🔑 Using API Token")
    headers = {
        "Authorization": f"Bearer {API_TOKEN}",
        "Content-Type": "application/javascript"
    }
elif EMAIL and GLOBAL_KEY:
    print(f"🔑 Using Global API Key for {EMAIL}")
    headers = {
        "X-Auth-Email": EMAIL,
        "X-Auth-Key": GLOBAL_KEY,
        "X-Auth-Key": GLOBAL_KEY
    }
else:
    print("❌ Error: No authentication credentials!")
    print("\nSet environment variables:")
    print("  export CLOUDFLARE_API_TOKEN=your_token")
    print("OR")
    print("  export CLOUDFLARE_EMAIL=your@email.com")
    print("  export CLOUDFLARE_GLOBAL_API_KEY=your_key")
    sys.exit(1)

# Read worker code
print("\n📦 Reading worker code...")

# Read main worker file
with open('src/index.js', 'r') as f:
    main_code = f.read()

# Read utils
with open('src/utils.js', 'r') as f:
    utils_code = f.read()

# Combine code (simple bundling)
worker_script = f"""
{utils_code}

{main_code}
"""

print(f"✅ Worker code loaded ({len(worker_script)} bytes)")

# Deploy worker using Multipart (required for Modules)
print(f"\n🚀 Deploying worker '{WORKER_NAME}' (Module Format)...")
url = f"https://api.cloudflare.com/client/v4/accounts/{ACCOUNT_ID}/workers/scripts/{WORKER_NAME}"

import json

metadata = {
    "main_module": "worker.js",
    "compatibility_date": "2024-01-01",
    "bindings": [
        {
            "type": "d1",
            "name": "DB",
            "id": "77da23cd-a8cc-40bf-9c0f-f0effe7eeaa0"
        }
    ]
}

# We call the concatenated file 'worker.js'
files = {
    'metadata': (None, json.dumps(metadata), 'application/json'),
    'worker.js': ('worker.js', worker_script, 'application/javascript+module')
}

try:
    response = requests.put(url, headers={"Authorization": f"Bearer {API_TOKEN}"} if API_TOKEN else headers, files=files)
    # Note: requests takes care of Content-Type multipart/form-data boundary
    
    # Check response
    try:
        result = response.json()
    except:
        print(f"❌ Failed to parse JSON response: {response.text}")
        sys.exit(1)
        
    if response.status_code == 200 and result.get('success'):
        print("✅ Worker deployed successfully!")
        print(f"\n🌐 Worker URL: https://{WORKER_NAME}.admin-lotfy.workers.dev")
        
        pass # Binding included in deployment
            
    else:
        print(f"❌ Deployment failed: {result.get('errors')}")
        if 'messages' in result:
             print(f"Messages: {result.get('messages')}")
        sys.exit(1)
        
except Exception as e:
    print(f"❌ Error: {e}")
    sys.exit(1)

print("\n" + "="*60)
print("✅ Deployment complete!")
print("="*60)
