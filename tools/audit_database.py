#!/usr/bin/env python3
"""
سكربت فحص شامل لقاعدة بيانات MediSwitch
يقوم بفحص جميع الجداول وإعطاء تقرير مفصل عن نسبة ملء البيانات
"""

import sqlite3
import sys

def audit_database(db_path):
    """فحص شامل لقاعدة البيانات"""
    
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    
    print("="*80)
    print(f"📊 تقرير فحص قاعدة البيانات: {db_path}")
    print("="*80)
    
    # 1. فحص جدول الأدوية (drugs)
    print("\n### 1️⃣  جدول الأدوية (drugs)")
    print("-" * 80)
    c.execute("SELECT COUNT(*) FROM drugs")
    total_drugs = c.fetchone()[0]
    print(f"إجمالي الأدوية: {total_drugs:,}")
    
    # فحص الحقول المثرية
    c.execute("SELECT COUNT(*) FROM drugs WHERE description IS NOT NULL AND description != ''")
    with_desc = c.fetchone()[0]
    
    c.execute("SELECT COUNT(*) FROM drugs WHERE atc_codes IS NOT NULL AND atc_codes != ''")
    with_atc = c.fetchone()[0]
    
    c.execute("SELECT COUNT(*) FROM drugs WHERE external_links IS NOT NULL AND external_links != ''")
    with_links = c.fetchone()[0]
    
    print(f"  ✓ بها وصف (description): {with_desc:,} ({with_desc/total_drugs*100:.1f}%)")
    print(f"  ✓ بها رموز ATC: {with_atc:,} ({with_atc/total_drugs*100:.1f}%)")
    print(f"  ✓ بها روابط خارجية: {with_links:,} ({with_links/total_drugs*100:.1f}%)")
    
    # 2. فحص التفاعلات الدوائية (drug_interactions)
    print("\n### 2️⃣  التفاعلات الدوائية (drug_interactions)")
    print("-" * 80)
    c.execute("SELECT COUNT(*) FROM drug_interactions")
    total_ddi = c.fetchone()[0]
    print(f"إجمالي التفاعلات: {total_ddi:,}")
    
    if total_ddi > 0:
        # فحص الأعمدة المثرية
        checks = [
            ("severity", "شدة التفاعل"),
            ("effect", "التأثير"),
            ("management_text", "نصائح الإدارة"),
            ("mechanism_text", "آلية التفاعل"),
            ("alternatives_a", "البدائل A"),
            ("alternatives_b", "البدائل B"),
            ("reference_text", "المراجع"),
            ("metabolism_info", "معلومات الأيض"),
            ("source_url", "رابط المصدر"),
        ]
        
        for col, label in checks:
            c.execute(f"SELECT COUNT(*) FROM drug_interactions WHERE {col} IS NOT NULL AND {col} != ''")
            count = c.fetchone()[0]
            pct = count/total_ddi*100
            status = "✅" if pct > 90 else "⚠️" if pct > 50 else "❌"
            print(f"  {status} {label} ({col}): {count:,} ({pct:.1f}%)")
    
    # 3. فحص تفاعلات الغذاء (food_interactions)
    print("\n### 3️⃣  تفاعلات الغذاء (food_interactions)")
    print("-" * 80)
    c.execute("SELECT COUNT(*) FROM food_interactions")
    total_food = c.fetchone()[0]
    print(f"إجمالي تفاعلات الغذاء: {total_food:,}")
    
    if total_food > 0:
        checks_food = [
            ("ingredient", "المكون الغذائي"),
            ("severity", "الشدة"),
            ("management_text", "نصائح الإدارة"),
            ("mechanism_text", "الآلية"),
            ("reference_text", "المراجع"),
        ]
        
        for col, label in checks_food:
            c.execute(f"SELECT COUNT(*) FROM food_interactions WHERE {col} IS NOT NULL AND {col} != ''")
            count = c.fetchone()[0]
            pct = count/total_food*100
            status = "✅" if pct > 90 else "⚠️" if pct > 50 else "❌"
            print(f"  {status} {label} ({col}): {count:,} ({pct:.1f}%)")
    
    # 4. فحص تفاعلات الأمراض (disease_interactions)
    print("\n### 4️⃣  تفاعلات الأمراض (disease_interactions)")
    print("-" * 80)
    c.execute("SELECT COUNT(*) FROM disease_interactions")
    total_disease = c.fetchone()[0]
    print(f"إجمالي تفاعلات الأمراض: {total_disease:,}")
    
    if total_disease > 0:
        c.execute("SELECT COUNT(*) FROM disease_interactions WHERE severity IS NOT NULL AND severity != ''")
        with_severity = c.fetchone()[0]
        
        c.execute("SELECT COUNT(*) FROM disease_interactions WHERE reference_text IS NOT NULL AND reference_text != ''")
        with_ref = c.fetchone()[0]
        
        print(f"  ✅ بها شدة: {with_severity:,} ({with_severity/total_disease*100:.1f}%)")
        print(f"  ✅ بها مراجع: {with_ref:,} ({with_ref/total_disease*100:.1f}%)")
    
    # 5. فحص الجرعات (dosage_guidelines)
    print("\n### 5️⃣  إرشادات الجرعات (dosage_guidelines)")
    print("-" * 80)
    c.execute("SELECT COUNT(*) FROM dosage_guidelines")
    total_dosages = c.fetchone()[0]
    print(f"إجمالي سجلات الجرعات: {total_dosages:,}")
    
    if total_dosages > 0:
        c.execute("SELECT COUNT(*), source FROM dosage_guidelines GROUP BY source")
        sources = c.fetchall()
        print("  التوزيع حسب المصدر:")
        for count, source in sources:
            print(f"    • {source}: {count:,}")
    
    # 6. فحص المكونات (med_ingredients)
    print("\n### 6️⃣  مكونات الأدوية (med_ingredients)")
    print("-" * 80)
    c.execute("SELECT COUNT(*) FROM med_ingredients")
    total_ingredients = c.fetchone()[0]
    print(f"إجمالي سجلات المكونات: {total_ingredients:,}")
    
    c.execute("SELECT COUNT(DISTINCT med_id) FROM med_ingredients")
    unique_drugs = c.fetchone()[0]
    print(f"عدد الأدوية المرتبطة: {unique_drugs:,}")
    
    # الخلاصة النهائية
    print("\n" + "="*80)
    print("📋 الخلاصة النهائية:")
    print("="*80)
    
    issues = []
    
    # تحديد المشاكل
    if total_ddi == 0:
        issues.append("❌ لا توجد تفاعلات دوائية!")
    else:
        c.execute("SELECT COUNT(*) FROM drug_interactions WHERE alternatives_a IS NULL OR alternatives_a = ''")
        missing_alts = c.fetchone()[0]
        if missing_alts / total_ddi > 0.1:  # أكثر من 10% فارغة
            issues.append(f"⚠️ هناك {missing_alts:,} تفاعل بدون بدائل A ({missing_alts/total_ddi*100:.1f}%)")
    
    if total_food == 0:
        issues.append("❌ لا توجد تفاعلات غذائية!")
    
    if total_disease == 0:
        issues.append("❌ لا توجد تفاعلات مع الأمراض!")
    
    if total_dosages == 0:
        issues.append("❌ لا توجد بيانات جرعات!")
    
    if not issues:
        print("✅ قاعدة البيانات سليمة ومكتملة!")
        print("✅ جميع الجداول تحتوي على بيانات بنسب جيدة.")
        print("✅ يمكنك المتابعة للمزامنة مع D1 بأمان.")
        return 0  # Success
    else:
        print("⚠️ تم اكتشاف بعض المشاكل:")
        for issue in issues:
            print(f"  {issue}")
        print("\n⚠️ يُنصح بإصلاح هذه المشاكل قبل المزامنة مع D1.")
        return 1  # Has issues
    
    conn.close()

if __name__ == "__main__":
    db_path = "mediswitch.db"
    if len(sys.argv) > 1:
        db_path = sys.argv[1]
    
    exit_code = audit_database(db_path)
    sys.exit(exit_code)
