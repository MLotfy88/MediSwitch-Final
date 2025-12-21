#!/usr/bin/env python3
"""
Phase 3: Import Food Interactions
==================================
Create food_interactions table and import data from DrugBank.
"""

import csv
import sqlite3
from pathlib import Path


def create_food_interactions_table(db_path: str):
    """Create the food_interactions table."""
    print("🔧 Creating food_interactions table...")
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Create table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS food_interactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            med_id INTEGER NOT NULL,
            interaction_text TEXT NOT NULL,
            source TEXT DEFAULT 'DrugBank',
            created_at INTEGER DEFAULT (strftime('%s', 'now')),
            FOREIGN KEY (med_id) REFERENCES drugs(id) ON DELETE CASCADE
        )
    """)
    
    # Create index
    cursor.execute("""
        CREATE INDEX IF NOT EXISTS idx_food_interactions_med_id 
        ON food_interactions(med_id)
    """)
    
    conn.commit()
    conn.close()
    
    print("✅ Table and index created successfully!\n")


def load_drugbank_food_interactions(food_interactions_csv: str):
    """Load food interactions from DrugBank CSV."""
    print(f"📚 Loading DrugBank food interactions from {food_interactions_csv}...")
    
    food_interactions = {}  # drugbank_id -> [interactions]
    
    try:
        with open(food_interactions_csv, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                db_id = row.get('drugbank_id', '')
                interaction = row.get('food_interaction', '')
                
                if db_id and interaction:
                    if db_id not in food_interactions:
                        food_interactions[db_id] = []
                    food_interactions[db_id].append(interaction)
        
        print(f"✅ Loaded food interactions for {len(food_interactions)} DrugBank drugs\n")
    except Exception as e:
        print(f"❌ Error loading food interactions: {e}")
    
    return food_interactions


def import_food_interactions(db_path: str, matched_csv: str, food_interactions_csv: str):
    """Import food interactions based on matched drugs."""
    print("📥 Importing food interactions...")
    
    # Load DrugBank food interactions
    drugbank_food = load_drugbank_food_interactions(food_interactions_csv)
    
    # Load matched drugs
    with open(matched_csv, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        matches = list(reader)
    
    print(f"   Processing {len(matches)} matched drugs...")
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    imported_count = 0
    total_interactions = 0
    
    for match in matches:
        dailymed_id = match['dailymed_id']
        drugbank_id = match['drugbank_id']
        
        # Get food interactions for this DrugBank drug
        if drugbank_id in drugbank_food:
            interactions = drugbank_food[drugbank_id]
            
            for interaction_text in interactions:
                cursor.execute("""
                    INSERT INTO food_interactions (med_id, interaction_text, source)
                    VALUES (?, ?, 'DrugBank')
                """, (dailymed_id, interaction_text))
                
                total_interactions += 1
            
            imported_count += 1
    
    conn.commit()
    conn.close()
    
    print(f"✅ Food interactions import complete!")
    print(f"   Drugs with food interactions: {imported_count}")
    print(f"   Total interactions imported: {total_interactions}\n")
    
    return imported_count, total_interactions


def verify_food_interactions(db_path: str):
    """Verify the food interactions import."""
    print("🔍 Verifying food interactions...")
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Count total interactions
    cursor.execute("SELECT COUNT(*) FROM food_interactions")
    total_count = cursor.fetchone()[0]
    
    # Count drugs with food interactions
    cursor.execute("""
        SELECT COUNT(DISTINCT med_id) 
        FROM food_interactions
    """)
    drug_count = cursor.fetchone()[0]
    
    # Get samples
    cursor.execute("""
        SELECT d.tradeName, d.active, f.interaction_text
        FROM food_interactions f
        JOIN drugs d ON d.id = f.med_id
        LIMIT 10
    """)
    samples = cursor.fetchall()
    
    conn.close()
    
    print(f"✅ Verification complete!")
    print(f"   Total food interactions: {total_count}")
    print(f"   Drugs with interactions: {drug_count}")
    
    print(f"\n📋 Sample food interactions:")
    print("="*80)
    for trade_name, active, interaction in samples:
        print(f"   • {trade_name} ({active})")
        print(f"     ⚠️ {interaction}\n")


def main():
    """Main execution."""
    print("🚀 Phase 3: Import Food Interactions")
    print("="*80 + "\n")
    
    db_path = "/home/adminlotfy/project/mediswitch.db"
    matched_csv = "/home/adminlotfy/project/scripts/drugbank_integration/output/matched_drugs.csv"
    food_interactions_csv = "/home/adminlotfy/project/DrugBank_Organized_Data/data/drugs/food_interactions.csv"
    
    # Step 1: Create table
    create_food_interactions_table(db_path)
    
    # Step 2: Import data
    imported_count, total_interactions = import_food_interactions(
        db_path, matched_csv, food_interactions_csv
    )
    
    # Step 3: Verify
    verify_food_interactions(db_path)
    
    print("="*80)
    print("✅ Food interactions import completed successfully!")
    print(f"   Drugs updated: {imported_count}")
    print(f"   Total interactions: {total_interactions}")


if __name__ == "__main__":
    main()
