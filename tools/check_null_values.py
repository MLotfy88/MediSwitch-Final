#!/usr/bin/env python3
"""
فحص القيم النصية null في قاعدة البيانات
"""
import sqlite3

conn = sqlite3.connect('mediswitch.db')
c = conn.cursor()

print('='*80)
print('🔍 فحص القيم النصية "null" في قاعدة البيانات')
print('='*80)

# فحص drug_interactions
print('\n### التفاعلات الدوائية (drug_interactions):')
print('-'*80)

c.execute('SELECT COUNT(*) FROM drug_interactions WHERE metabolism_info = "null"')
null_text = c.fetchone()[0]
print(f'metabolism_info = "null" (كنص): {null_text:,}')

c.execute('SELECT COUNT(*) FROM drug_interactions WHERE metabolism_info IS NULL')
null_real = c.fetchone()[0]
print(f'metabolism_info IS NULL (حقيقي): {null_real:,}')

c.execute('SELECT COUNT(*) FROM drug_interactions WHERE metabolism_info = ""')
empty = c.fetchone()[0]
print(f'metabolism_info = "" (فارغ): {empty:,}')

# عينة
c.execute('SELECT metabolism_info FROM drug_interactions WHERE metabolism_info IS NOT NULL AND metabolism_info != "" LIMIT 5')
samples = c.fetchall()
if samples:
    print(f'\nعينات من القيم الموجودة:')
    for s in samples:
        print(f'  -> {repr(s[0])}')
else:
    print('\n⚠️ لا توجد قيم ممتلئة')

# فحص food_interactions
print('\n### تفاعلات الغذاء (food_interactions):')
print('-'*80)

c.execute('SELECT COUNT(*) FROM food_interactions WHERE mechanism_text = "null"')
food_null_text = c.fetchone()[0]
print(f'mechanism_text = "null" (كنص): {food_null_text:,}')

c.execute('SELECT COUNT(*) FROM food_interactions WHERE mechanism_text IS NULL')
food_null_real = c.fetchone()[0]
print(f'mechanism_text IS NULL (حقيقي): {food_null_real:,}')

c.execute('SELECT COUNT(*) FROM food_interactions WHERE mechanism_text = ""')
food_empty = c.fetchone()[0]
print(f'mechanism_text = "" (فارغ): {food_empty:,}')

print()
c.execute('SELECT COUNT(*) FROM food_interactions WHERE reference_text = "null"')
food_ref_null_text = c.fetchone()[0]
print(f'reference_text = "null" (كنص): {food_ref_null_text:,}')

c.execute('SELECT COUNT(*) FROM food_interactions WHERE reference_text IS NULL')
food_ref_null_real = c.fetchone()[0]
print(f'reference_text IS NULL (حقيقي): {food_ref_null_real:,}')

# الخلاصة
print('\n' + '='*80)
print('📋 الخلاصة:')
print('='*80)

if null_text > 0 or food_null_text > 0 or food_ref_null_text > 0:
    print('⚠️ تحذير: هناك قيم نصية "null" في قاعدة البيانات!')
    print('   هذه القيم يحتسبها السكربت كبيانات ممتلئة (خطأ)')
    print('\nالتوصية: تنظيف البيانات لتحويل "null" النصية إلى NULL حقيقية')
else:
    print('✅ ممتاز: لا توجد قيم نصية "null"')
    print('✅ جميع القيم الفارغة هي NULL حقيقية')

conn.close()
