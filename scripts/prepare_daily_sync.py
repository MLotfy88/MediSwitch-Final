#!/usr/bin/env python3
import os
from datetime import datetime, timedelta

SYNC_DATE_FILE = "production_data/last_dailymed_sync.txt"

def get_last_sync_date():
    if os.path.exists(SYNC_DATE_FILE):
        with open(SYNC_DATE_FILE, 'r') as f:
            date_str = f.read().strip()
            try:
                # Validate format
                datetime.strptime(date_str, "%Y-%m-%d")
                return date_str
            except:
                pass
    
    # Default: 3 days ago to be safe
    return (datetime.now() - timedelta(days=3)).strftime("%Y-%m-%d")

def save_sync_date(date_str=None):
    if not date_str:
        date_str = datetime.now().strftime("%Y-%m-%d")
    
    os.makedirs(os.path.dirname(SYNC_DATE_FILE), exist_ok=True)
    with open(SYNC_DATE_FILE, 'w') as f:
        f.write(date_str)
    print(f"✅ Saved sync date: {date_str}")

if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == "save":
        save_sync_date()
    else:
        print(get_last_sync_date())
