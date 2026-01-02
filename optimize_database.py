import sqlite3
import os

DB_PATH = "mediswitch.db"

def optimize_database():
    """تحسين قاعدة البيانات بإزالة التكرار"""
    
    print("🔧 بدء تحسين قاعدة البيانات...")
    print("="*80)
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # 1. حذف التكرار من disease_interactions
    print("\n📋 خطوة 1: تحسين disease_interactions...")
    print("   الحجم الحالي:", end=" ")
    cursor.execute("SELECT COUNT(*) FROM disease_interactions")
    original_count = cursor.fetchone()[0]
    print(f"{original_count:,} صف")
    
    # إنشاء جدول مؤقت بدون تكرار (واحد لكل مادة فعالة)
    cursor.execute("""
        CREATE TABLE disease_interactions_temp AS
        SELECT 
            trade_name,
            disease_name,
            severity,
            interaction_text,
            source,
            created_at,
            MIN(id) as id
        FROM disease_interactions
        WHERE med_id > 0 OR med_id = 0
        GROUP BY trade_name, disease_name
    """)
    
    cursor.execute("SELECT COUNT(*) FROM disease_interactions_temp")
    new_count = cursor.fetchone()[0]
    print(f"   الحجم الجديد: {new_count:,} صف")
    print(f"   ✅ تم تقليل {original_count - new_count:,} صف ({(1 - new_count/original_count)*100:.1f}% تقليل)")
    
    # 2. حذف التكرار من food_interactions  
    print("\n📋 خطوة 2: تحسين food_interactions...")
    print("   الحجم الحالي:", end=" ")
    cursor.execute("SELECT COUNT(*) FROM food_interactions")
    original_food = cursor.fetchone()[0]
    print(f"{original_food:,} صف")
    
    cursor.execute("""
        CREATE TABLE food_interactions_temp AS
        SELECT 
            interaction_text,
            source,
            created_at,
            MIN(id) as id
        FROM food_interactions
        GROUP BY interaction_text
    """)
    
    cursor.execute("SELECT COUNT(*) FROM food_interactions_temp")
    new_food = cursor.fetchone()[0]
    print(f"   الحجم الجديد: {new_food:,} صف")
    print(f"   ✅ تم تقليل {original_food - new_food:,} صف ({(1 - new_food/original_food)*100:.1f}% تقليل)")
    
    # 3. استبدال الجداول
    print("\n📋 خطوة 3: استبدال الجداول القديمة...")
    
    cursor.execute("DROP TABLE disease_interactions")
    cursor.execute("ALTER TABLE disease_interactions_temp RENAME TO disease_interactions")
    print("   ✅ تم تحديث disease_interactions")
    
    cursor.execute("DROP TABLE food_interactions")
    cursor.execute("ALTER TABLE food_interactions_temp RENAME TO food_interactions")
    print("   ✅ تم تحديث food_interactions")
    
    # 4. إعادة بناء الـ indexes
    print("\n📋 خطوة 4: إعادة بناء Indexes...")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_disease_name ON disease_interactions(disease_name)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_disease_severity ON disease_interactions(severity)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_food_text ON food_interactions(interaction_text)")
    print("   ✅ تم إنشاء الـ Indexes")
    
    # 5. تنظيف وضغط قاعدة البيانات
    print("\n📋 خطوة 5: ضغط قاعدة البيانات...")
    old_size = os.path.getsize(DB_PATH) / (1024 * 1024)
    print(f"   الحجم قبل الضغط: {old_size:.2f} MB")
    
    cursor.execute("VACUUM")
    
    conn.commit()
    conn.close()
    
    new_size = os.path.getsize(DB_PATH) / (1024 * 1024)
    print(f"   الحجم بعد الضغط: {new_size:.2f} MB")
    print(f"   ✅ تم توفير {old_size - new_size:.2f} MB ({(1 - new_size/old_size)*100:.1f}% تقليل)")
    
    print("\n" + "="*80)
    print("🎉 انتهى التحسين بنجاح!")
    print(f"📊 الحجم النهائي: {new_size:.2f} MB")
    print("="*80)

if __name__ == "__main__":
    # نسخ احتياطي أولاً
    import shutil
    backup_path = "mediswitch_before_optimization.db"
    if not os.path.exists(backup_path):
        print("💾 إنشاء نسخة احتياطية...")
        shutil.copy2(DB_PATH, backup_path)
        print(f"   ✅ تم حفظ النسخة الاحتياطية: {backup_path}")
    
    optimize_database()
