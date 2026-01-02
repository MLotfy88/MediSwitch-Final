import sqlite3
import os

DB_PATH = "mediswitch.db"

def audit_db():
    if not os.path.exists(DB_PATH):
        print(f"❌ Database not found at {DB_PATH}")
        return

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    # Get all tables
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
    tables = [row[0] for row in cursor.fetchall()]

    print(f"📊 Auditing Database: {DB_PATH}")
    print("=" * 60)

    for table in tables:
        if table == 'sqlite_sequence': continue
        
        # Get total rows
        cursor.execute(f"SELECT COUNT(*) FROM {table}")
        total_rows = cursor.fetchone()[0]
        
        print(f"\nTable: {table} ({total_rows:,} rows)")
        print("-" * 60)
        
        # Get columns
        cursor.execute(f"PRAGMA table_info({table})")
        columns = cursor.fetchall()
        
        for col in columns:
            col_name = col[1]
            
            # Count non-null and non-empty
            cursor.execute(f"""
                SELECT COUNT(*) FROM {table} 
                WHERE {col_name} IS NOT NULL 
                AND {col_name} != '' 
                AND {col_name} != 'N/A'
                AND {col_name} != 'nan'
            """)
            filled_count = cursor.fetchone()[0]
            fill_rate = (filled_count / total_rows * 100) if total_rows > 0 else 0
            
            print(f"  {col_name:<25} | Filled: {filled_count:>8,} | Rate: {fill_rate:>6.1f}%")

    conn.close()

if __name__ == "__main__":
    audit_db()
