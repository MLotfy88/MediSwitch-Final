import sqlite3
import re

DB_PATH = "assets/database/mediswitch.db"

def normalize():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    print("--- Normalizing drug_interactions table ---")
    cursor.execute("UPDATE drug_interactions SET ingredient1 = LOWER(TRIM(ingredient1)), ingredient2 = LOWER(TRIM(ingredient2))")
    
    print("--- Rebuilding med_ingredients table ---")
    cursor.execute("DROP TABLE IF EXISTS med_ingredients")
    cursor.execute("""
        CREATE TABLE med_ingredients (
            med_id INTEGER,
            ingredient TEXT,
            PRIMARY KEY (med_id, ingredient)
        )
    """)
    
    cursor.execute("SELECT id, active FROM drugs WHERE active IS NOT NULL AND active != ''")
    drugs = cursor.fetchall()
    
    count = 0
    for med_id, active in drugs:
        # Split by various delimiters
        ingredients = re.split(r'[+;,/]', active)
        for ing in ingredients:
            ing = ing.strip().lower()
            if ing:
                try:
                    cursor.execute("INSERT OR IGNORE INTO med_ingredients (med_id, ingredient) VALUES (?, ?)", (med_id, ing))
                except:
                    pass
        count += 1
        if count % 5000 == 0:
            print(f"Processed {count} drugs...")

    print("--- Creating Indexes ---")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_mi_med_id ON med_ingredients(med_id)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_mi_ingredient ON med_ingredients(ingredient)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_di_ing1 ON drug_interactions(ingredient1)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_di_ing2 ON drug_interactions(ingredient2)")

    conn.commit()
    conn.close()
    print("Normalization complete!")

if __name__ == "__main__":
    normalize()
