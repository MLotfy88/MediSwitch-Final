import sqlite3
import os

# Source (Correct Names)
SRC_DB = "assets/external_research_data/updated/ddinter_complete.db"
# Target (Complete Interactions)
TGT_DB = "assets/external_research_data/ddinter_complete.db"

def sync_names():
    if not os.path.exists(SRC_DB) or not os.path.exists(TGT_DB):
        print("❌ Database files not found!")
        return

    print("🔗 Connecting...")
    conn_src = sqlite3.connect(SRC_DB)
    conn_tgt = sqlite3.connect(TGT_DB)
    
    c_src = conn_src.cursor()
    c_tgt = conn_tgt.cursor()

    print("📋 Fetching correct names from source...")
    c_src.execute("SELECT ddinter_id, drug_name FROM drugs")
    src_data = c_src.fetchall()
    
    print(f"🔄 Updating {len(src_data)} records in target...")
    updated = 0
    for dd_id, name in src_data:
        c_tgt.execute("UPDATE drugs SET drug_name = ? WHERE ddinter_id = ?", (name, dd_id))
        if c_tgt.rowcount > 0:
            updated += 1
    
    conn_tgt.commit()
    print(f"✅ Successfully updated {updated} drug names.")
    
    conn_src.close()
    conn_tgt.close()

if __name__ == "__main__":
    sync_names()
