import sqlite3
import os

DB_PATH = 'mediswitch.db'

def analyze_size():
    if not os.path.exists(DB_PATH):
        print("Database not found.")
        return

    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    
    print(f"📦 Total Database File Size: {os.path.getsize(DB_PATH) / (1024*1024):.2f} MB")
    print("-" * 40)
    print(f"{'Table':<30} | {'Est. Size (MB)':<10} | {'Rows':<10}")
    print("-" * 40)
    
    c.execute("SELECT name FROM sqlite_master WHERE type='table'")
    tables = c.fetchall()
    
    total_est = 0
    
    for (table,) in tables:
        # Get simple count
        c.execute(f"SELECT COUNT(*) FROM {table}")
        count = c.fetchone()[0]
        
        # Estimate size by dumping to temp string (rough approx)
        # Better: use dbstat if available (often not enabled)
        # Fallback: Measure length of columns for a sample
        
        # We can also use 'pragma page_count' logic if we knew pages per table, but that's hard in standard sqlite without dbstat.
        # Let's try to get average row size * count
        
        if count > 0:
            c.execute(f"SELECT * FROM {table} LIMIT 100")
            sample = c.fetchall()
            if sample:
                import sys
                avg_size = sum([sum([sys.getsizeof(str(col)) for col in row]) for row in sample]) / len(sample)
                est_size_mb = (avg_size * count) / (1024*1024)
            else:
                est_size_mb = 0
        else:
            est_size_mb = 0
            
        print(f"{table:<30} | {est_size_mb:>10.2f} | {count:>10}")
        total_est += est_size_mb
        
    print("-" * 40)
    print(f"Total Content Approx: {total_est:.2f} MB")
    print("Note: Index overhead and page fragmentation are NOT included in this content-only estimate, but account for significant disk usage.")

    conn.close()

if __name__ == "__main__":
    analyze_size()
