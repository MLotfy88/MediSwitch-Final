import sqlite3
import os
import json
import re

# Paths
DDINTER_DB = "assets/external_research_data/ddinter_complete.db"
MEDISWITCH_DB = "mediswitch.db"

def clean_name(name):
    if not name: return ""
    # Remove content in parentheses e.g. (ophthalmic)
    name = re.sub(r'\(.*?\)', '', name)
    # Common salts to strip for better matching
    salts = ['tromethamine', 'sodium', 'potassium', 'hcl', 'hydrochloride', 'maleate', 'sulfate', 'phosphate', 'fumarate', 'citrate', 'calcium', 'magnesium', 'acetate', 'topical', 'systemic']
    name = name.lower().strip()
    for salt in salts:
        name = name.replace(f" {salt}", "").replace(f"{salt} ", "").strip()
    return name

def update_mediswitch():
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
    local_drug_map = {} # cleaned_name -> list of local IDs
    raw_local_actives = {} # cleaned_name -> raw_active_name
    
    for local_id, active in c_ms.fetchall():
        cleaned = clean_name(active)
        if cleaned not in local_drug_map:
            local_drug_map[cleaned] = []
            raw_local_actives[cleaned] = active
        local_drug_map[cleaned].append(local_id)
    
    print(f"✅ Loaded {len(local_drug_map):,} unique base ingredients from local DB.")

    # 1. Update drug_interactions
    print("\n🧪 Processing Drug-Drug Interactions (DDIs)...")
    c_ms.execute("DELETE FROM drug_interactions")
    sql_ddi = """
        SELECT d1.drug_name, d2.drug_name, di.severity, di.interaction_description, di.management_text, di.mechanism_flags
        FROM drug_drug_interactions di
        JOIN drugs d1 ON di.drug_a_id = d1.ddinter_id
        JOIN drugs d2 ON di.drug_b_id = d2.ddinter_id
    """
    c_dd.execute(sql_ddi)
    rows = c_dd.fetchall()
    
    insert_sql = """
        INSERT INTO drug_interactions (
            ingredient1, ingredient2, severity, effect, source, 
            management_text, mechanism_text, recommendation, risk_level, type, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """
    
    batch_size = 5000
    for i in range(0, len(rows), batch_size):
        batch = rows[i:i+batch_size]
        data_to_insert = []
        for r in batch:
            mech_text = ""
            if r[5]:
                try:
                    mechs = json.loads(r[5])
                    if mechs: mech_text = ", ".join(mechs)
                except: pass

            # Distinct Recommendation Logic:
            # If management text is long, take the first sentence or until the first period.
            management = r[4] if r[4] else ""
            recommendation = management
            if "." in management:
                recommendation = management.split(".")[0].strip() + "."
            
            data_to_insert.append((
                r[0], r[1], r[2], r[3], 'DDInter', 
                management, mech_text, recommendation, r[2], 'pharmacodynamic', 0
            ))
        c_ms.executemany(insert_sql, data_to_insert)
    print(f"✅ Inserted {len(rows):,} DDIs.")

    # 2. Update disease_interactions
    print("\n🚀 Processing Disease Interactions with Fuzzy ID Mapping...")
    c_ms.execute("DELETE FROM disease_interactions")
    c_dd.execute("""
        SELECT d.drug_name, di.disease_name, di.severity, di.interaction_text
        FROM drug_disease_interactions di
        JOIN drugs d ON di.drug_id = d.ddinter_id
    """)
    dis_rows = c_dd.fetchall()
    
    disease_data = []
    linked_count = 0
    for r in dis_rows:
        drug_name = r[0]
        cleaned_dd = clean_name(drug_name)
        
        # Match using base name
        matched_ids = []
        if cleaned_dd in local_drug_map:
            matched_ids = local_drug_map[cleaned_dd]
        else:
            # Fallback: check if DD drug name is contained in any local active name
            for local_active_clean, ids in local_drug_map.items():
                if cleaned_dd in local_active_clean or local_active_clean in cleaned_dd:
                    matched_ids = ids
                    break
        
        if matched_ids:
            for local_id in matched_ids:
                disease_data.append((local_id, drug_name, r[1], r[3], r[2], 'DDInter', 0))
            linked_count += 1
        else:
            disease_data.append((0, drug_name, r[1], r[3], r[2], 'DDInter', 0))

    c_ms.executemany("""
        INSERT INTO disease_interactions (med_id, trade_name, disease_name, interaction_text, severity, source, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    """, disease_data)
    print(f"✅ Inserted {len(disease_data):,} records. Linked {linked_count:,}/{len(dis_rows):,} DDInter drugs.")

    # 3. Update food_interactions
    print("\n🍎 Processing Food Interactions...")
    c_ms.execute("DELETE FROM food_interactions")
    c_dd.execute("""
        SELECT d.drug_name, fi.food_name, fi.severity, fi.description, fi.management_text
        FROM drug_food_interactions fi
        JOIN drugs d ON fi.drug_id = d.ddinter_id
    """)
    food_rows = c_dd.fetchall()
    
    food_data = []
    f_linked_count = 0
    for r in food_rows:
        drug_name = r[0]
        cleaned_dd = clean_name(drug_name)
        full_text = f"Interaction with {r[1]} ({r[2]}):\n{r[3]}\n\nClinical Management: {r[4]}"
        
        matched_ids = []
        if cleaned_dd in local_drug_map:
            matched_ids = local_drug_map[cleaned_dd]
        else:
            for local_active_clean, ids in local_drug_map.items():
                if cleaned_dd in local_active_clean or local_active_clean in cleaned_dd:
                    matched_ids = ids
                    break
                    
        if matched_ids:
            for local_id in matched_ids:
                food_data.append((local_id, full_text, 'DDInter', 0))
            f_linked_count += 1
        else:
            food_data.append((0, full_text, 'DDInter', 0))

    c_ms.executemany("INSERT INTO food_interactions (med_id, interaction_text, source, created_at) VALUES (?, ?, ?, ?)", food_data)
    print(f"✅ Inserted {len(food_data):,} records. Linked {f_linked_count:,}/{len(food_rows):,} DDInter drugs.")

    conn_ms.commit()
    conn_dd.close()
    conn_ms.close()
    print("\n🎉 Mediswitch.db updated safely.")

if __name__ == "__main__":
    update_mediswitch()
