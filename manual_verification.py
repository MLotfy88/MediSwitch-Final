import sqlite3

DB = "mediswitch.db"

def verify_manually():
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    
    print("="*100)
    print("🔍 الفحص اليدوي لبيانات التفاعلات - MediSwitch Database")
    print("="*100)
    
    # 1. فحص التفاعلات الدوائية - التأكد من عدم التكرار
    print("\n📌 الجزء الأول: فحص تفاعلات الأدوية (Drug-Drug Interactions)")
    print("-"*100)
    c.execute("""
        SELECT ingredient1, ingredient2, severity, 
               SUBSTR(effect, 1, 80) as effect_preview,
               SUBSTR(management_text, 1, 80) as mgmt_preview,
               SUBSTR(recommendation, 1, 80) as rec_preview,
               mechanism_text
        FROM drug_interactions 
        WHERE ingredient1 IN ('Aspirin', 'Metformin', 'Warfarin')
        LIMIT 5
    """)
    
    for i, row in enumerate(c.fetchall(), 1):
        print(f"\nالعينة #{i}:")
        print(f"  الدواء الأول: {row[0]}")
        print(f"  الدواء الثاني: {row[1]}")
        print(f"  الخطورة: {row[2]}")
        print(f"  التأثير: {row[3]}...")
        print(f"  إدارة التفاعل: {row[4]}...")
        print(f"  التوصية: {row[5]}...")
        print(f"  الآلية: {row[6]}")
        print(f"  ✓ هل التوصية مختلفة عن الإدارة؟ {'نعم' if row[4] != row[5] else 'لا - متطابقة!'}")
    
    # 2. فحص تفاعلات الأمراض - التأكد من الربط بالأدوية المحلية
    print("\n\n📌 الجزء الثاني: فحص تفاعلات الأمراض (Drug-Disease Interactions)")
    print("-"*100)
    c.execute("""
        SELECT di.trade_name, d.tradeName as local_drug, d.id as med_id,
               di.disease_name, di.severity,
               SUBSTR(di.interaction_text, 1, 100) as interaction_preview
        FROM disease_interactions di
        LEFT JOIN drugs d ON di.med_id = d.id
        WHERE di.med_id > 0
        ORDER BY RANDOM()
        LIMIT 5
    """)
    
    for i, row in enumerate(c.fetchall(), 1):
        print(f"\nالعينة #{i}:")
        print(f"  المادة الفعالة (DDInter): {row[0]}")
        print(f"  الدواء المحلي المرتبط: {row[1]}")
        print(f"  رقم الدواء (med_id): {row[2]}")
        print(f"  المرض: {row[3]}")
        print(f"  الخطورة: {row[4]}")
        print(f"  التفاعل: {row[5]}...")
        print(f"  ✓ هل تم الربط؟ {'نعم - صحيح!' if row[1] else 'لا - خطأ!'}")
    
    # 3. فحص تفاعلات الطعام
    print("\n\n📌 الجزء الثالث: فحص تفاعلات الطعام (Drug-Food Interactions)")
    print("-"*100)
    c.execute("""
        SELECT d.tradeName as local_drug, d.active, fi.med_id,
               SUBSTR(fi.interaction_text, 1, 120) as interaction_preview
        FROM food_interactions fi
        JOIN drugs d ON fi.med_id = d.id
        WHERE fi.med_id > 0
        ORDER BY RANDOM()
        LIMIT 5
    """)
    
    for i, row in enumerate(c.fetchall(), 1):
        print(f"\nالعينة #{i}:")
        print(f"  الدواء المحلي: {row[0]}")
        print(f"  المادة الفعالة: {row[1]}")
        print(f"  رقم الدواء (med_id): {row[2]}")
        print(f"  التفاعل: {row[3]}...")
        print(f"  ✓ التفاعل يحتوي على تفاصيل؟ {'نعم' if 'Interaction Type' in row[3] else 'لا'}")
    
    # 4. إحصائيات نهائية
    print("\n\n📊 إحصائيات نهائية:")
    print("-"*100)
    
    c.execute("SELECT COUNT(*) FROM drug_interactions")
    print(f"إجمالي تفاعلات الأدوية: {c.fetchone()[0]:,}")
    
    c.execute("SELECT COUNT(*) FROM disease_interactions WHERE med_id > 0")
    linked_diseases = c.fetchone()[0]
    c.execute("SELECT COUNT(*) FROM disease_interactions")
    total_diseases = c.fetchone()[0]
    print(f"تفاعلات الأمراض المرتبطة: {linked_diseases:,} / {total_diseases:,} ({linked_diseases/total_diseases*100:.1f}%)")
    
    c.execute("SELECT COUNT(*) FROM food_interactions WHERE med_id > 0")
    linked_food = c.fetchone()[0]
    c.execute("SELECT COUNT(*) FROM food_interactions")
    total_food = c.fetchone()[0]
    print(f"تفاعلات الطعام المرتبطة: {linked_food:,} / {total_food:,} ({linked_food/total_food*100:.1f}%)")
    
    # 5. فحص عدم التكرار في التوصيات
    c.execute("""
        SELECT COUNT(*) FROM drug_interactions 
        WHERE management_text = recommendation
    """)
    duplicates = c.fetchone()[0]
    c.execute("SELECT COUNT(*) FROM drug_interactions")
    total_ddis = c.fetchone()[0]
    print(f"\nالتفاعلات التي فيها تكرار (management = recommendation): {duplicates:,} / {total_ddis:,} ({duplicates/total_ddis*100:.1f}%)")
    
    conn.close()
    print("\n" + "="*100)
    print("✅ انتهى الفحص اليدوي")
    print("="*100)

if __name__ == "__main__":
    verify_manually()
