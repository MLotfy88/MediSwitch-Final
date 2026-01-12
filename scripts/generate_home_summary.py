import sqlite3
import os

DB_PATH = 'assets/database/mediswitch.db'

def generate_summary():
    if not os.path.exists(DB_PATH):
        print(f"Database not found: {DB_PATH}")
        return

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # 1. Create table
    cursor.execute("DROP TABLE IF EXISTS home_summary")
    cursor.execute("""
        CREATE TABLE home_summary (
            type TEXT,          -- 'food_interaction' or 'high_risk_ingredient'
            name TEXT,
            count INTEGER,
            med_id INTEGER,     -- optional, for navigation
            severe_count INTEGER,
            moderate_count INTEGER,
            minor_count INTEGER,
            danger_score INTEGER
        )
    """)
    
    print("Populating food_interaction summaries...")
    cursor.execute("""
        INSERT INTO home_summary (type, name, count, med_id)
        SELECT 'food_interaction', ingredient, COUNT(*), MAX(med_id)
        FROM food_interactions
        WHERE ingredient IS NOT NULL AND ingredient != ''
        GROUP BY ingredient
        ORDER BY COUNT(*) DESC
        LIMIT 20
    """)
    
    print("Populating high_risk_ingredient summaries...")
    # Matches the logic in SqliteLocalDataSource.getHighRiskIngredientsWithMetrics
    cursor.execute("""
        INSERT INTO home_summary (type, name, count, severe_count, moderate_count, minor_count, danger_score)
        SELECT 
            'high_risk_ingredient',
            di.ingredient1,
            COUNT(*),
            SUM(CASE WHEN LOWER(di.severity) IN ('contraindicated', 'severe', 'critical', 'high') THEN 1 ELSE 0 END),
            SUM(CASE WHEN LOWER(di.severity) IN ('major', 'moderate', 'serious') THEN 1 ELSE 0 END),
            SUM(CASE WHEN LOWER(di.severity) = 'minor' THEN 1 ELSE 0 END),
            SUM(CASE 
                WHEN LOWER(di.severity) = 'contraindicated' THEN 10 
                WHEN LOWER(di.severity) IN ('severe', 'critical') THEN 8
                ELSE 1 
            END) as dangerScore
        FROM drug_interactions di
        JOIN (SELECT DISTINCT ingredient FROM med_ingredients) mi ON di.ingredient1 = mi.ingredient
        WHERE LOWER(di.severity) IN ('contraindicated', 'severe', 'major', 'high')
        GROUP BY di.ingredient1
        ORDER BY dangerScore DESC
        LIMIT 20
    """)
    
    conn.commit()
    conn.close()
    print("Home summary table generated successfully.")

if __name__ == "__main__":
    generate_summary()
