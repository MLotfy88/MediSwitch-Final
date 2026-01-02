import sqlite3
import json
import os

DB_PATH = "mediswitch.db"
FOOD_JSON = "assets/data/interactions/enriched/enriched_food_interactions.json"
DOSAGE_JSON = "assets/data/dosage_guidelines.json"

def export_assets():
    if not os.path.exists(DB_PATH):
        print(f"❌ Database not found: {DB_PATH}")
        return

    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    # 1. Export Food Interactions
    print("🍎 Exporting Food Interactions...")
    cursor.execute("SELECT med_id, trade_name, interaction, ingredient, severity, management_text, mechanism_text, reference_text, source FROM food_interactions")
    food_rows = [dict(row) for row in cursor.fetchall()]
    
    os.makedirs(os.path.dirname(FOOD_JSON), exist_ok=True)
    with open(FOOD_JSON, 'w', encoding='utf-8') as f:
        json.dump(food_rows, f, ensure_ascii=False, indent=2)
    print(f"   ✅ Exported {len(food_rows)} food interactions to {FOOD_JSON}")

    # 2. Export Dosage Guidelines
    print("💊 Exporting Dosage Guidelines...")
    cursor.execute("SELECT med_id, dailymed_setid, min_dose, max_dose, frequency, duration, instructions, condition, source, is_pediatric FROM dosage_guidelines")
    dosage_rows = [dict(row) for row in cursor.fetchall()]
    
    os.makedirs(os.path.dirname(DOSAGE_JSON), exist_ok=True)
    with open(DOSAGE_JSON, 'w', encoding='utf-8') as f:
        # Note: We export as a simple list to match the app's expectation (fixing the crash)
        json.dump(dosage_rows, f, ensure_ascii=False, indent=2)
    print(f"   ✅ Exported {len(dosage_rows)} dosage records to {DOSAGE_JSON}")

    conn.close()
    print("\n✨ Assets synchronized with Mediswitch.db!")

if __name__ == "__main__":
    export_assets()
