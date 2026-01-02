import sqlite3
import os

DB_PATH = "mediswitch.db"

def verify_samples():
    if not os.path.exists(DB_PATH):
        print(f"❌ Database not found at {DB_PATH}")
        return

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    def print_section(title, query):
        print(f"\n{'='*100}")
        print(f"🔍 {title}")
        print(f"{'='*100}")
        cursor.execute(query)
        columns = [description[0] for description in cursor.description]
        rows = cursor.fetchall()
        for i, row in enumerate(rows, 1):
            print(f"\n📌 Sample #{i}:")
            for col, val in zip(columns, row):
                # Truncate long text for readability
                val_str = str(val)
                if len(val_str) > 200:
                    val_str = val_str[:197] + "..."
                print(f"  {col:<20} : {val_str}")

    # 1. Drug-Drug Interactions
    print_section("Drug-Drug Interactions (Sample)", """
        SELECT ingredient1, ingredient2, severity, effect, management_text, mechanism_text, recommendation
        FROM drug_interactions 
        ORDER BY RANDOM() 
        LIMIT 3
    """)

    # 2. Disease Interactions
    print_section("Disease Interactions (Sample)", """
        SELECT di.trade_name, d.tradeName as local_trade_name, di.disease_name, di.severity, di.interaction_text, di.med_id
        FROM disease_interactions di
        LEFT JOIN drugs d ON di.med_id = d.id
        WHERE di.med_id > 0
        ORDER BY RANDOM() 
        LIMIT 3
    """)

    # 3. Food Interactions
    print_section("Food Interactions (Sample)", """
        SELECT d.tradeName as local_trade_name, fi.interaction_text, fi.med_id
        FROM food_interactions fi
        JOIN drugs d ON fi.med_id = d.id
        WHERE fi.med_id > 0
        ORDER BY RANDOM() 
        LIMIT 3
    """)

    conn.close()

if __name__ == "__main__":
    verify_samples()
