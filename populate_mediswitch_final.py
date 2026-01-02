import sqlite3
import os
import json
import re
import time

# Paths
DDINTER_DB = "assets/external_research_data/ddinter_complete.db"
MEDISWITCH_DB = "mediswitch.db"
BATCH_SIZE = 5000 # Increased for speed but memory-safe

def clean_name(name):
    if not name: return ""
    name = re.sub(r'\(.*?\)', '', name)
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
    
    # CRITICAL: Optimization for huge DBs on limited memory
    conn_ms.execute("PRAGMA journal_mode = OFF") # Minimal disk/memory overhead
    conn_ms.execute("PRAGMA synchronous = OFF")
    conn_ms.execute("PRAGMA cache_size = -1000000") # Use ~1GB RAM for cache if available
    conn_ms.execute("PRAGMA temp_store = MEMORY")
    
    c_dd = conn_dd.cursor()
    c_ms = conn_ms.cursor()

    # --- ID Mapping Logic ---
    print("🧠 Building Ingredient Memory Map...")
    c_ms.execute("SELECT id, active FROM drugs WHERE active IS NOT NULL")
    local_drug_map = {}
    for local_id, active in c_ms.fetchall():
        cleaned = clean_name(active)
        if cleaned not in local_drug_map:
            local_drug_map[cleaned] = []
        local_drug_map[cleaned].append(local_id)
    
    print(f"✅ Loaded {len(local_drug_map):,} ingredients.")

    # --- 1. Enrich Drugs Table ---
    print("\n💊 Enriching Drugs metadata (Streaming)...")
    c_dd.execute("SELECT drug_name, description, atc_codes, external_links FROM drugs")
    
    e_count = 0
    while True:
        batch = c_dd.fetchmany(BATCH_SIZE)
        if not batch: break
        for drug_name, desc, atc, links in batch:
            cleaned = clean_name(drug_name)
            if cleaned in local_drug_map:
                for local_id in local_drug_map[cleaned]:
                    c_ms.execute("UPDATE drugs SET description = ?, atc_codes = ?, external_links = ? WHERE id = ?", (desc, atc, links, local_id))
                    e_count += 1
        conn_ms.commit() # Periodic flush
    print(f"✅ Enriched {e_count:,} drug instances.")

    # --- 2. Drug-Drug Interactions ---
    print("\n🧪 Rebuilding drug_interactions (DROP + CREATE)...")
    c_ms.execute("DROP TABLE IF EXISTS drug_interactions")
    c_ms.execute("""
    CREATE TABLE drug_interactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ingredient1 TEXT, ingredient2 TEXT, severity TEXT, effect TEXT, source TEXT, 
        management_text TEXT, mechanism_text TEXT, recommendation TEXT, risk_level TEXT, type TEXT,
        metabolism_info TEXT, source_url TEXT, reference_text TEXT, alternatives_a TEXT, alternatives_b TEXT, updated_at INTEGER DEFAULT 0
    )
    """)
    c_ms.execute("CREATE INDEX idx_rules_pair ON drug_interactions(ingredient1, ingredient2)")

    sql_ddi = """
        SELECT d1.drug_name, d2.drug_name, di.severity, di.interaction_description, 
               di.management_text, di.mechanism_flags, di.metabolism_info, 
               di.source_url, di.reference_text, di.alternative_drugs_a, di.alternative_drugs_b
        FROM drug_drug_interactions di
        JOIN drugs d1 ON di.drug_a_id = d1.ddinter_id
        JOIN drugs d2 ON di.drug_b_id = d2.ddinter_id
    """
    c_dd.execute(sql_ddi)
    
    insert_sql = "INSERT INTO drug_interactions (ingredient1, ingredient2, severity, effect, source, management_text, mechanism_text, recommendation, risk_level, type, metabolism_info, source_url, reference_text, alternatives_a, alternatives_b, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
    
    ddi_count = 0
    now = int(time.time())
    while True:
        batch = c_dd.fetchmany(BATCH_SIZE)
        if not batch: break
        
        insert_data = []
        for r in batch:
            mech = ""
            if r[5]:
                try: 
                    m = json.loads(r[5])
                    if m: mech = ", ".join(m)
                except: pass
            
            alts_a = ""
            if r[9]:
                try: 
                    alts_list = json.loads(r[9])
                    if alts_list: alts_a = ", ".join(alts_list)
                except: alts_a = str(r[9])
            
            alts_b = ""
            if r[10]:
                try: 
                    alts_list = json.loads(r[10])
                    if alts_list: alts_b = ", ".join(alts_list)
                except: alts_b = str(r[10])

            mgmt = r[4] or ""
            reco = mgmt.split(".")[0].strip() + "." if "." in mgmt else mgmt
            
            insert_data.append((r[0], r[1], r[2], r[3], 'DDInter', mgmt, mech, reco, r[2], 'pharmacodynamic', r[6], r[7], r[8], alts_a, alts_b, now))
        
        c_ms.executemany(insert_sql, insert_data)
        conn_ms.commit()
        ddi_count += len(insert_data)
        print(f"   ... Processed {ddi_count:,} DDIs")
    
    # --- 3. Disease Interactions ---
    print("\n🚀 Rebuilding disease_interactions...")
    c_ms.execute("DROP TABLE IF EXISTS disease_interactions")
    c_ms.execute("""
    CREATE TABLE disease_interactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        med_id INTEGER NOT NULL, trade_name TEXT, disease_name TEXT NOT NULL, interaction_text TEXT NOT NULL, 
        severity TEXT, reference_text TEXT, source TEXT DEFAULT 'DDInter', created_at INTEGER DEFAULT 0
    )
    """)
    c_ms.execute("CREATE INDEX idx_disease_med_id ON disease_interactions(med_id)")

    c_dd.execute("SELECT d.drug_name, di.disease_name, di.severity, di.interaction_text, di.reference_text FROM drug_disease_interactions di JOIN drugs d ON di.drug_id = d.ddinter_id")
    
    dis_count = 0
    while True:
        batch = c_dd.fetchmany(BATCH_SIZE)
        if not batch: break
        insert_data = []
        for r in batch:
            drug_name = r[0]
            cleaned = clean_name(drug_name)
            matched = local_drug_map.get(cleaned, [])
            if not matched and len(cleaned) >= 4:
                for l_clean, ids in local_drug_map.items():
                    if len(l_clean) >= 4 and (cleaned in l_clean or l_clean in cleaned):
                        matched = ids
                        break
            if matched:
                for local_id in matched: insert_data.append((local_id, drug_name, r[1], r[3], r[2], r[4], 'DDInter', 0))
            else:
                insert_data.append((0, drug_name, r[1], r[3], r[2], r[4], 'DDInter', 0))
        c_ms.executemany("INSERT INTO disease_interactions (med_id, trade_name, disease_name, interaction_text, severity, reference_text, source, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)", insert_data)
        conn_ms.commit()
        dis_count += len(insert_data)
    print(f"✅ Total Disease Interactions: {dis_count:,}")

    # --- 4. Food Interactions ---
    print("\n🍎 Rebuilding food_interactions...")
    c_ms.execute("DROP TABLE IF EXISTS food_interactions")
    c_ms.execute("""
    CREATE TABLE food_interactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT, med_id INTEGER NOT NULL, trade_name TEXT, interaction TEXT NOT NULL, 
        ingredient TEXT, severity TEXT, management_text TEXT, mechanism_text TEXT, reference_text TEXT, 
        source TEXT DEFAULT 'DrugBank', created_at INTEGER DEFAULT 0
    )
    """)
    c_ms.execute("CREATE INDEX idx_food_med_id ON food_interactions(med_id)")

    c_dd.execute("SELECT d.drug_name, fi.food_name, fi.severity, fi.description, fi.management_text, fi.mechanism_flags, fi.reference_text FROM drug_food_interactions fi JOIN drugs d ON fi.drug_id = d.ddinter_id")
    
    f_count = 0
    while True:
        batch = c_dd.fetchmany(BATCH_SIZE)
        if not batch: break
        insert_data = []
        for r in batch:
            drug_name, food_name, severity, desc, mgmt, mech_f, refs = r
            cleaned = clean_name(drug_name)
            mech_t = ""
            if mech_f:
                try:
                    m = json.loads(mech_f)
                    if m: mech_t = ", ".join(m)
                except: mech_t = str(mech_f)
            
            matched = local_drug_map.get(cleaned, [])
            if not matched and len(cleaned) >= 4:
                for l_clean, ids in local_drug_map.items():
                    if len(l_clean) >= 4 and (cleaned in l_clean or l_clean in cleaned):
                        matched = ids
                        break
            if matched:
                for local_id in matched: insert_data.append((local_id, drug_name, desc or "", food_name, severity, mgmt, mech_t, refs, 'DDInter', 0))
            else:
                insert_data.append((0, drug_name, desc or "", food_name, severity, mgmt, mech_t, refs, 'DDInter', 0))
        c_ms.executemany("INSERT INTO food_interactions (med_id, trade_name, interaction, ingredient, severity, management_text, mechanism_text, reference_text, source, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", insert_data)
        conn_ms.commit()
        f_count += len(insert_data)
    print(f"✅ Total Food Interactions: {f_count:,}")

    conn_dd.close()
    conn_ms.close()
    print("\n🎉 Mediswitch.db REBUILT successfully (Lightning Fast & Stable)!")

if __name__ == "__main__":
    update_mediswitch()
