#!/usr/bin/env python3
"""
Export food_interactions.json to SQL for D1
"""

import json
from pathlib import Path


def export_food_interactions():
    """Export food interactions to SQL."""
    json_file = "/home/adminlotfy/project/assets/data/food_interactions.json"
    output_file = "/home/adminlotfy/project/d1_food_interactions.sql"
    
    print(f"📖 Reading {json_file}...")
    
    with open(json_file, 'r', encoding='utf-8') as f:
        interactions = json.load(f)
    
    print(f"📊 Found {len(interactions)} food interactions")
    
    with open(output_file, 'w', encoding='utf-8') as f:
        # Schema
        f.write("-- Food Interactions for D1\n\n")
        f.write("CREATE TABLE IF NOT EXISTS food_interactions (\n")
        f.write("  id INTEGER PRIMARY KEY AUTOINCREMENT,\n")
        f.write("  med_id INTEGER NOT NULL,\n")
        f.write("  interaction_text TEXT NOT NULL,\n")
        f.write("  source TEXT DEFAULT 'DrugBank',\n")
        f.write("  created_at INTEGER DEFAULT (strftime('%s', 'now'))\n")
        f.write(");\n\n")
        
        f.write("CREATE INDEX IF NOT EXISTS idx_food_interactions_med_id ON food_interactions(med_id);\n\n")
        
        # Data
        for item in interactions:
            med_id = item['med_id']
            interaction = item['interaction'].replace("'", "''")
            
            f.write(f"INSERT INTO food_interactions (med_id, interaction_text, source) ")
            f.write(f"VALUES ({med_id}, '{interaction}', 'DrugBank');\n")
    
    print(f"✅ Exported to {output_file}")
    print(f"   File size: {Path(output_file).stat().st_size / 1024:.2f} KB")


if __name__ == "__main__":
    export_food_interactions()
