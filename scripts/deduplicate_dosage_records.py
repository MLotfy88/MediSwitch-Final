import sqlite3
import time

DB_PATH = 'assets/database/mediswitch.db'

def clean_database():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    print("="*80)
    print("🧹 تنظيف وإزالة التكرار من قاعدة البيانات")
    print("="*80)
    
    try:
        # 1. Get initial count
        cursor.execute("SELECT COUNT(*) FROM dosage_guidelines WHERE source = 'DailyMed SPL Enhanced'")
        initial_count = cursor.fetchone()[0]
        print(f"📊 العدد الحالي للسجلات: {initial_count:,}")
        
        # 2. Define the scoring logic (Completeness Score)
        # We give higher weight to records that have critical info
        # Columns to check: min_dose, max_dose, warnings, contraindications, instructions, patient_category
        
        print("🔄 جاري حساب النتائج وتحديد السجلات الأفضل (قد يستغرق وقتاً)...")
        
        # We will use a CTE with ROW_NUMBER() to identify the best records
        # Score calculation:
        # +5 if has numeric dose (min_dose)
        # +3 if has warning
        # +3 if has contraindication
        # +2 if has adverse_reaction
        # +1 for other fields
        # +0.1 * LENGTH(section_text) / 1000 (Prefer longer detailed text)
        
        start_time = time.time()
        
        delete_query = """
        DELETE FROM dosage_guidelines 
        WHERE id IN (
            SELECT id FROM (
                SELECT 
                    id,
                    ROW_NUMBER() OVER (
                        PARTITION BY med_id 
                        ORDER BY 
                            (CASE WHEN min_dose IS NOT NULL OR max_dose IS NOT NULL THEN 5 ELSE 0 END +
                             CASE WHEN warnings IS NOT NULL THEN 3 ELSE 0 END +
                             CASE WHEN contraindications IS NOT NULL THEN 3 ELSE 0 END +
                             CASE WHEN adverse_reactions IS NOT NULL THEN 2 ELSE 0 END +
                             CASE WHEN frequency IS NOT NULL THEN 2 ELSE 0 END +
                             CASE WHEN patient_category IS NOT NULL THEN 1 ELSE 0 END
                            ) DESC
                    ) as rank
                FROM dosage_guidelines
                WHERE source = 'DailyMed SPL Enhanced'
            ) 
            WHERE rank > 3
        );
        """
        
        cursor.execute(delete_query)
        deleted_count = cursor.rowcount
        conn.commit()
        
        end_time = time.time()
        print(f"✅ تم الحذف بنجاح في {end_time - start_time:.1f} ثانية")
        print(f"🗑️  عدد السجلات المحذوفة: {deleted_count:,}")
        
        # 3. Final Count
        cursor.execute("SELECT COUNT(*) FROM dosage_guidelines WHERE source = 'DailyMed SPL Enhanced'")
        final_count = cursor.fetchone()[0]
        print(f"✨ العدد النهائي للسجلات: {final_count:,}")
        print(f"📉 نسبة التقليص: {(deleted_count/initial_count*100):.1f}%")
        
        print("\n🔍 التحقق من دمج 'proclean astra' كمثال:")
        cursor.execute("""
            SELECT d.trade_name, COUNT(*) 
            FROM dosage_guidelines dg
            JOIN drugs d ON d.id = dg.med_id
            WHERE d.trade_name LIKE 'proclean astra%'
            GROUP BY d.trade_name
        """)
        for row in cursor.fetchall():
            print(f"  - {row[0]}: {row[1]} سجل")

        print("🔄 جاري ضغط قاعدة البيانات (VACUUM)...")
        cursor.execute("VACUUM")
        print("✅ تم الضغط.")

    except Exception as e:
        print(f"❌ حدث خطأ: {e}")
        conn.rollback()
    finally:
        conn.close()

if __name__ == "__main__":
    clean_database()
