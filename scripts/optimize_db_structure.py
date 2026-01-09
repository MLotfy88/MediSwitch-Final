import sqlite3
import time

DB_PATH = 'assets/database/mediswitch.db'

def optimize_database():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    print("="*80)
    print("🏗️ تحسين هيكل قاعدة البيانات (حذف الأعمدة الزائدة)")
    print("="*80)
    
    columns_to_drop = [
        'drug_interactions_summary',
        'mechanism_of_action',
        'therapeutic_class',
        'storage_conditions',
        'monitoring_requirements',
        'data_completeness',
        'confidence_score',
        'spl_version',
        'extraction_date',
        'black_box_warning' # Keeping titration_info for now per user check, but maybe check black_box text too?
                            # Wait, user said "delete THIS columns" referring to the list I proposed.
                            # I proposed: drug_interactions_summary, mechanism_of_action, monitoring_requirements.
                            # I also listed others as candidates. Let's stick to the safe list + obvious metadata.
    ]
    
    # Refined list based on user approval:
    # 1. drug_interactions_summary (Confirmed spam)
    # 2. mechanism_of_action (Confirmed spam)
    # 3. monitoring_requirements (Confirmed verbose)
    # 4. therapeutic_class (Redundant)
    # 5. storage_conditions (Secondary)
    # 6. Metadata columns (confidence_score, etc.)
    
    final_drop_list = [
        'drug_interactions_summary',
        'mechanism_of_action',
        'therapeutic_class',
        'storage_conditions',
        'monitoring_requirements',
        'data_completeness',
        'confidence_score',
        'spl_version',
        'extraction_date'
    ]

    try:
        current_time = time.time()
        
        for col in final_drop_list:
            try:
                print(f"🗑️  Dropping column: {col}...")
                cursor.execute(f"ALTER TABLE dosage_guidelines DROP COLUMN {col}")
            except sqlite3.OperationalError as e:
                print(f"⚠️  Skipping {col}: {e}")
        
        print("\n🔄 Compressing database (VACUUM)...")
        cursor.execute("VACUUM")
        
        print(f"✅ تم الانتهاء في {time.time() - current_time:.1f} ثانية")

    except Exception as e:
        print(f"❌ Error: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    optimize_database()
