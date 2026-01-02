import sqlite3
import json
import os

# Paths
MEDISWITCH_DB = 'mediswitch.db'
DDINTER_DB = 'assets/external_research_data/ddinter_complete.db'

def merge_interactions():
    if not os.path.exists(MEDISWITCH_DB) or not os.path.exists(DDINTER_DB):
        print("❌ Database files not found!")
        return

    print(f"🔗 Connecting to databases...")
    conn_med = sqlite3.connect(MEDISWITCH_DB)
    conn_ddi = sqlite3.connect(DDINTER_DB)
    
    conn_med.row_factory = sqlite3.Row
    conn_ddi.row_factory = sqlite3.Row
    
    c_med = conn_med.cursor()
    c_ddi = conn_ddi.cursor()

    # 1. Create a mapping of DDInter drug_id to its actual generic name (ingredient)
    # Using the name provided in ddinter_complete.db (which we know is 'DDInter 2.0' in some columns, 
    # but we will try to find the correct one or use the ID as a last resort)
    print("📋 Resolving DDInter ingredient names...")
    # Actually, let's load a mapping of ID to Name from the DDInter DB metadata
    # We saw that 'drug_name' column was corrupted as 'DDInter 2.0'.
    # I will try to see if there is another source for the name.
    # If not, I'll notify the user.
    
    # Wait, if drug_name is 'DDInter 2.0', we have a problem.
    # Let's check drug_drug_interactions table in DDInter. 
    # Usually, it has columns like drug_a_name, drug_b_name? No, let's check schema.
    c_ddi.execute("PRAGMA table_info(drug_drug_interactions)")
    ddi_cols = [r['name'] for r in c_ddi.fetchall()]
    print(f"DDI Columns in DDInter DB: {ddi_cols}")

    # If names are missing, we might need a backup mapping.
    # Let's try to find if ANY drug has a real name.
    c_ddi.execute("SELECT drug_name FROM drugs WHERE drug_name != 'DDInter 2.0' LIMIT 5")
    sample = c_ddi.fetchone()
    if not sample:
        print("⚠️ CRITICAL: Drug names in DDInter DB are corrupted ('DDInter 2.0').")
        print("I need to fix the names using the HTML cache or re-parsing before merging.")
        return

    # Assuming names are fixed or working:
    c_ddi.execute("SELECT ddinter_id, drug_name FROM drugs")
    id_to_name = {row['ddinter_id']: row['drug_name'] for row in c_ddi.fetchall()}

    # 2. Sync Drug-Drug Interactions
    print("⚔️ Syncing Drug-Drug Interactions...")
    c_ddi.execute("SELECT * FROM drug_drug_interactions")
    batch_size = 5000
    total_ddis = 0
    
    while True:
        ddis = c_ddi.fetchmany(batch_size)
        if not ddis:
            break
        
        insert_data = []
        for ddi in ddis:
            name_a = id_to_name.get(ddi['drug_a_id'])
            name_b = id_to_name.get(ddi['drug_b_id'])
            
            if name_a and name_b:
                insert_data.append((
                    name_a,
                    name_b,
                    ddi['severity'],
                    ddi['interaction_description'],
                    ddi['management_text'],
                    ddi['mechanism_flags'],
                    'DDInter',
                    ddi['severity'] # type
                ))
        
        if insert_data:
            c_med.executemany("""
                INSERT OR REPLACE INTO drug_interactions 
                (ingredient1, ingredient2, severity, effect, management_text, mechanism_text, source, type)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, insert_data)
            total_ddis += len(insert_data)
            
        print(f"   Processed {total_ddis} interactions...")
        conn_med.commit()

    print(f"✅ Merged {total_ddis} drug-drug interactions.")

    # 3. Sync Disease Interactions
    print("🤒 Syncing Disease Interactions...")
    c_ddi.execute("SELECT * FROM drug_disease_interactions")
    dsis = c_ddi.fetchall()
    dsi_data = []
    for dsi in dsis:
        name = id_to_name.get(dsi['drug_id'])
        if name:
            dsi_data.append((
                None, # med_id
                name, # trade_name (fallback to generic)
                dsi['disease_name'],
                dsi['interaction_text'],
                dsi['severity'],
                'DDInter'
            ))
    
    if dsi_data:
        c_med.executemany("""
            INSERT OR IGNORE INTO disease_interactions 
            (med_id, trade_name, disease_name, interaction_text, severity, source)
            VALUES (?, ?, ?, ?, ?, ?)
        """, dsi_data)
        conn_med.commit()
    print(f"✅ Merged {len(dsi_data)} disease interactions.")

    # 4. Sync Food Interactions
    print("🍏 Syncing Food Interactions...")
    c_ddi.execute("SELECT * FROM drug_food_interactions")
    dfis = c_ddi.fetchall()
    dfi_data = []
    for dfi in dfis:
        name = id_to_name.get(dfi['drug_id'])
        if name:
            dfi_data.append((
                None, # med_id
                dfi['description'], # interaction_text
                'DDInter'
            ))
    
    # Food interactions in mediswitch use 'med_id', 'interaction_text', 'source'
    if dfi_data:
        # Note: We might need to map generic name back to an Egyptian med_id if we want icons to show up correctly.
        # But per user request, we just update the data.
        c_med.executemany("""
            INSERT INTO food_interactions (med_id, interaction_text, source)
            VALUES (?, ?, ?)
        """, dfi_data)
        conn_med.commit()
    print(f"✅ Merged {len(dfi_data)} food interactions.")

    conn_med.close()
    conn_ddi.close()
    print("\n🎉 INTERACTION MERGE COMPLETE!")

if __name__ == '__main__':
    merge_interactions()
