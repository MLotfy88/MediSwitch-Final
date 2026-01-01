#!/usr/bin/env python3
"""
سكربت اختبار سريع - جلب 5 أدوية فقط للتحقق
"""
import sys
import os

# إضافة المسار  
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

# تغيير المجلد الحالي إلى updated
os.chdir(os.path.join(os.path.dirname(__file__), 'updated'))

# استيراد السكربت الأصلي
import ultimate_scraper_v10 as scraper
import sqlite3

# تعديل القيم
scraper.MAX_WORKERS = 5  # تقليل Workers للاختبار

def test_scraping():
    """اختبار السحب على 5 أدوية فقط"""
    print("=" * 70)
    print("🧪 سكربت اختبار: جلب 5 أدوية فقط")
    print("=" * 70)
    
    # قائمة صغيرة من الأدوية للاختبار
    test_drugs = [
        'DDInter263',  # Caffeine
        'DDInter20',   # Aspirin  
        'DDInter900',  # Ibuprofen
        'DDInter1',    # Abacavir
        'DDInter100'   # Anthrax vaccine
    ]
    
    print(f"\n📋 سيتم اختبار {len(test_drugs)} أدوية:")
    for drug in test_drugs:
        print(f"   - {drug}")
    
    # تهيئة قاعدة البيانات إذا لم تكن موجودة
    if not os.path.exists(scraper.DB_PATH):
        print("\n⚠️ قاعدة البيانات غير موجودة!")
        return
    
    # معالجة كل دواء
    from concurrent.futures import ThreadPoolExecutor, as_completed
    
    print("\n🚀 بدء الاختبار...\n")
    
    with ThreadPoolExecutor(max_workers=2) as executor:
        futures = {executor.submit(scraper.process_single_drug, drug_id): drug_id for drug_id in test_drugs}
        
        for future in as_completed(futures):
            drug_id = futures[future]
            try:
                result = future.result()
                status = "✅" if result else "❌"
                print(f"{status} {drug_id}")
            except Exception as e:
                print(f"❌ {drug_id}: {e}")
    
    # التحقق من النتائج
    print("\n" + "=" * 70)
    print("📊 النتائج:")
    print("=" * 70)
    
    conn = sqlite3.connect(scraper.DB_PATH)
    c = conn.cursor()
    
    # 1. Mechanism Flags
    c.execute("""
        SELECT COUNT(*) 
        FROM drug_drug_interactions 
        WHERE mechanism_flags IS NOT NULL AND mechanism_flags != ''
          AND drug_a_id IN ('DDInter263', 'DDInter20', 'DDInter900', 'DDInter1', 'DDInter100')
    """)
    mech_count = c.fetchone()[0]
    print(f"\n✅ Mechanisms: {mech_count} تفاعلات لديها mechanism_flags")
    
    # عرض عينة
    c.execute("""
        SELECT drug_a_id, drug_b_id, mechanism_flags 
        FROM drug_drug_interactions 
        WHERE mechanism_flags IS NOT NULL AND mechanism_flags != ''
          AND drug_a_id IN ('DDInter263', 'DDInter20', 'DDInter900', 'DDInter1', 'DDInter100')
        LIMIT 3
    """)
    print("   عينة:")
    for row in c.fetchall():
        print(f"      {row[0]} + {row[1]}: {row[2]}")
    
    # 2. Drug-Disease Interactions
    c.execute("""
        SELECT COUNT(*)
        FROM drug_disease_interactions
        WHERE drug_id IN ('DDInter263', 'DDInter20', 'DDInter900', 'DDInter1', 'DDInter100')
    """)
    disease_count = c.fetchone()[0]
    print(f"\n✅ Drug-Disease: {disease_count} تفاعلات مع أمراض")
    
    # عرض عينة
    c.execute("""
        SELECT drug_id, disease_name, severity
        FROM drug_disease_interactions
        WHERE drug_id IN ('DDInter263', 'DDInter20', 'DDInter900', 'DDInter1', 'DDInter100')
        LIMIT 3
    """)
    print("   عينة:")
    for row in c.fetchall():
        print(f"      {row[0]} + {row[1]} ({row[2]})")
    
    # 3. Drug Info (Description, ATC)
    c.execute("""
        SELECT COUNT(*)
        FROM drugs
        WHERE ddinter_id IN ('DDInter263', 'DDInter20', 'DDInter900', 'DDInter1', 'DDInter100')
          AND (description IS NOT NULL OR atc_codes IS NOT NULL)
    """)
    drug_info_count = c.fetchone()[0]
    print(f"\n✅ Drug Info: {drug_info_count} أدوية لديها description/ATC")
    
    conn.close()
    
    print("\n" + "=" * 70)
    print("✅ انتهى الاختبار!")
    print("=" * 70)

if __name__ == "__main__":
    test_scraping()
