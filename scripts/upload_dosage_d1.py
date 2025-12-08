#!/usr/bin/env python3
"""
Upload Dosage Guidelines to Cloudflare D1
Uploads dosage data from JSON file to D1 database with batch processing
"""

import json
import requests
import argparse
import sys
import time
from typing import List, Dict

class CloudflareD1Uploader:
    def __init__(self, account_id: str, database_id: str, api_token: str = None):
        self.account_id = account_id
        self.database_id = database_id
        self.base_url = f"https://api.cloudflare.com/client/v4/accounts/{account_id}/d1/database/{database_id}"
        
        if not api_token:
            raise ValueError("API token is required")
        
        self.headers = {
            "Authorization": f"Bearer {api_token}",
            "Content-Type": "application/json"
        }
    
    def execute_query(self, sql: str, params: List = None) -> Dict:
        """Execute SQL query on D1 database"""
        url = f"{self.base_url}/query"
        
        payload = {"sql": sql}
        if params:
            payload["params"] = params
        
        try:
            response = requests.post(url, headers=self.headers, json=payload)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"❌ API Error: {e}")
            if hasattr(e, 'response') and hasattr(e.response, 'text'):
                print(f"Response: {e.response.text}")
            raise
    
    def initialize_table(self):
        """Create dosage_guidelines table if it doesn't exist"""
        print("🛠️  Checking/Creating dosage_guidelines table...")
        
        sql = """
        CREATE TABLE IF NOT EXISTS dosage_guidelines (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            active_ingredient TEXT NOT NULL,
            strength TEXT NOT NULL,
            standard_dose TEXT,
            max_dose TEXT,
            package_label TEXT,
            source TEXT DEFAULT 'OpenFDA',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(active_ingredient, strength)
        );
        """
        
        self.execute_query(sql)
        print("✅ Table ready")
    
    def create_indexes(self):
        """Create indexes for better query performance"""
        print("🔍 Creating indexes...")
        
        indexes = [
            "CREATE INDEX IF NOT EXISTS idx_active_ingredient ON dosage_guidelines(active_ingredient);",
            "CREATE INDEX IF NOT EXISTS idx_strength ON dosage_guidelines(strength);",
        ]
        
        for idx_sql in indexes:
            try:
                self.execute_query(idx_sql)
            except Exception as e:
                print(f"⚠️  Index creation warning: {e}")
        
        print("✅ Indexes created")
    
    def clear_existing_data(self):
        """Clear all existing data from dosage_guidelines table"""
        print("🗑️  Clearing existing data...")
        self.execute_query("DELETE FROM dosage_guidelines;")
        print("✅ Existing data cleared")
    
    def upload_batch(self, guidelines: List[Dict], start_idx: int) -> int:
        """Upload a batch of guidelines"""
        # Build INSERT statement with multiple values
        values_placeholders = []
        params = []
        
        for g in guidelines:
            values_placeholders.append("(?, ?, ?, ?, ?, ?)")
            params.extend([
                g['active_ingredient'],
                g['strength'],
                g.get('standard_dose'),
                g.get('max_dose'),
                g.get('package_label'),
                'OpenFDA'
            ])
        
        sql = f"""
        INSERT OR REPLACE INTO dosage_guidelines 
        (active_ingredient, strength, standard_dose, max_dose, package_label, source) 
        VALUES {', '.join(values_placeholders)};
        """
        
        self.execute_query(sql, params)
        return len(guidelines)
    
    def upload_guidelines(self, json_file: str, batch_size: int = 100):
        """Upload all dosage guidelines from JSON file"""
        # Load data
        print(f"📂 Loading data from {json_file}...")
        with open(json_file, 'r', encoding='utf-8') as f:
            guidelines = json.load(f)
        
        total = len(guidelines)
        print(f"📊 Found {total:,} dosage guidelines to upload")
        
        # Initialize table
        self.initialize_table()
        self.clear_existing_data()
        
        # Upload in batches
        print(f"\n📤 Uploading in batches of {batch_size}...")
        uploaded = 0
        failed = 0
        
        for i in range(0, total, batch_size):
            batch = guidelines[i:i + batch_size]
            try:
                count = self.upload_batch(batch, i)
                uploaded += count
                print(f"  ✓ Batch {i//batch_size + 1}: Uploaded {count} guidelines " +
                      f"({uploaded:,}/{total:,} = {uploaded/total*100:.1f}%)")
                
                # Rate limiting
                if i + batch_size < total:
                    time.sleep(0.5)  # 500ms between batches
            
            except Exception as e:
                failed += len(batch)
                print(f"  ✗ Batch {i//batch_size + 1} failed: {e}")
        
        # Create indexes after upload
        self.create_indexes()
        
        # Summary
        print(f"\n{'='*80}")
        print(f"📊 Upload Summary")
        print(f"{'='*80}")
        print(f"  • Total guidelines: {total:,}")
        print(f"  • Successfully uploaded: {uploaded:,}")
        print(f"  • Failed: {failed:,}")
        print(f"  • Success rate: {uploaded/total*100 if total > 0 else 0:.1f}%")
        
        if failed > 0:
            print(f"\n⚠️  {failed} guidelines failed to upload")
            return False
        else:
            print(f"\n✅ All guidelines uploaded successfully!")
            return True

def main():
    parser = argparse.ArgumentParser(description='Upload dosage guidelines to Cloudflare D1')
    parser.add_argument('--json-file', required=True, help='Path to dosage guidelines JSON file')
    parser.add_argument('--database-id', required=True, help='Cloudflare D1 Database ID')
    parser.add_argument('--account-id', required=True, help='Cloudflare Account ID')
    parser.add_argument('--api-token', required=True, help='Cloudflare API Token')
    parser.add_argument('--batch-size', type=int, default=15, help='Batch size for uploads')
    
    args = parser.parse_args()
    
    print("="*80)
    print("Cloudflare D1 Dosage Guidelines Uploader")
    print("="*80)
    print(f"Database ID: {args.database_id}")
    print(f"Account ID: {args.account_id}")
    print()
    
    try:
        uploader = CloudflareD1Uploader(
            account_id=args.account_id,
            database_id=args.database_id,
            api_token=args.api_token
        )
        
        success = uploader.upload_guidelines(
            json_file=args.json_file,
            batch_size=args.batch_size
        )
        
        sys.exit(0 if success else 1)
    
    except Exception as e:
        print(f"\n❌ Upload failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
