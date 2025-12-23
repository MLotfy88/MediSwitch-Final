#!/usr/bin/env python3
import json
import os

def export_food_interactions_to_sql(json_file, output_file):
    if not os.path.exists(json_file):
        print(f"❌ File not found: {json_file}")
        return False

    print(f"📖 Reading food interactions from {json_file}...")
    with open(json_file, 'r', encoding='utf-8') as f:
        try:
            data = json.load(f)
            # Support both list and {data: []} format
            if isinstance(data, dict):
                records = data.get('data', data.get('food_interactions', []))
            else:
                records = data
        except Exception as e:
            print(f"❌ Error parsing JSON: {e}")
            return False

    total = len(records)
    print(f"📊 Found {total} food interaction records.")

    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("-- MediSwitch Food Interactions Export\n")
        f.write("DROP TABLE IF EXISTS food_interactions;\n")
        f.write("""CREATE TABLE food_interactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    med_id INTEGER NOT NULL,
    trade_name TEXT,
    interaction TEXT NOT NULL,
    source TEXT DEFAULT 'DrugBank',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);\n\n""")

        batch = []
        for r in records:
            mid = r.get('med_id', 0)
            name = str(r.get('trade_name', '')).replace("'", "''")
            text = str(r.get('interaction', '')).replace("'", "''")
            src = str(r.get('source', 'DrugBank')).replace("'", "''")
            
            batch.append(f"({mid}, '{name}', '{text}', '{src}')")
            
            if len(batch) >= 100:
                f.write("INSERT INTO food_interactions (med_id, trade_name, interaction, source) VALUES\n")
                f.write(",\n".join(batch))
                f.write(";\n")
                batch = []
        
        if batch:
            f.write("INSERT INTO food_interactions (med_id, trade_name, interaction, source) VALUES\n")
            f.write(",\n".join(batch))
            f.write(";\n")

    print(f"✅ Generated {output_file}")
    return True

if __name__ == "__main__":
    export_food_interactions_to_sql('assets/data/food_interactions.json', 'd1_food_interactions.sql')
