#!/usr/bin/env python3
"""
تحديث هيكل جدول dosage_guidelines لإضافة أعمدة جديدة للبيانات الغنية من DailyMed
"""
import sqlite3
import os

def migrate_dosage_guidelines_schema(db_path):
    """إضافة أعمدة جديدة لجدول dosage_guidelines"""
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    print("🔄 بدء تحديث هيكل جدول dosage_guidelines...")
    
    # قائمة الأعمدة الجديدة
    new_columns = [
        # معلومات الجرعة التفصيلية
        ("dose_unit", "TEXT", "وحدة القياس"),
        ("route", "TEXT", "طريق الإعطاء"),
        ("dosage_form", "TEXT", "الشكل الدوائي"),
        ("titration_info", "TEXT", "معلومات التدريج"),
        ("max_daily_dose", "REAL", "الحد الأقصى اليومي"),
        ("loading_dose", "REAL", "الجرعة التحميلية"),
        ("maintenance_dose", "REAL", "جرعة الصيانة"),
        
        # فئات المرضى
        ("is_geriatric", "INTEGER DEFAULT 0", "لكبار السن"),
        ("renal_adjustment", "TEXT", "تعديل القصور الكلوي"),
        ("hepatic_adjustment", "TEXT", "تعديل القصور الكبدي"),
        ("pregnancy_category", "TEXT", "فئة الحمل"),
        ("lactation_info", "TEXT", "معلومات الرضاعة"),
        
        # معلومات السلامة
        ("contraindications", "TEXT", "موانع الاستعمال"),
        ("warnings", "TEXT", "التحذيرات"),
        ("precautions", "TEXT", "الاحتياطات"),
        ("adverse_reactions", "TEXT", "الأعراض الجانبية"),
        ("black_box_warning", "TEXT", "تحذير الصندوق الأسود"),
        ("overdose_management", "TEXT", "إدارة الجرعة الزائدة"),
        
        # معلومات الفعالية
        ("indication", "TEXT", "دواعي الاستعمال"),
        ("mechanism_of_action", "TEXT", "آلية العمل"),
        ("therapeutic_class", "TEXT", "الفئة العلاجية"),
        
        # معلومات إضافية
        ("drug_interactions_summary", "TEXT", "ملخص التداخلات"),
        ("monitoring_requirements", "TEXT", "متطلبات المراقبة"),
        ("storage_conditions", "TEXT", "ظروف التخزين"),
        ("special_populations", "TEXT", "فئات خاصة"),
        
        # بيانات وصفية
        ("extraction_date", "DATETIME", "تاريخ الاستخراج"),
        ("spl_version", "TEXT", "إصدار SPL"),
        ("confidence_score", "REAL", "درجة الثقة"),
        ("data_completeness", "REAL", "اكتمال البيانات"),
    ]
    
    # إضافة الأعمدة واحداً تلو الآخر
    added_count = 0
    skipped_count = 0
    
    for column_name, column_type, description in new_columns:
        try:
            # التحقق إذا كان العمود موجوداً
            cursor.execute(f"PRAGMA table_info(dosage_guidelines)")
            existing_columns = [col[1] for col in cursor.fetchall()]
            
            if column_name in existing_columns:
                print(f"  ⏭️  {column_name:30} - موجود مسبقاً")
                skipped_count += 1
                continue
            
            # إضافة العمود
            sql = f"ALTER TABLE dosage_guidelines ADD COLUMN {column_name} {column_type}"
            cursor.execute(sql)
            print(f"  ✅ {column_name:30} - تمت الإضافة ({description})")
            added_count += 1
            
        except sqlite3.OperationalError as e:
            if "duplicate column name" in str(e):
                print(f"  ⏭️  {column_name:30} - موجود مسبقاً")
                skipped_count += 1
            else:
                print(f"  ❌ {column_name:30} - خطأ: {e}")
    
    # حفظ التغييرات
    conn.commit()
    conn.close()
    
    print(f"\n{'='*80}")
    print(f"✅ اكتمل التحديث!")
    print(f"  - أعمدة جديدة: {added_count}")
    print(f"  - أعمدة موجودة: {skipped_count}")
    print(f"  - الإجمالي: {len(new_columns)}")
    print(f"{'='*80}")
    
    return added_count

def verify_schema(db_path):
    """التحقق من هيكل الجدول بعد التحديث"""
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    cursor.execute("PRAGMA table_info(dosage_guidelines)")
    columns = cursor.fetchall()
    
    print(f"\n📋 هيكل الجدول الحالي ({len(columns)} عمود):")
    print("="*80)
    for col in columns:
        col_id, name, type_, notnull, default, pk = col
        req = "مطلوب" if notnull else "اختياري"
        pk_mark = " 🔑" if pk else ""
        print(f"  {col_id:2}. {name:35} {type_:15} ({req}){pk_mark}")
    
    conn.close()

def main():
    print("="*80)
    print("تحديث هيكل قاعدة بيانات الجرعات - Enhanced Schema Migration")
    print("="*80)
    
    # تجميع قاعدة البيانات
    parts_dir = 'assets/database/parts'
    db_path = 'temp_mediswitch_migration.db'
    
    if os.path.exists(db_path):
        os.remove(db_path)
    
    parts = sorted([f for f in os.listdir(parts_dir) if f.startswith('mediswitch.db.part-')])
    
    print(f"\n🔧 تجميع قاعدة البيانات من {len(parts)} جزء...")
    with open(db_path, 'wb') as outfile:
        for part in parts:
            part_path = os.path.join(parts_dir, part)
            with open(part_path, 'rb') as infile:
                outfile.write(infile.read())
    
    print(f"✅ تم التجميع\n")
    
    # تنفيذ التحديث
    added = migrate_dosage_guidelines_schema(db_path)
    
    # التحقق من الهيكل
    if added > 0:
        verify_schema(db_path)
    
    print(f"\n💾 قاعدة البيانات المحدثة: {db_path}")
    print(f"⚠️  لا تنسَ: يجب استخدام هذا الملف في السكربت التالي")
    print("\n✅ انتهى")

if __name__ == "__main__":
    main()
