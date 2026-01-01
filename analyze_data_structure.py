import sqlite3
import csv
import os

CSV_PATH = 'assets/external_research_data/ddinter_interactions_v6.csv'
DB_PATH = 'ddinter_data/ddinter_complete.db'

print("--- Checking CSV Header ---")
try:
    if os.path.exists(CSV_PATH):
        with open(CSV_PATH, 'r', encoding='utf-8') as f:
            reader = csv.reader(f)
            header = next(reader)
            print(f"CSV Columns: {header}")
    else:
        print(f"CSV not found at {CSV_PATH}")
except Exception as e:
    print(f"Error reading CSV: {e}")

print("\n--- Checking DB Schema ---")
try:
    if os.path.exists(DB_PATH):
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.execute("PRAGMA table_info(drug_drug_interactions)")
        columns = [row[1] for row in cursor.fetchall()]
        print(f"DB Columns: {columns}")
        conn.close()
    else:
        print(f"DB not found at {DB_PATH}")
except Exception as e:
    print(f"Error reading DB: {e}")
