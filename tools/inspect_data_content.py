#!/usr/bin/env python3
"""
سكربت فحص محتوى البيانات الفعلية في قاعدة البيانات
"""
import sqlite3

def inspect_data_quality():
    conn = sqlite3.connect('mediswitch.db')
    conn.row_factory = sqlite3.Row
    c = conn.cursor()

    print('='*80)
    print('🔍 فحص محتوى البيانات في mediswitch.db')
    print('='*80)

    # 1. فحص drug_interactions
    print('\n### 1️⃣  عينات من drug_interactions:')
    print('-'*80)
    c.execute('''
        SELECT ingredient1, ingredient2, severity, effect, management_text, 
               mechanism_text, alternatives_a, alternatives_b, reference_text, source_url
        FROM drug_interactions 
        WHERE alternatives_a IS NOT NULL AND alternatives_a != ""
        LIMIT 3
    ''')

    for i, row in enumerate(c.fetchall(), 1):
        print(f'\nعينة {i}:')
        print(f'  المكونات: {row[0]} + {row[1]}')
        print(f'  الشدة: {row[2]}')
        effect_text = row[3][:80] + '...' if row[3] and len(row[3]) > 80 else row[3]
        print(f'  التأثير: {effect_text}')
        mgmt_text = row[4][:80] + '...' if row[4] and len(row[4]) > 80 else row[4]
        print(f'  الإدارة: {mgmt_text}')
        print(f'  الآلية: {row[5][:80] if row[5] else "فارغ"}')
        alt_a = row[6][:80] + '...' if row[6] and len(row[6]) > 80 else row[6]
        print(f'  البدائل A: {alt_a}')
        print(f'  البدائل B: {row[7][:80] if row[7] else "فارغ"}')
        ref_text = row[8][:80] + '...' if row[8] and len(row[8]) > 80 else row[8]
        print(f'  المراجع: {ref_text}')
        print(f'  الرابط: {row[9][:60] if row[9] else "فارغ"}')

    # 2. فحص food_interactions
    print('\n### 2️⃣  عينات من food_interactions:')
    print('-'*80)
    c.execute('''
        SELECT med_id, trade_name, interaction, ingredient, severity, management_text
        FROM food_interactions LIMIT 3
    ''')

    for i, row in enumerate(c.fetchall(), 1):
        print(f'\nعينة {i}:')
        print(f'  الدواء: {row[1]} (ID: {row[0]})')
        print(f'  المكون الغذائي: {row[3]}')
        print(f'  الشدة: {row[4]}')
        interaction = row[2][:100] + '...' if len(row[2]) > 100 else row[2]
        print(f'  التفاعل: {interaction}')
        mgmt = row[5][:100] + '...' if row[5] and len(row[5]) > 100 else row[5]
        print(f'  الإدارة: {mgmt}')

    # 3. فحص disease_interactions
    print('\n### 3️⃣  عينات من disease_interactions:')
    print('-'*80)
    c.execute('''
        SELECT med_id, trade_name, disease_name, interaction_text, severity, reference_text
        FROM disease_interactions LIMIT 3
    ''')

    for i, row in enumerate(c.fetchall(), 1):
        print(f'\nعينة {i}:')
        print(f'  الدواء: {row[1]} (ID: {row[0]})')
        print(f'  المرض: {row[2]}')
        print(f'  الشدة: {row[4]}')
        interaction = row[3][:100] + '...' if len(row[3]) > 100 else row[3]
        print(f'  التفاعل: {interaction}')
        print(f'  المرجع: {row[5][:80] if row[5] else "فارغ"}')

    # 4. فحص الأدوية المثرية
    print('\n### 4️⃣  عينات من drugs (المثرية):')
    print('-'*80)
    c.execute('''
        SELECT id, trade_name, active, description, atc_codes, external_links
        FROM drugs 
        WHERE description IS NOT NULL AND description != ""
        LIMIT 3
    ''')

    for i, row in enumerate(c.fetchall(), 1):
        print(f'\nعينة {i}:')
        print(f'  الدواء: {row[1]} (ID: {row[0]})')
        print(f'  المادة الفعالة: {row[2]}')
        desc = row[3][:100] + '...' if row[3] and len(row[3]) > 100 else row[3]
        print(f'  الوصف: {desc}')
        print(f'  ATC: {row[4]}')
        print(f'  الروابط: {row[5][:60] if row[5] else "فارغ"}')
    
    # 5. فحص تفصيلي لصف واحد من drug_interactions
    print('\n### 5️⃣  فحص تفصيلي لصف كامل من drug_interactions:')
    print('-'*80)
    c.execute('SELECT * FROM drug_interactions LIMIT 1')
    row = c.fetchone()
    if row:
        for key in row.keys():
            value = row[key]
            if value and len(str(value)) > 100:
                print(f'{key}: {str(value)[:100]}...')
            else:
                print(f'{key}: {value}')

    conn.close()

if __name__ == "__main__":
    inspect_data_quality()
