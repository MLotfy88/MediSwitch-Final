#!/usr/bin/env python3
"""
Update meds.csv with DrugBank pharmacology data
================================================
Updates the pharmacology column in meds.csv with data from matched_drugs.csv
"""

import csv
import sqlite3
from pathlib import Path


def load_matched_pharmacology():
    """Load pharmacology data from matched drugs."""
    matched_file = "/home/adminlotfy/project/scripts/drugbank_integration/output/matched_drugs.csv"
    
    pharmacology_map = {}  # drug_id -> indication text
    
    with open(matched_file, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            drug_id = row['dailymed_id']
            indication = row['indication']
            
            # Use indication as the main pharmacology text
            if indication:
                pharmacology_map[drug_id] = indication
    
    print(f"✅ Loaded pharmacology for {len(pharmacology_map)} drugs")
    return pharmacology_map


def update_csv_with_pharmacology(csv_path: str, pharmacology_map: dict):
    """Update meds.csv with pharmacology data."""
    
    # Read current CSV
    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames
        rows = list(reader)
    
    print(f"📋 Found {len(rows)} rows in meds.csv")
    
    # Update rows
    updated_count = 0
    
    for row in rows:
        drug_id = row.get('id', '')
        
        if drug_id in pharmacology_map:
            # Update pharmacology column
            row['pharmacology'] = pharmacology_map[drug_id]
            updated_count += 1
    
    # Write back
    backup_path = csv_path + '.backup_before_drugbank'
    print(f"💾 Creating backup at {backup_path}...")
    
    import shutil
    shutil.copy2(csv_path, backup_path)
    
    with open(csv_path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    
    print(f"✅ Updated {updated_count} rows in meds.csv")
    return updated_count


def create_food_interactions_json():
    """Create food_interactions.json for future use."""
    import json
    
    db_path = "/home/adminlotfy/project/mediswitch.db"
    output_file = "/home/adminlotfy/project/assets/data/food_interactions.json"
    
    # Create directory if needed
    Path(output_file).parent.mkdir(parents=True, exist_ok=True)
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    cursor.execute("""
        SELECT f.med_id, d.tradeName, f.interaction_text
        FROM food_interactions f
        JOIN drugs d ON d.id = f.med_id
    """)
    
    interactions = []
    for med_id, trade_name, interaction_text in cursor.fetchall():
        interactions.append({
            "med_id": med_id,
            "trade_name": trade_name,
            "interaction": interaction_text,
            "source": "DrugBank"
        })
    
    conn.close()
    
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(interactions, f, ensure_ascii=False, indent=2)
    
    print(f"✅ Created {output_file} with {len(interactions)} interactions")


def main():
    """Main execution."""
    print("🚀 Update Source Files with DrugBank Data")
    print("="*80)
    
    csv_path = "/home/adminlotfy/project/assets/meds.csv"
    
    # Step 1: Load pharmacology data
    print("\n📚 Step 1: Loading pharmacology data...")
    pharmacology_map = load_matched_pharmacology()
    
    # Step 2: Update CSV
    print("\n📝 Step 2: Updating meds.csv...")
    updated_count = update_csv_with_pharmacology(csv_path, pharmacology_map)
    
    # Step 3: Create food interactions JSON
    print("\n🍽️  Step 3: Creating food_interactions.json...")
    create_food_interactions_json()
    
    print("\n" + "="*80)
    print("✅ Source files updated successfully!")
    print(f"   - meds.csv: {updated_count} drugs updated")
    print(f"   - food_interactions.json: created")
    print("\n⚠️  Next steps:")
    print("   1. Re-seed local database from CSV")
    print("   2. Export to D1 using export_to_d1.py")


if __name__ == "__main__":
    main()
