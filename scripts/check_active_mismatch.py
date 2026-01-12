import sqlite3

def check_mismatch():
    conn = sqlite3.connect('assets/database/mediswitch.db')
    c = conn.cursor()
    
    print("--- Top 10 Active Ingredients WITH Dosage ---")
    c.execute("""
        SELECT lower(d.active), count(*) 
        FROM drugs d
        JOIN dosage_guidelines dg ON d.id = dg.med_id
        GROUP BY 1 ORDER BY 2 DESC LIMIT 10
    """)
    for r in c.fetchall():
        print(f"'{r[0]}': {r[1]}")
        
    print("\n--- Top 10 Active Ingredients WITHOUT Dosage ---")
    c.execute("""
        SELECT lower(d.active), count(*) 
        FROM drugs d
        LEFT JOIN dosage_guidelines dg ON d.id = dg.med_id
        WHERE dg.id IS NULL AND d.active IS NOT NULL
        GROUP BY 1 ORDER BY 2 DESC LIMIT 10
    """)
    for r in c.fetchall():
        print(f"'{r[0]}': {r[1]}")
    
    conn.close()

if __name__ == '__main__':
    check_mismatch()
