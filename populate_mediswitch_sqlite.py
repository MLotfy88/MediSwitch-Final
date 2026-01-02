import sqlite3
import os
import json

# Paths
DDINTER_DB = "assets/external_research_data/ddinter_complete.db"
MEDISWITCH_DB = "mediswitch.db"

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
    print("🧠 Building Generic-to-Local-ID mapping...")
    c_ms.execute("SELECT id, active FROM drugs WHERE active IS NOT NULL")
    local_drug_map = {}
    for local_id, active in c_ms.fetchall():
        active_clean = active.strip().lower()
        if active_clean not in local_drug_map:
            local_drug_map[active_clean] = []
        local_drug_map[active_clean].append(local_id)
    
    print(f"✅ Loaded {len(local_drug_map):,} unique active ingredients from local DB.")

    # 1. Update drug_interactions
    print("\n🧪 Processing Drug-Drug Interactions (DDIs)...")
    c_ms.execute("DELETE FROM drug_interactions")
    sql_ddi = """
        SELECT 
            d1.drug_name as drug_a,
            d2.drug_name as drug_b,
            di.severity,
            di.interaction_description,
            di.management_text,
            di.mechanism_flags
        FROM drug_drug_interactions di
        JOIN drugs d1 ON di.drug_a_id = d1.ddinter_id
        JOIN drugs d2 ON di.drug_b_id = d2.ddinter_id
        WHERE di.interaction_description IS NOT NULL
    """
    c_dd.execute(sql_ddi)
    rows = c_dd.fetchall()
    print(f"📦 Found {len(rows):,} DDIs. Inserting into mediswitch.db...")
    
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

            data_to_insert.append((r[0], r[1], r[2], r[3], 'DDInter', r[4], mech_text, r[4], r[2], 'pharmacodynamic', 0))
        c_ms.executemany(insert_sql, data_to_insert)

    # 2. Update disease_interactions (Linked to local IDs)
    print("\n🚀 Processing Disease Interactions with ID Mapping...")
    c_ms.execute("DELETE FROM disease_interactions")
    c_dd.execute("""
        SELECT d.drug_name, di.disease_name, di.severity, di.interaction_text
        FROM drug_disease_interactions di
        JOIN drugs d ON di.drug_id = d.ddinter_id
    """)
    dis_rows = c_dd.fetchall()
    
    dis_insert_sql = """
        INSERT INTO disease_interactions (
            med_id, trade_name, disease_name, interaction_text, severity, source, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
    """
    
    disease_data = []
    linked_count = 0
    for r in dis_rows:
        drug_name = r[0]
        drug_name_clean = drug_name.strip().lower()
        if drug_name_clean in local_drug_map:
            for local_id in local_drug_map[drug_name_clean]:
                disease_data.append((local_id, drug_name, r[1], r[3], r[2], 'DDInter', 0))
            linked_count += 1
        else:
            disease_data.append((0, drug_name, r[1], r[3], r[2], 'DDInter', 0))

    c_ms.executemany(dis_insert_sql, disease_data)
    print(f"✅ Inserted {len(disease_data):,} records. Successfully linked {linked_count:,}/{len(dis_rows):,} DDInter drugs to local database.")

    # 3. Update food_interactions (Linked to local IDs)
    print("\n🍎 Processing Food Interactions with ID Mapping...")
    c_ms.execute("DELETE FROM food_interactions")
    c_dd.execute("""
        SELECT d.drug_name, fi.food_name, fi.severity, fi.description, fi.management_text
        FROM drug_food_interactions fi
        JOIN drugs d ON fi.drug_id = d.ddinter_id
    """)
    food_rows = c_dd.fetchall()
    
    food_insert_sql = """
        INSERT INTO food_interactions (
            med_id, interaction_text, source, created_at
        ) VALUES (?, ?, ?, ?)
    """
    
    food_data = []
    f_linked_count = 0
    for r in food_rows:
        drug_name = r[0]
        drug_name_clean = drug_name.strip().lower()
        full_text = f"Food: {r[1]}\nSeverity: {r[2]}\n{r[3]}\nManagement: {r[4]}"
        
        if drug_name_clean in local_drug_map:
            for local_id in local_drug_map[drug_name_clean]:
                food_data.append((local_id, full_text, 'DDInter', 0))
            f_linked_count += 1
        else:
            food_data.append((0, full_text, 'DDInter', 0))

    c_ms.executemany(food_insert_sql, food_data)
    print(f"✅ Inserted {len(food_data):,} records. Successfully linked {f_linked_count:,}/{len(food_rows):,} DDInter drugs to local database.")

    conn_ms.commit()
    conn_dd.close()
    conn_ms.close()
    print("\n🎉 Mediswitch.db updated successfully with full DDInter data!")

if __name__ == "__main__":
    update_mediswitch()
