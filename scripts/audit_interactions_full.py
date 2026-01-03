import sqlite3
import subprocess
import json
import re

# --- Configuration ---
DB_PATH = "mediswitch.db"
D1_DATABASE = "mediswitch-interactions"

def run_d1_query(query):
    """Run a query on D1 and return the result as a list of dicts"""
    cmd = ["npx", "wrangler", "d1", "execute", D1_DATABASE, "--command", query, "--remote", "--json"]
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        # Wrangler JSON output is sometimes wrapped in extra text
        out = result.stdout
        # Find the start of the JSON array
        match = re.search(r'\[.*\]', out, re.DOTALL)
        if match:
            return json.loads(match.group(0))[0].get('results', [])
        return []
    except Exception as e:
        print(f"Error running D1 query: {e}")
        return []

def get_local_stats(table_name, columns):
    """Get non-null counts for each column in local SQLite"""
    conn = sqlite3.connect(DB_PATH)
    stats = {}
    
    # Total row count
    cursor = conn.execute(f"SELECT COUNT(*) FROM {table_name}")
    stats['total_rows'] = cursor.fetchone()[0]
    
    # Column non-null counts
    for col in columns:
        cursor = conn.execute(f"SELECT COUNT(*) FROM {table_name} WHERE {col} IS NOT NULL AND {col} != ''")
        stats[f"col_{col}"] = cursor.fetchone()[0]
    
    conn.close()
    return stats

def get_d1_stats(table_name, columns):
    """Get non-null counts for each column in D1"""
    stats = {}
    
    # Total row count
    res = run_d1_query(f"SELECT COUNT(*) as count FROM {table_name}")
    stats['total_rows'] = res[0]['count'] if res else 0
    
    # Column non-null counts
    for col in columns:
        res = run_d1_query(f"SELECT COUNT(*) as count FROM {table_name} WHERE {col} IS NOT NULL AND {col} != ''")
        stats[f"col_{col}"] = res[0]['count'] if res else 0
        
    return stats

def audit_table(table_name, columns):
    print(f"\n📊 Auditing Table: {table_name}...")
    local = get_local_stats(table_name, columns)
    d1 = get_d1_stats(table_name, columns)
    
    print(f"{'Metric':<25} | {'Local':<10} | {'D1':<10} | {'Match':<10}")
    print("-" * 60)
    
    match = local['total_rows'] == d1['total_rows']
    print(f"{'Total Rows':<25} | {local['total_rows']:<10} | {d1['total_rows']:<10} | {'✅' if match else '❌'}")
    
    for col in columns:
        l_count = local[f"col_{col}"]
        d_count = d1[f"col_{col}"]
        match = l_count == d_count
        print(f"{f'Col: {col}':<25} | {l_count:<10} | {d_count:<10} | {'✅' if match else '❌'}")

def perform_audit():
    # 1. Drug Interactions Columns
    drug_cols = ['id', 'ingredient1', 'ingredient2', 'severity', 'effect', 'source', 
                 'management_text', 'mechanism_text', 'recommendation', 'risk_level', 
                 'type', 'metabolism_info', 'source_url', 'reference_text', 
                 'alternatives_a', 'alternatives_b', 'updated_at']
    
    # 2. Food Interactions Columns
    food_cols = ['id', 'med_id', 'trade_name', 'interaction', 'ingredient', 'severity', 
                 'management_text', 'mechanism_text', 'reference_text', 'source', 'created_at']
    
    # 3. Disease Interactions Columns
    disease_cols = ['id', 'med_id', 'trade_name', 'disease_name', 'interaction_text', 
                    'severity', 'reference_text', 'source', 'created_at']
    
    audit_table("drug_interactions", drug_cols)
    audit_table("food_interactions", food_cols)
    audit_table("disease_interactions", disease_cols)

if __name__ == "__main__":
    perform_audit()
