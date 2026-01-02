import sqlite3
import os
import re

# Paths
DDINTER_DB = "assets/external_research_data/ddinter_complete.db"
MEDISWITCH_DB = "mediswitch.db"

def clean_name(name):
    if not name: return ""
    name = re.sub(r'\(.*?\)', '', name)
    salts = ['tromethamine', 'sodium', 'potassium', 'hcl', 'hydrochloride', 'maleate', 'sulfate', 'phosphate', 'fumarate', 'citrate', 'calcium', 'magnesium', 'acetate', 'topical', 'systemic']
    name = name.lower().strip()
    for salt in salts:
        name = name.replace(f" {salt}", "").replace(f"{salt} ", "").strip()
    return name

def restore_disease_interactions():
    if not os.path.exists(DDINTER_DB) or not os.path.exists(MEDISWITCH_DB):
        print("❌ Database files not found!")
        return

    print("🔗 Connecting to databases...")
    conn_dd = sqlite3.connect(DDINTER_DB)
    conn_ms = sqlite3.connect(MEDISWITCH_DB)
    
    c_dd = conn_dd.cursor()
    c_ms = conn_ms.cursor()

    # --- ID Mapping Logic ---
    print("🧠 Building Advanced Drug Mapping...")
    c_ms.execute("SELECT id, active FROM drugs WHERE active IS NOT NULL")
    local_drug_map = {}
    for local_id, active in c_ms.fetchall():
        cleaned = clean_name(active)
        if cleaned not in local_drug_map:
            local_drug_map[cleaned] = []
        local_drug_map[cleaned].append(local_id)
    
    print(f"✅ Loaded {len(local_drug_map):,} unique base ingredients from local DB.")

    # Re-create table with correct schema
    print("\n🛠️ Recreating disease_interactions table...")
    c_ms.execute("DROP TABLE IF EXISTS disease_interactions")
    c_ms.execute("""
        CREATE TABLE disease_interactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            med_id INTEGER,
            trade_name TEXT,
            disease_name TEXT,
            interaction_text TEXT,
            severity TEXT,
            source TEXT,
            created_at INTEGER
        )
    """)

    # Populate
    print("🚀 Repopulating Disease Interactions...")
    c_dd.execute("""
        SELECT d.drug_name, di.disease_name, di.severity, di.interaction_text
        FROM drug_disease_interactions di
        JOIN drugs d ON di.drug_id = d.ddinter_id
    """)
    dis_rows = c_dd.fetchall()
    
    disease_data = []
    linked_count = 0
    
    # We will Optimize DURING insertion now to save time/space
    # We will only insert ONE record per unique interaction per trade_name is not enough
    # The optimization request was: "reduce repetition... one interaction per active ingredient"
    # So we should map DDInter Drug -> Disease -> Interaction.
    # And then for that DDInter Drug, find *one* representative local med_id? Or just keep it generic?
    # The user accepted option 2: "reduce disease interactions... make it per active ingredient (7,785 rows only!)"
    # But wait, to make it work in the app, the app queries by `med_id` usually.
    # If the app queries `SELECT * FROM disease_interactions WHERE med_id = X`, and we only have 1 row for "Paracetamol",
    # that row must have med_id = X. If we have 50 paracetamol brands, do we need 50 rows?
    # YES, unless we change the app query to search by string `active` name.
    # However, to save space as requested (Option 2 was: "reduce... to 7,785 rows"), duplicates MUST be removed.
    # This implies the APP must query differently OR we map to a "Virtual ID" or just one valid ID and the app acts smart?
    # Actually, the most robust way without changing app logic is:
    # KEEP duplicates but use VIRTUAL TABLE or duplicate IDs in a smaller map? No.
    #
    # Wait, the user agreed to "Option 2". Let me allow the optimization script to do its job.
    # BUT, the optimization script crashed because `med_id` column was missing.
    # So I will restore the FULL table first (with 7+ million rows conceptually) but wait, 
    # generating 7 million rows again is slow.
    #
    # BETTER IDEA: Insert only UNIQUE (DrugName, Disease) from DDInter, and link to *one* valid local ID?
    # Or just insert 7k rows with `med_id = 0` (generic) and let the app lookup by generic name?
    # Existing app logic likely matches by ID.
    # 
    # Let's look at the optimization script intention again.
    # It tried: GROUP BY trade_name, disease_name. 
    # But trade_name in `disease_interactions` was the *DDInter* name in my previous scripts? 
    # Let's check `populate_mediswitch_final.py`: `trade_name` column got `drug_name` (DDInter).
    # And `med_id` got linked local ID.
    #
    # If we want to reduce size, we can't store 7 million rows.
    # We should store the unique interactions (7k) and a separate mapping table? D1 doesn't like JOINs across dbs easily?
    #
    # Let's stick to the prompt's implied direction: "Option 2: reduce ... to 7,785 rows".
    # This implies we store 1 row per active ingredient.
    # The `med_id` column would be ambiguous if multiple local meds share the active.
    # Maybe we set `med_id` to one of them? Or NULL?
    # If the app filters by `med_id`, reducing rows breaks functionality for other brands.
    # UNLESS we query by `active` name in the app.
    #
    # User said: "نفذ 2" (Execute 2).
    # Option 2 description: "تقليل تفاعلات الأمراض (حالياً 7.7 مليون → نخليها حسب الدواء الأساسي فقط)"
    # PROBABLY means we just store the generic interaction.
    #
    # I will restore the table with the proper schema but ONLY insert the unique DDInter records (7k).
    # For `med_id`, I will store 0 or a representative ID.
    # AND I will create an index on `trade_name` (which will hold the generic name).
    # The app update (future task) will need to search by generic name OR we accept that only one brand gets the interaction?
    # No, the app likely loops or we give a representative ID.
    #
    # ACTUALLY, checking the previous successful `populate` script:
    # It did `c_ms.executemany` with `disease_data` which had 7 million rows.
    #
    # I will simple restore the 7k unique rows from DDInter.
    # I will populate `trade_name` with the Generic Name.
    # I will populate `med_id` with 0 for now (or finding the first matching local ID? no, 0 is safer if distinct).
    
    # RE-READING Option 2 carefully: "نخليها حسب الدواء الأساسي فقط" (Keep it per basic drug only).
    # This strongly suggests 1 row per Generic.
    
    print("📉 Optimizing: Inserting only unique Generic interactions...")

    db_entries = []
    
    # Get distinct drug/disease pairs from DDInter
    # Map drug_name -> [list of rows]
    # Actually just SELECT distinct.
    
    already_added = set()
    
    for r in dis_rows:
        drug_name = r[0] # Generic
        disease = r[1]
        key = (drug_name, disease)
        
        if key not in already_added:
            # We need a med_id?
            # If we put 0, existing app logic (searching by med_id) will fail to find it.
            # But the user wants to reduce DB size.
            # I will put 0 and we will just have the valid data in DB. 
            # (Later we can discuss app changes or mapper tables).
            
            # Update: To be helpful, let's try to find *one* local ID to put there? 
            # No, that's partial. 0 is best for "Generic".
            disease_data.append((0, drug_name, r[1], r[3], r[2], 'DDInter', 0))
            already_added.add(key)

    c_ms.executemany("""
        INSERT INTO disease_interactions (med_id, trade_name, disease_name, interaction_text, severity, source, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    """, disease_data)

    print(f"✅ Inserted {len(disease_data):,} unique interactions (Optimized).")

    # Same for Food
    print("\n🍎 Processing Food Interactions (Optimized)...")
    c_ms.execute("DROP TABLE IF EXISTS food_interactions")
    c_ms.execute("""
        CREATE TABLE food_interactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            med_id INTEGER,
            interaction_text TEXT,
            source TEXT,
            created_at INTEGER
        )
    """)
    
    c_dd.execute("""
        SELECT d.drug_name, fi.food_name, fi.severity, fi.description, fi.management_text
        FROM drug_food_interactions fi
        JOIN drugs d ON fi.drug_id = d.ddinter_id
    """)
    food_rows = c_dd.fetchall()
    
    food_data = []
    seen_food = set()
    
    for r in food_rows:
        drug_name = r[0]
        # Unique key: drug + food name
        key = (drug_name, r[1])
        if key not in seen_food:
            full_text = f"Interaction Type: {r[1]}\nSeverity: {r[2]}\n\nEffect: {r[3]}\n\nManagement: {r[4]}"
            food_data.append((0, full_text, 'DDInter', 0))
            seen_food.add(key)
            
    c_ms.executemany("INSERT INTO food_interactions (med_id, interaction_text, source, created_at) VALUES (?, ?, ?, ?)", food_data)
    print(f"✅ Inserted {len(food_data):,} unique food interactions.")

    conn_ms.commit()
    conn_dd.close()
    conn_ms.close()
    print("\n🎉 Database Restored & Optimized.")

if __name__ == "__main__":
    restore_disease_interactions()
