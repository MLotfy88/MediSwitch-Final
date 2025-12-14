#!/usr/bin/env python3
"""
Sync Daily Updates to Cloudflare D1
Uplods incremental changes to 'med_dosages' and 'drug_interactions' tables.
"""

import sys
import json
import requests
import argparse
import time

class CloudflareD1Uploader:
    def __init__(self, account_id, database_id, api_token=None, email=None, global_key=None):
        self.base_url = f"https://api.cloudflare.com/client/v4/accounts/{account_id}/d1/database/{database_id}/query"
        if email and global_key:
            self.headers = {"X-Auth-Email": email, "X-Auth-Key": global_key, "Content-Type": "application/json"}
        elif api_token:
            self.headers = {"Authorization": f"Bearer {api_token}", "Content-Type": "application/json"}
        else:
            raise ValueError("Auth credentials missing")

    def query(self, sql, params=None):
        payload = {"sql": sql}
        if params: payload["params"] = params
        resp = requests.post(self.base_url, headers=self.headers, json=payload)
        resp.raise_for_status()
        return resp.json()

    def init_tables(self):
        # 1. Med Dosages (Keyed by med_id)
        sql_dosages = """
        CREATE TABLE IF NOT EXISTS med_dosages (
            med_id TEXT PRIMARY KEY,
            trade_name TEXT,
            active_ingredient TEXT,
            adult_dose_mg REAL,
            pediatric_dose_mg_kg REAL,
            dosage_text TEXT,
            json_data TEXT, 
            last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        """
        self.query(sql_dosages)
        
        # 2. Drug Interactions (Keyed by pair) - Ensuring it exists
        sql_interactions = """
        CREATE TABLE IF NOT EXISTS drug_interactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ingredient1 TEXT NOT NULL,
            ingredient2 TEXT NOT NULL,
            severity TEXT NOT NULL,
            effect TEXT,
            recommendation TEXT,
            source TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(ingredient1, ingredient2)
        );
        """
        self.query(sql_interactions)
        
        # Indexes
        self.query("CREATE INDEX IF NOT EXISTS idx_int_ing1 ON drug_interactions(ingredient1);")
        print("✅ Tables Initialized.")

    def sync_dosages(self, file_path):
        print(f"💊 Syncing Dosages from {file_path}")
        with open(file_path, 'r') as f:
            records = [json.loads(line) for line in f if line.strip()]

        if not records:
             print("  No records to sync.")
             return

        batch_size = 20
        for i in range(0, len(records), batch_size):
            batch = records[i:i+batch_size]
            placeholders = []
            params = []
            for r in batch:
                placeholders.append("(?, ?, ?, ?, ?, ?, ?)")
                # Extract simplified cols
                adult_dose = r.get('dosages', {}).get('adult_dose_mg')
                ped_dose = r.get('dosages', {}).get('dose_mg_kg')
                
                params.extend([
                    str(r['med_id']),
                    r.get('trade_name'),
                    r.get('dailymed_name'), # Using dailymed name as active/generic proxy if needed
                    float(adult_dose) if adult_dose else None,
                    float(ped_dose) if ped_dose else None,
                    r.get('clinical_text', {}).get('dosage', '')[:2000],
                    json.dumps(r, ensure_ascii=False)
                ])

            sql = f"""
            INSERT OR REPLACE INTO med_dosages 
            (med_id, trade_name, active_ingredient, adult_dose_mg, pediatric_dose_mg_kg, dosage_text, json_data)
            VALUES {', '.join(placeholders)}
            """
            try:
                self.query(sql, params)
                print(f"  Uploaded batch {i//batch_size + 1}")
            except Exception as e:
                print(f"  ❌ Batch failed: {e}")

    def sync_interactions(self, file_path):
        print(f"🔄 Syncing Interactions from {file_path}")
        with open(file_path, 'r') as f:
            records = json.load(f)

        if not records: return
        
        batch_size = 50 
        for i in range(0, len(records), batch_size):
             batch = records[i:i+batch_size]
             
             placeholders = []
             params = []
             for r in batch:
                 placeholders.append("(?, ?, ?, ?, ?, ?)")
                 params.extend([
                     r['ingredient1'].lower(), # Normalize case for better matching
                     r['ingredient2'].lower(), 
                     r['severity'],
                     r.get('effect', '')[:500],
                     r.get('recommendation', '')[:500],
                     r.get('source', 'DailyMed')
                 ])
                 
             sql = f"""
             INSERT OR REPLACE INTO drug_interactions 
             (ingredient1, ingredient2, severity, effect, recommendation, source)
             VALUES {', '.join(placeholders)}
             """
             try:
                 self.query(sql, params)
                 print(f"  Uploaded batch {i//batch_size + 1}")
             except Exception as e:
                 print(f"  ❌ Batch failed: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--dosages", help="Path to dosage updates jsonl")
    parser.add_argument("--interactions", help="Path to interactions updates json")
    parser.add_argument("--account-id", required=True)
    parser.add_argument("--database-id", required=True)
    parser.add_argument("--api-token", help="API Token")
    parser.add_argument("--email", help="Email for Global Key")
    parser.add_argument("--global-key", help="Global Key")
    
    args = parser.parse_args()
    
    uploader = CloudflareD1Uploader(args.account_id, args.database_id, args.api_token, args.email, args.global_key)
    uploader.init_tables()
    
    if args.dosages and os.path.exists(args.dosages):
        uploader.sync_dosages(args.dosages)
        
    if args.interactions and os.path.exists(args.interactions):
        uploader.sync_interactions(args.interactions)
