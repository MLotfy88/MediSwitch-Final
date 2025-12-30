import sqlite3
import json

DB_PATH = 'ddinter_data/ddinter_complete.db'

def verify_data():
    print("🕵️ التحقق من توفر البيانات في أعمدة DDInter...\n")
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    # 1. Check Alternative Drugs
    print("1️⃣  فحص البدائل الآمنة (Alternative Drugs):")
    cursor.execute("""
        SELECT COUNT(*) FROM drug_drug_interactions 
        WHERE alternative_drugs_a IS NOT NULL AND alternative_drugs_a != '[]' 
           OR alternative_drugs_b IS NOT NULL AND alternative_drugs_b != '[]'
    """)
    alt_count = cursor.fetchone()[0]
    
    cursor.execute("SELECT COUNT(*) FROM drug_drug_interactions")
    total_ddi = cursor.fetchone()[0]
    
    print(f"   - إجمالي التفاعلات: {total_ddi:,}")
    print(f"   - تفاعلات تحتوي على بدائل مقترحة: {alt_count:,} ({alt_count/total_ddi*100:.1f}%)")
    
    if alt_count > 0:
        cursor.execute("""
            SELECT alternative_drugs_a FROM drug_drug_interactions 
            WHERE alternative_drugs_a IS NOT NULL AND alternative_drugs_a != '[]' LIMIT 1
        """)
        example = cursor.fetchone()[0]
        print(f"   - مثال على البيانات: {example[:100]}...")
    else:
        print("   ⚠️  تحذير: لا توجد بيانات بدائل!")

    # 2. Check Food Interactions
    print("\n2️⃣  فحص التفاعلات الغذائية (Reference Table):")
    cursor.execute("SELECT COUNT(*) FROM drug_food_interactions")
    food_count = cursor.fetchone()[0]
    print(f"   - عدد سجلات التفاعلات الغذائية في الجدول الأصلي: {food_count:,}")
    
    if food_count > 0:
        cursor.execute("SELECT food_name, description FROM drug_food_interactions LIMIT 3")
        rows = cursor.fetchall()
        print("   - أمثلة:")
        for r in rows:
            print(f"     * {r[0]}: {r[1][:50]}...")
            
    conn.close()

if __name__ == "__main__":
    verify_data()
