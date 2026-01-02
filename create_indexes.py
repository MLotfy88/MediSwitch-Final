import sqlite3
import os

DB_PATH = "mediswitch.db"

def create_indexes():
    if not os.path.exists(DB_PATH):
        print(f"❌ Database not found: {DB_PATH}")
        return
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    print("🔧 Creating Indexes for Optimal Performance...")
    print("="*80)
    
    indexes = [
        # Disease interactions indexes
        ("idx_disease_med", "disease_interactions", "med_id", "للبحث السريع حسب الدواء"),
        ("idx_disease_severity", "disease_interactions", "severity", "للفلترة حسب الخطورة"),
        ("idx_disease_name", "disease_interactions", "disease_name", "للبحث حسب اسم المرض"),
        
        # Food interactions indexes
        ("idx_food_med", "food_interactions", "med_id", "للبحث السريع حسب الدواء"),
        
        # Drug interactions indexes
        ("idx_ddi_ing1", "drug_interactions", "ingredient1", "للبحث حسب المادة الأولى"),
        ("idx_ddi_ing2", "drug_interactions", "ingredient2", "للبحث حسب المادة الثانية"),
        ("idx_ddi_severity", "drug_interactions", "severity", "للفلترة حسب الخطورة"),
        
        # Drugs table indexes (for joining)
        ("idx_drugs_active", "drugs", "active", "للبحث حسب المادة الفعالة"),
    ]
    
    for idx_name, table, column, description in indexes:
        try:
            cursor.execute(f"CREATE INDEX IF NOT EXISTS {idx_name} ON {table}({column})")
            print(f"✅ {idx_name:25} على {table:25} ({column:20}) - {description}")
        except Exception as e:
            print(f"⚠️  خطأ في {idx_name}: {e}")
    
    conn.commit()
    
    # عرض إحصائيات
    print("\n" + "="*80)
    print("📊 إحصائيات الفهرسة:")
    cursor.execute("SELECT name FROM sqlite_master WHERE type='index' AND sql IS NOT NULL")
    all_indexes = cursor.fetchall()
    print(f"إجمالي الـ Indexes: {len(all_indexes)}")
    
    # حساب حجم قاعدة البيانات
    db_size = os.path.getsize(DB_PATH) / (1024 * 1024)  # MB
    print(f"حجم قاعدة البيانات: {db_size:.2f} MB")
    
    conn.close()
    print("\n✅ تم إنشاء جميع الـ Indexes بنجاح!")
    print("⚡ استعلامات البحث الآن ستكون أسرع بكثير!")

if __name__ == "__main__":
    create_indexes()
