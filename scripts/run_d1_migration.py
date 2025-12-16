#!/usr/bin/env python3
"""
Execute D1 Schema Migration via API
Runs ALTER TABLE statements directly on Cloudflare D1
"""

import requests
import json
import time

# Credentials
ACCOUNT_ID = "9f7fd7dfef294f26d47d62df34726367"
DATABASE_ID = "77da23cd-a8cc-40bf-9c0f-f0effe7eeaa0"
API_TOKEN = "yy-vk8KC4yth3Cn2lpva1AgrP2kGMJrQQrGIUM1-"

BASE_URL = f"https://api.cloudflare.com/client/v4/accounts/{ACCOUNT_ID}/d1/database/{DATABASE_ID}/query"

headers = {
    "Authorization": f"Bearer {API_TOKEN}",
    "Content-Type": "application/json"
}

def execute_sql(sql, description=""):
    """Execute SQL statement on D1"""
    print(f"\n🔧 {description}")
    print(f"   SQL: {sql[:80]}...")
    
    payload = {"sql": sql}
    
    try:
        response = requests.post(BASE_URL, headers=headers, json=payload, timeout=30)
        response.raise_for_status()
        result = response.json()
        
        if result.get('success'):
            print(f"   ✅ Success")
            return True
        else:
            errors = result.get('errors', [])
            # Check if error is "duplicate column name" which means it already exists
            error_msgs = [e.get('message', '') for e in errors]
            if any('duplicate column' in msg.lower() for msg in error_msgs):
                print(f"   ⚠️  Column already exists (skipping)")
                return True
            else:
                print(f"   ❌ Failed: {errors}")
                return False
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return False

# Migration statements
migrations = [
    # drugs table
    ("ALTER TABLE drugs ADD COLUMN pharmacology TEXT;", "Adding pharmacology to drugs"),
    ("ALTER TABLE drugs ADD COLUMN barcode TEXT;", "Adding barcode to drugs"),
    
    # med_dosages table
    ("ALTER TABLE med_dosages ADD COLUMN dailymed_setid TEXT;", "Adding dailymed_setid to med_dosages"),
    ("ALTER TABLE med_dosages ADD COLUMN dailymed_product_name TEXT;", "Adding dailymed_product_name to med_dosages"),
    ("ALTER TABLE med_dosages ADD COLUMN matching_confidence REAL DEFAULT 0.0;", "Adding matching_confidence to med_dosages"),
    ("CREATE INDEX IF NOT EXISTS idx_med_dosages_dailymed ON med_dosages(dailymed_setid);", "Creating index on dailymed_setid"),
    
    # drug_interactions table
    ("ALTER TABLE drug_interactions ADD COLUMN egyptian_drug_id1 TEXT;", "Adding egyptian_drug_id1 to interactions"),
    ("ALTER TABLE drug_interactions ADD COLUMN egyptian_drug_id2 TEXT;", "Adding egyptian_drug_id2 to interactions"),
    ("ALTER TABLE drug_interactions ADD COLUMN dailymed_setid1 TEXT;", "Adding dailymed_setid1 to interactions"),
    ("ALTER TABLE drug_interactions ADD COLUMN dailymed_setid2 TEXT;", "Adding dailymed_setid2 to interactions"),
    ("ALTER TABLE drug_interactions ADD COLUMN mechanism TEXT;", "Adding mechanism to interactions"),
    ("ALTER TABLE drug_interactions ADD COLUMN clinical_significance TEXT;", "Adding clinical_significance to interactions"),
    ("ALTER TABLE drug_interactions ADD COLUMN confidence_score REAL DEFAULT 50.0;", "Adding confidence_score to interactions"),
    ("ALTER TABLE drug_interactions ADD COLUMN last_verified TIMESTAMP;", "Adding last_verified to interactions"),
    
    # Indexes for interactions
    ("CREATE INDEX IF NOT EXISTS idx_interactions_eg_drug1 ON drug_interactions(egyptian_drug_id1);", "Creating index on eg_drug1"),
    ("CREATE INDEX IF NOT EXISTS idx_interactions_eg_drug2 ON drug_interactions(egyptian_drug_id2);", "Creating index on eg_drug2"),
    ("CREATE INDEX IF NOT EXISTS idx_interactions_dm_setid1 ON drug_interactions(dailymed_setid1);", "Creating index on dm_setid1"),
    ("CREATE INDEX IF NOT EXISTS idx_interactions_dm_setid2 ON drug_interactions(dailymed_setid2);", "Creating index on dm_setid2"),
]

print("="*70)
print("D1 Schema Migration - Direct Execution")
print("="*70)

success_count = 0
fail_count = 0

for sql, desc in migrations:
    if execute_sql(sql, desc):
        success_count += 1
    else:
        fail_count += 1
    time.sleep(0.5)  # Rate limiting

print("\n" + "="*70)
print(f"✅ Migration Complete: {success_count} succeeded, {fail_count} failed")
print("="*70)

# Verify
print("\n🔍 Verifying schema changes...")
for table in ['drugs', 'med_dosages', 'drug_interactions']:
    execute_sql(f"PRAGMA table_info({table});", f"Checking {table} schema")
