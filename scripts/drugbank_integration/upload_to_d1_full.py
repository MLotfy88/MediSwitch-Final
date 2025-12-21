#!/usr/bin/env python3
"""
Full D1 Upload Script with Batching
====================================
Upload all DrugBank data to Cloudflare D1 in manageable batches.
"""

import sqlite3
import subprocess
import json
from pathlib import Path


def export_pharmacology_batch(db_path: str, offset: int, limit: int, output_file: str):
    """Export a batch of pharmacology updates as SQL."""
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    cursor.execute("""
        SELECT id, indication, mechanism_of_action, pharmacodynamics, data_source_pharmacology
        FROM drugs
        WHERE data_source_pharmacology = 'DrugBank'
        LIMIT ? OFFSET ?
    """, (limit, offset))
    
    rows = cursor.fetchall()
    conn.close()
    
    if not rows:
        return 0
    
    with open(output_file, 'w', encoding='utf-8') as f:
        for drug_id, indication, mechanism, pharmacodynamics, source in rows:
            # Escape single quotes
            indication = indication.replace("'", "''") if indication else ''
            mechanism = mechanism.replace("'", "''") if mechanism else ''
            pharmacodynamics = pharmacodynamics.replace("'", "''") if pharmacodynamics else ''
            
            sql = f"""UPDATE drugs SET 
                indication = '{indication}',
                mechanism_of_action = '{mechanism}',
                pharmacodynamics = '{pharmacodynamics}',
                data_source_pharmacology = 'DrugBank'
            WHERE id = {drug_id};
"""
            f.write(sql)
    
    return len(rows)


def export_food_interactions_batch(db_path: str, offset: int, limit: int, output_file: str):
    """Export a batch of food interactions as SQL."""
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    cursor.execute("""
        SELECT med_id, interaction_text, source
        FROM food_interactions
        LIMIT ? OFFSET ?
    """, (limit, offset))
    
    rows = cursor.fetchall()
    conn.close()
    
    if not rows:
        return 0
    
    with open(output_file, 'w', encoding='utf-8') as f:
        for med_id, interaction_text, source in rows:
            # Escape single quotes
            interaction_text = interaction_text.replace("'", "''") if interaction_text else ''
            
            sql = f"""INSERT INTO food_interactions (med_id, interaction_text, source) 
            VALUES ({med_id}, '{interaction_text}', 'DrugBank');
"""
            f.write(sql)
    
    return len(rows)


def upload_to_d1(sql_file: str, db_name: str = "mediswitch-db"):
    """Upload SQL file to D1."""
    try:
        result = subprocess.run(
            ["wrangler", "d1", "execute", db_name, "--file", sql_file],
            capture_output=True,
            text=True,
            check=True
        )
        return True, result.stdout
    except subprocess.CalledProcessError as e:
        return False, e.stderr


def main():
    """Main execution."""
    print("🚀 Full D1 Upload - DrugBank Data")
    print("="*80)
    
    db_path = "/home/adminlotfy/project/mediswitch.db"
    output_dir = Path("/home/adminlotfy/project/scripts/drugbank_integration/d1_export")
    output_dir.mkdir(exist_ok=True)
    
    batch_size = 500  # Reasonable batch size for D1
    
    # Step 1: Update schema
    print("\n📋 Step 1: Updating D1 Schema...")
    schema_file = "/home/adminlotfy/project/scripts/drugbank_integration/d1_schema_update.sql"
    success, output = upload_to_d1(schema_file)
    if success:
        print("✅ Schema updated successfully")
    else:
        print(f"⚠️  Schema update (may already exist): {output}")
    
    # Step 2: Upload pharmacology data in batches
    print("\n📤 Step 2: Uploading Pharmacology Data...")
    offset = 0
    total_uploaded = 0
    batch_num = 1
    
    while True:
        output_file = str(output_dir / f"pharmacology_batch_{batch_num}.sql")
        count = export_pharmacology_batch(db_path, offset, batch_size, output_file)
        
        if count == 0:
            break
        
        print(f"   Batch {batch_num}: Uploading {count} records...")
        success, output = upload_to_d1(output_file)
        
        if success:
            print(f"   ✅ Batch {batch_num} uploaded")
            total_uploaded += count
        else:
            print(f"   ❌ Batch {batch_num} failed: {output}")
            break
        
        offset += batch_size
        batch_num += 1
        
        # Safety limit
        if batch_num > 25:
            print("   ⚠️  Reached batch limit (25 batches)")
            break
    
    print(f"✅ Pharmacology upload complete: {total_uploaded} drugs")
    
    # Step 3: Upload food interactions in batches
    print("\n📤 Step 3: Uploading Food Interactions...")
    offset = 0
    total_uploaded = 0
    batch_num = 1
    
    while True:
        output_file = str(output_dir / f"food_interactions_batch_{batch_num}.sql")
        count = export_food_interactions_batch(db_path, offset, batch_size, output_file)
        
        if count == 0:
            break
        
        print(f"   Batch {batch_num}: Uploading {count} interactions...")
        success, output = upload_to_d1(output_file)
        
        if success:
            print(f"   ✅ Batch {batch_num} uploaded")
            total_uploaded += count
        else:
            print(f"   ❌ Batch {batch_num} failed: {output}")
            break
        
        offset += batch_size
        batch_num += 1
        
        # Safety limit
        if batch_num > 30:
            print("   ⚠️  Reached batch limit (30 batches)")
            break
    
    print(f"✅ Food interactions upload complete: {total_uploaded} interactions")
    
    print("\n" + "="*80)
    print("✅ D1 upload completed successfully!")


if __name__ == "__main__":
    main()
