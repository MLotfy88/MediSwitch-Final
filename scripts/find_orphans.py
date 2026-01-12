import sqlite3
import os

DB_PATH = "assets/database/mediswitch.db"

def check_orphans():
    if not os.path.exists(DB_PATH):
        print(f"❌ Database not found: {DB_PATH}")
        return

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    print(f"🔍 Analyzing Database for Orphan Records: {DB_PATH}\n")

    # 1. Check Dosage Guidelines (Linked by med_id)
    print("--- Dosage Guidelines ---")
    cursor.execute("SELECT COUNT(*) FROM dosage_guidelines")
    total_dosage = cursor.fetchone()[0]
    
    cursor.execute("""
        SELECT COUNT(*) FROM dosage_guidelines 
        WHERE med_id NOT IN (SELECT id FROM drugs)
    """)
    orphan_dosage = cursor.fetchone()[0]
    print(f"Total Records: {total_dosage}")
    print(f"Orphan Records (Invalid med_id): {orphan_dosage} ({(orphan_dosage/total_dosage*100):.2f}%)" if total_dosage else "0")

    # 2. Check Disease Interactions (Linked by med_id)
    print("\n--- Disease Interactions ---")
    cursor.execute("SELECT COUNT(*) FROM disease_interactions")
    total_disease = cursor.fetchone()[0]
    
    cursor.execute("""
        SELECT COUNT(*) FROM disease_interactions 
        WHERE med_id NOT IN (SELECT id FROM drugs)
    """)
    orphan_disease = cursor.fetchone()[0]
    print(f"Total Records: {total_disease}")
    print(f"Orphan Records (Invalid med_id): {orphan_disease} ({(orphan_disease/total_disease*100):.2f}%)" if total_disease else "0")

    # 3. Check Food Interactions (Linked by med_id)
    print("\n--- Food Interactions ---")
    cursor.execute("SELECT COUNT(*) FROM food_interactions")
    total_food = cursor.fetchone()[0]
    
    cursor.execute("""
        SELECT COUNT(*) FROM food_interactions 
        WHERE med_id NOT IN (SELECT id FROM drugs)
    """)
    orphan_food = cursor.fetchone()[0]
    print(f"Total Records: {total_food}")
    print(f"Orphan Records (Invalid med_id): {orphan_food} ({(orphan_food/total_food*100):.2f}%)" if total_food else "0")

    # 4. Check Drug Interactions (Linked by ingredient name)
    # This is trickier. Interactions are between ingredient1 and ingredient2.
    # An orphan here means NEITHER ingredient1 NOR ingredient2 exists in our `med_ingredients` table.
    # OR we could be stricter: if ONE of them doesn't exist, is it useful? 
    # Usually, we want to show interactions for drugs we HAVE. 
    # If we have Drug A (ingredient X), and the interaction is X + Y. 
    # If we don't have ANY drug with ingredient Y, is that interaction useful?
    # Maybe yes, if the user manually checks "X". 
    # But usually, checking "orphans" implies data that can NEVER be triggered.
    # Let's count interactions where NEITHER ingredient is in our system.
    
    print("\n--- Drug Interactions ---")
    
    # Ensure med_ingredients is populated/up-to-date (it should be)
    cursor.execute("SELECT COUNT(*) FROM med_ingredients")
    total_ingredients_map = cursor.fetchone()[0]
    print(f"Total Med-Ingredient mappings: {total_ingredients_map}")

    cursor.execute("SELECT COUNT(*) FROM drug_interactions")
    total_interactions = cursor.fetchone()[0]
    
    # Count rows where NEITHER ingredient1 NOR ingredient2 is found in med_ingredients
    # Normalized check (LOWER/TRIM) is best practice
    cursor.execute("""
        SELECT COUNT(*) FROM drug_interactions 
        WHERE 
            LOWER(TRIM(ingredient1)) NOT IN (SELECT LOWER(TRIM(ingredient)) FROM med_ingredients)
            AND 
            LOWER(TRIM(ingredient2)) NOT IN (SELECT LOWER(TRIM(ingredient)) FROM med_ingredients)
    """)
    orphan_interactions_strict = cursor.fetchone()[0]
    
    # Count rows where AT LEAST ONE is missing (just for info)
    # If I only have Drug A, and it interacts with Drug B (which I don't sell), 
    # I still might want to know about it. So strict orphan is "neither exists".
    
    print(f"Total Records: {total_interactions}")
    print(f"Orphan Records (Neither ingredient exists): {orphan_interactions_strict} ({(orphan_interactions_strict/total_interactions*100):.2f}%)" if total_interactions else "0")

    conn.close()

if __name__ == "__main__":
    check_orphans()
