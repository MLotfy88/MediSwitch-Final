#!/usr/bin/env python3
"""
Upload Drug Interactions to Cloudflare D1
Uploads interaction data from JSON file to D1 database with batch processing
"""

import json
import requests
import argparse
import sys
import time
from typing import List, Dict

class CloudflareD1Uploader:
    def __init__(self, account_id: str, database_id: str, api_token: str):
        self.account_id = account_id
        self.database_id = database_id
        self.api_token = api_token
        self.base_url = f"https://api.cloudflare.com/client/v4/accounts/{account_id}/d1/database/{database_id}"
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
            if hasattr(e.response, 'text'):
                print(f"Response: {e.response.text}")
            raise
    
    def clear_interactions_table(self):
        """Clear existing interactions (TRUNCATE TABLE)"""
        print("🗑️  Clearing existing interactions...")
        result = self.execute_query("DELETE FROM drug_interactions")
        print(f"✅ Cleared table")
        return result
    
    def batch_insert_interactions(self, interactions: List[Dict], batch_size: int = 100):
        """Insert interactions in batches"""
        total = len(interactions)
        print(f"\n📦 Uploading {total:,} interactions in batches of {batch_size}...")
        
        for i in range(0, total, batch_size):
            batch = interactions[i:i + batch_size]
            
            # Build batch INSERT
            values = []
            for interaction in batch:
                values.append(f"('{interaction['ingredient1']}', '{interaction['ingredient2']}', "
                            f"'{interaction['severity']}', '{interaction['type']}', "
                            f"'{interaction['effect'].replace(\"'\", \"''\")[:1000]}', "
                            f"'{interaction.get('arabic_effect', '')}', "
                            f"'{interaction.get('recommendation', '').replace(\"'\", \"''\")[:500]}', "
                            f"'{interaction.get('arabic_recommendation', '')}', "
                            f"'{interaction.get('source', 'OpenFDA')}')")
            
            sql = f"""
                INSERT INTO drug_interactions 
                (ingredient1, ingredient2, severity, type, effect, arabic_effect, recommendation, arabic_recommendation, source)
                VALUES {','.join(values)}
            """
            
            try:
                self.execute_query(sql)
                progress = ((i + len(batch)) / total) * 100
                print(f"  Progress: {progress:.1f}% ({i + len(batch):,}/{total:,})", end='\r')
            except Exception as e:
                print(f"\n❌ Error in batch {i//batch_size + 1}: {e}")
                raise
        
        print(f"\n✅ Upload complete: {total:,} interactions")
    
    def log_sync(self, total: int, unique: int, files_processed: int, status: str, duration: int, error: str = None):
        """Log sync operation"""
        sql = f"""
            INSERT INTO interaction_sync_log 
            (sync_date, total_interactions, unique_interactions, openfda_files_processed, status, error_message, duration_seconds)
            VALUES (datetime('now'), {total}, {unique}, {files_processed}, '{status}', 
                    {'NULL' if not error else f"'{error}'"}, {duration})
        """
        self.execute_query(sql)
        print(f"✅ Logged sync: {status}")
    
    def get_stats(self):
        """Get database statistics"""
        result = self.execute_query("SELECT COUNT(*) as count FROM drug_interactions")
        count = result['result'][0]['results'][0]['count']
        print(f"\n📊 Database Stats:")
        print(f"  Total interactions: {count:,}")
        return count

def main():
    parser = argparse.ArgumentParser(description='Upload drug interactions to Cloudflare D1')
    parser.add_argument('--json-file', required=True, help='Path to interactions JSON file')
    parser.add_argument('--account-id', required=True, help='Cloudflare Account ID')
    parser.add_argument('--database-id', required=True, help='D1 Database ID')
    parser.add_argument('--api-token', required=True, help='Cloudflare API Token')
    parser.add_argument('--batch-size', type=int, default=100, help='Batch size for inserts')
    parser.add_argument('--clear-first', action='store_true', help='Clear table before upload')
    
    args = parser.parse_args()
    
    print("=" * 60)
    print("Cloudflare D1 Drug Interactions Upload")
    print("=" * 60)
    
    start_time = time.time()
    
    try:
        # Load interactions
        print(f"\n📂 Loading interactions from {args.json_file}...")
        with open(args.json_file, 'r', encoding='utf-8') as f:
            interactions = json.load(f)
        
        print(f"✅ Loaded {len(interactions):,} interactions")
        
        # Initialize uploader
        uploader = CloudflareD1Uploader(
            account_id=args.account_id,
            database_id=args.database_id,
            api_token=args.api_token
        )
        
        # Clear if requested
        if args.clear_first:
            uploader.clear_interactions_table()
        
        # Upload
        uploader.batch_insert_interactions(interactions, args.batch_size)
        
        # Verify
        final_count = uploader.get_stats()
        
        # Log success
        duration = int(time.time() - start_time)
        uploader.log_sync(
            total=len(interactions),
            unique=final_count,
            files_processed=13,
            status='success',
            duration=duration
        )
        
        print(f"\n✅ Upload completed successfully in {duration}s")
        print(f"📊 Final count: {final_count:,} interactions in D1")
        
        return 0
        
    except Exception as e:
        duration = int(time.time() - start_time)
        print(f"\n❌ Upload failed: {e}")
        
        try:
            uploader.log_sync(
                total=0,
                unique=0,
                files_processed=0,
                status='failed',
                duration=duration,
                error=str(e)
            )
        except:
            pass
        
        return 1

if __name__ == '__main__':
    sys.exit(main())
