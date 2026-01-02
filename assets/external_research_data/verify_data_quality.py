import sqlite3
import os

DB_PATH = 'ddinter_complete.db'

def check_db():
    if not os.path.exists(DB_PATH):
        # Fallback for different working directory
        if os.path.exists('assets/external_research_data/' + DB_PATH):
            db_file = 'assets/external_research_data/' + DB_PATH
        else:
            print(f"❌ Database file '{DB_PATH}' not found!")
            return
    else:
        db_file = DB_PATH

    print(f"🔍 Analyzing database: {db_file}")
    conn = sqlite3.connect(db_file)
    conn.row_factory = sqlite3.Row
    c = conn.cursor()

    # Get all user tables
    c.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name != 'scrap_status';")
    tables = [row['name'] for row in c.fetchall()]
    
    print("\n📊 COMPREHENSIVE DATABASE ANALYSIS")
    print("="*70)

    for table in tables:
        print(f"\n📂 Table: {table}")
        
        # Get total count
        c.execute(f"SELECT COUNT(*) as count FROM {table}")
        total = c.fetchone()['count']
        print(f"📈 Total Rows: {total:,}")
        print("-" * 70)
        
        if total == 0:
            print("⚠️ Table is empty.")
            continue

        # Get column info
        c.execute(f"PRAGMA table_info({table})")
        columns = c.fetchall()
        
        print(f"{'  Column Name':<35} | {'Filled':<12} | {'Fill Rate':<10}")
        print("-" * 70)
        
        for col in columns:
            col_name = col['name']
            
            # Count non-empty values
            # Considering None, empty string, 'null' string, and '[]' (for JSON) as empty
            query = f"""
                SELECT COUNT(*) as filled 
                FROM {table} 
                WHERE {col_name} IS NOT NULL 
                AND cast({col_name} as text) != '' 
                AND lower(cast({col_name} as text)) != 'null' 
                AND {col_name} != '[]'
            """
            try:
                c.execute(query)
                filled = c.fetchone()['filled']
                pct = (filled / total) * 100
                
                status_icon = "🌟" if pct == 100 else "✅" if pct > 80 else "⚠️" if pct > 0 else "❌"
                print(f"{status_icon} {col_name:<33} | {filled:>11,} | {pct:>8.1f}%")
            except Exception as e:
                print(f"❌ {col_name:<33} | ERROR: {str(e)[:20]}")
        print("-" * 70)

    conn.close()

if __name__ == '__main__':
    check_db()
