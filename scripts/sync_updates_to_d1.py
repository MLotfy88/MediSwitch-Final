#!/usr/bin/env python3
"""
Sync Daily Updates to Cloudflare D1
Uplods incremental changes to 'med_dosages' and 'drug_interactions' tables.
"""

import sys
import os
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
        result = resp.json()
        if not result.get("success", False):
            # Extract errors
            errors = result.get("errors", [])
            error_msg = "; ".join([e.get("message", "Unknown Error") for e in errors])
            raise Exception(f"D1 Query Failed: {error_msg}")
        return result

    def init_tables(self):
        # 1. Dosage Guidelines (Keyed by id, but med_id used for sync)
        sql_dosages = """
        CREATE TABLE IF NOT EXISTS dosage_guidelines (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            med_id INTEGER NOT NULL,
            dailymed_setid TEXT,
            min_dose REAL,
            max_dose REAL,
            frequency INTEGER,
            duration INTEGER,
            instructions TEXT,
            condition TEXT,
            source TEXT,
            is_pediatric BOOLEAN,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        """
        self.query(sql_dosages)
        
        # 2. Drug Interactions
        sql_interactions = """
        CREATE TABLE IF NOT EXISTS drug_interactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ingredient1 TEXT NOT NULL,
            ingredient2 TEXT NOT NULL,
            severity TEXT,
            effect TEXT,
            arabic_effect TEXT,
            recommendation TEXT,
            arabic_recommendation TEXT,
            source TEXT,
            type TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(ingredient1, ingredient2)
        );
        """
        self.query(sql_interactions)
        
        # 3. Food Interactions
        sql_food = """
        CREATE TABLE IF NOT EXISTS food_interactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            med_id INTEGER NOT NULL,
            trade_name TEXT,
            interaction TEXT NOT NULL,
            source TEXT DEFAULT 'DrugBank',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        """
        self.query(sql_food)
        
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
                # Handle nested structure from fetch_daily_updates.py
                dosages = r.get('dosages', {})
                clinical = r.get('clinical_text', {})
                
                # Linkage mapping
                placeholders.append("(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)")
                params.extend([
                    int(r['med_id']),
                    r.get('set_id', r.get('dailymed_setid', '')),
                    float(dosages.get('adult_dose_mg') or dosages.get('min_dose') or 0),
                    float(dosages.get('max_dose_mg') or dosages.get('max_dose')) if (dosages.get('max_dose_mg') or dosages.get('max_dose')) else None,
                    int(dosages.get('frequency_hours') or dosages.get('frequency') or 24),
                    7, # Default duration
                    clinical.get('dosage', '')[:1000],
                    r.get('condition', 'General'),
                    r.get('source', 'DailyMed'),
                    1 if dosages.get('is_pediatric') else 0
                ])
            
            sql = f"""
            INSERT OR REPLACE INTO dosage_guidelines  
            (med_id, dailymed_setid, min_dose, max_dose, frequency, duration, instructions, condition, source, is_pediatric)
            VALUES {','.join(placeholders)}
            """
            try:
                self.query(sql, params)
                print(f"  Uploaded batch {i//batch_size + 1}")
            except Exception as e:
                print(f"  ❌ Batch failed: {e}")

    def sync_interactions(self, file_path):
        print(f"🔄 Syncing Interactions from {file_path}")
        with open(file_path, 'r') as f:
             if file_path.endswith('.jsonl'):
                 records = [json.loads(line) for line in f if line.strip()]
             else:
                 records = json.load(f)

        if not records: return
        
        batch_size = 50 
        for i in range(0, len(records), batch_size):
             batch = records[i:i+batch_size]
             
             placeholders = []
             params = []
             for r in batch:
                 placeholders.append("(?, ?, ?, ?, ?, ?, ?, ?, ?)")
                 params.extend([
                     r['ingredient1'].lower(),
                     r['ingredient2'].lower(), 
                     r['severity'],
                     r.get('effect', ''),
                     r.get('arabic_effect', ''),
                     r.get('recommendation', ''),
                     r.get('arabic_recommendation', ''),
                     r.get('source', 'DailyMed'),
                     r.get('type', 'pharmacodynamic')
                 ])
                 
             sql = f"""
             INSERT OR REPLACE INTO drug_interactions 
             (ingredient1, ingredient2, severity, effect, arabic_effect, recommendation, arabic_recommendation, source, type)
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
