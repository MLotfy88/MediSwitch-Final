import sqlite3
import os

SOURCE_DB = 'assets/database/mediswitch.db'
CORE_DB = 'assets/database/mediswitch_core.db'

def create_smart_core():
    """Create a smart core DB with essential interactions only"""
    if not os.path.exists(SOURCE_DB):
        print(f"Source DB not found: {SOURCE_DB}")
        return

    if os.path.exists(CORE_DB):
        os.remove(CORE_DB)

    print(f"Creating Smart Core DB from {SOURCE_DB}...")
    
    # Connect to source
    src_conn = sqlite3.connect(SOURCE_DB)
    src_cursor = src_conn.cursor()
    
    # Create new core DB
    core_conn = sqlite3.connect(CORE_DB)
    core_cursor = core_conn.cursor()
    
    # 1. Copy schema for all tables except dosage_guidelines
    print("Copying schema...")
    src_cursor.execute("SELECT sql FROM sqlite_master WHERE type='table' AND name NOT IN ('android_metadata', 'sqlite_sequence', 'dosage_guidelines')")
    for row in src_cursor.fetchall():
        if row[0]:
            core_cursor.execute(row[0])
    
    # 2. Copy full data for core tables
    core_tables = ['drugs', 'med_ingredients', 'home_summary']
    for table in core_tables:
        print(f"Copying {table}...")
        src_cursor.execute(f"SELECT * FROM {table}")
        rows = src_cursor.fetchall()
        if rows:
            placeholders = ','.join(['?' for _ in rows[0]])
            core_cursor.executemany(f"INSERT INTO {table} VALUES ({placeholders})", rows)
    
    # 3. Copy essential interactions only
    print("Extracting essential drug interactions...")
    # Get top ingredients from home_summary
    src_cursor.execute("""
        SELECT name FROM home_summary 
        WHERE type = 'high_risk_ingredient' 
        ORDER BY danger_score DESC 
        LIMIT 20
    """)
    high_risk_ingredients = [row[0] for row in src_cursor.fetchall()]
    
    if high_risk_ingredients:
        placeholders = ','.join(['?' for _ in high_risk_ingredients])
        query = f"""
            SELECT * FROM drug_interactions 
            WHERE ingredient1 IN ({placeholders}) OR ingredient2 IN ({placeholders})
        """
        src_cursor.execute(query, high_risk_ingredients + high_risk_ingredients)
        interactions = src_cursor.fetchall()
        
        if interactions:
            placeholders = ','.join(['?' for _ in interactions[0]])
            core_cursor.executemany(f"INSERT INTO drug_interactions VALUES ({placeholders})", interactions)
        print(f"  Copied {len(interactions)} drug interactions")
    
    # 4. Copy essential food interactions
    print("Extracting essential food interactions...")
    src_cursor.execute("""
        SELECT name FROM home_summary 
        WHERE type = 'food_interaction' 
        ORDER BY count DESC 
        LIMIT 20
    """)
    top_food_ingredients = [row[0] for row in src_cursor.fetchall()]
    
    if top_food_ingredients:
        placeholders = ','.join(['?' for _ in top_food_ingredients])
        query = f"SELECT * FROM food_interactions WHERE ingredient IN ({placeholders})"
        src_cursor.execute(query, top_food_ingredients)
        food_interactions = src_cursor.fetchall()
        
        if food_interactions:
            placeholders = ','.join(['?' for _ in food_interactions[0]])
            core_cursor.executemany(f"INSERT INTO food_interactions VALUES ({placeholders})", food_interactions)
        print(f"  Copied {len(food_interactions)} food interactions")
    
    # 5. Copy essential disease interactions (if any related to top drugs)
    print("Extracting essential disease interactions...")
    try:
        src_cursor.execute("SELECT DISTINCT med_id FROM drugs LIMIT 100")
        top_drug_ids = [row[0] for row in src_cursor.fetchall()]
        
        if top_drug_ids:
            placeholders = ','.join(['?' for _ in top_drug_ids])
            query = f"SELECT * FROM disease_interactions WHERE med_id IN ({placeholders})"
            src_cursor.execute(query, top_drug_ids)
            disease_interactions = src_cursor.fetchall()
            
            if disease_interactions:
                placeholders = ','.join(['?' for _ in disease_interactions[0]])
                core_cursor.executemany(f"INSERT INTO disease_interactions VALUES ({placeholders})", disease_interactions)
            print(f"  Copied {len(disease_interactions)} disease interactions")
    except Exception as e:
        print(f"  Warning: {e}")
    
    # 6. Copy indices
    print("Copying indices...")
    src_cursor.execute("SELECT sql FROM sqlite_master WHERE type='index' AND sql IS NOT NULL")
    for row in src_cursor.fetchall():
        try:
            core_cursor.execute(row[0])
        except:
            pass  # Skip if index already exists or conflicts
    
    # Commit and close
    core_conn.commit()
    src_conn.close()
    core_conn.close()
    
    # 7. VACUUM to optimize
    print("Optimizing Core DB...")
    core_conn = sqlite3.connect(CORE_DB)
    core_conn.execute("VACUUM")
    core_conn.close()
    
    core_size = os.path.getsize(CORE_DB) / (1024*1024)
    print(f"✅ Smart Core DB created successfully! Size: {core_size:.2f} MB")

if __name__ == "__main__":
    create_smart_core()
