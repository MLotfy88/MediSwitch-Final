import sqlite3
import os
import shutil
from datetime import datetime

TARGET_DB = 'assets/database/mediswitch.db'
SOURCE_DB = 'temp_mediswitch_migration.db'

def backup_database():
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    backup_path = f"{TARGET_DB}.pre_merge_{timestamp}.bak"
    shutil.copy2(TARGET_DB, backup_path)
    print(f"✅ Created backup at: {backup_path}")

def migrate_schema(cursor):
    print("🔄 Checking and migrating schema...")
    
    # Define new columns with their types
    new_columns = {
        'min_dose': 'REAL',
        'max_dose': 'REAL',
        'dose_unit': 'TEXT',
        'frequency': 'REAL',
        'route': 'TEXT',
        'dosage_form': 'TEXT',
        'patient_category': 'TEXT',
        'is_geriatric': 'BOOLEAN',
        'is_pediatric': 'BOOLEAN',
        'is_pregnant': 'BOOLEAN',
        'renal_adjustment': 'TEXT',
        'hepatic_adjustment': 'TEXT',
        'warnings': 'TEXT',
        'contraindications': 'TEXT',
        'precautions': 'TEXT',
        'adverse_reactions': 'TEXT',
        'black_box_warning': 'TEXT',
        'drug_interactions_summary': 'TEXT',
        'monitoring_requirements': 'TEXT',
        'overdose_management': 'TEXT',
        'indication': 'TEXT',
        'mechanism_of_action': 'TEXT',
        'therapeutic_class': 'TEXT',
        'storage_conditions': 'TEXT',
        'max_daily_dose': 'REAL',
        'loading_dose': 'REAL',
        'maintenance_dose': 'REAL',
        'titration_info': 'TEXT',
        'special_populations': 'TEXT',
        'pregnancy_category': 'TEXT',
        'lactation_info': 'TEXT',
        'spl_version': 'TEXT',
        'data_completeness': 'TEXT',
        'confidence_score': 'REAL',
        'extraction_date': 'TEXT'
    }

    # Get existing columns
    cursor.execute("PRAGMA table_info(dosage_guidelines)")
    existing_columns = {row[1] for row in cursor.fetchall()}

    added_count = 0
    for col, dtype in new_columns.items():
        if col not in existing_columns:
            try:
                print(f"  Adding column: {col} ({dtype})")
                cursor.execute(f"ALTER TABLE dosage_guidelines ADD COLUMN {col} {dtype}")
                added_count += 1
            except sqlite3.OperationalError as e:
                print(f"  ⚠️ Error adding {col}: {e}")

    print(f"✅ Added {added_count} new columns.")

def merge_data(conn, cursor):
    print("\n🔄 Merging data from temporary database...")
    
    # Attach source database
    cursor.execute(f"ATTACH DATABASE '{SOURCE_DB}' AS source_db")
    
    # Get columns from source to ensure order match
    cursor.execute("PRAGMA source_db.table_info(dosage_guidelines)")
    source_cols = [row[1] for row in cursor.fetchall()]
    cols_str = ", ".join(source_cols)
    
    # Delete old data from same source to prevent duplicates
    print("🗑️  Removing old 'DailyMed SPL Enhanced' records...")
    cursor.execute("DELETE FROM dosage_guidelines WHERE source = 'DailyMed SPL Enhanced'")
    deleted = cursor.rowcount
    print(f"  - Deleted {deleted:,} old records.")
    
    # Insert new data
    print("📥 Inserting new records (this may take a minute)...")
    insert_sql = f"""
    INSERT INTO dosage_guidelines ({cols_str})
    SELECT {cols_str}
    FROM source_db.dosage_guidelines
    WHERE source = 'DailyMed SPL Enhanced'
    """
    
    try:
        cursor.execute(insert_sql)
        inserted = cursor.rowcount
        conn.commit()
        print(f"✅ Successfully inserted {inserted:,} records!")
    except Exception as e:
        print(f"❌ Error during insertion: {e}")
        conn.rollback()
        raise e
    finally:
        cursor.execute("DETACH DATABASE source_db")

def main():
    if not os.path.exists(TARGET_DB):
        print(f"❌ Target database not found: {TARGET_DB}")
        return
        
    if not os.path.exists(SOURCE_DB):
        print(f"❌ Source database not found: {SOURCE_DB}")
        return
        
    # backup_database() # We already did manual backup, but safe to keep function
    
    conn = sqlite3.connect(TARGET_DB)
    cursor = conn.cursor()
    
    try:
        migrate_schema(cursor)
        merge_data(conn, cursor)
        
        # Verify final count
        cursor.execute("SELECT COUNT(*) FROM dosage_guidelines WHERE source = 'DailyMed SPL Enhanced'")
        final_count = cursor.fetchone()[0]
        print(f"\n📊 Final 'DailyMed SPL Enhanced' count in production: {final_count:,}")
        
    except Exception as e:
        print(f"\n❌ FATAL ERROR: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    main()
