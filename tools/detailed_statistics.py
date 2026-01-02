#!/usr/bin/env python3
"""
تقرير إحصائي شامل ومفصل لجميع جداول التفاعلات
يعرض عدد الحقول الممتلئة لكل عمود في كل جدول
"""

import sqlite3
import sys

def generate_detailed_stats(db_path='mediswitch.db'):
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    
    print('='*100)
    print('📊 تقرير إحصائي شامل لجداول التفاعلات - MediSwitch Database')
    print('='*100)
    
    # قائمة الجداول المطلوبة
    tables_config = {
        'drugs': {
            'title': 'جدول الأدوية',
            'columns': [
                'id', 'trade_name', 'arabic_name', 'price', 'old_price', 'category', 
                'active', 'company', 'dosage_form', 'dosage_form_ar', 'concentration', 
                'unit', 'usage', 'pharmacology', 'barcode', 'qr_code', 'visits', 
                'last_price_update', 'updated_at', 'indication', 'mechanism_of_action', 
                'pharmacodynamics', 'data_source_pharmacology', 'has_drug_interaction', 
                'has_food_interaction', 'has_disease_interaction', 'description', 
                'atc_codes', 'external_links'
            ]
        },
        'drug_interactions': {
            'title': 'التفاعلات الدوائية',
            'columns': [
                'id', 'ingredient1', 'ingredient2', 'severity', 'effect', 'source',
                'management_text', 'mechanism_text', 'recommendation', 'risk_level', 
                'type', 'metabolism_info', 'source_url', 'reference_text', 
                'alternatives_a', 'alternatives_b', 'updated_at'
            ]
        },
        'food_interactions': {
            'title': 'تفاعلات الغذاء',
            'columns': [
                'id', 'med_id', 'trade_name', 'interaction', 'ingredient', 'severity',
                'management_text', 'mechanism_text', 'reference_text', 'source', 'created_at'
            ]
        },
        'disease_interactions': {
            'title': 'تفاعلات الأمراض',
            'columns': [
                'id', 'med_id', 'trade_name', 'disease_name', 'interaction_text',
                'severity', 'reference_text', 'source', 'created_at'
            ]
        },
        'dosage_guidelines': {
            'title': 'إرشادات الجرعات',
            'columns': [
                'id', 'med_id', 'dailymed_setid', 'min_dose', 'max_dose', 'frequency',
                'duration', 'instructions', 'condition', 'source', 'is_pediatric'
            ]
        },
        'med_ingredients': {
            'title': 'مكونات الأدوية',
            'columns': ['med_id', 'ingredient', 'updated_at']
        }
    }
    
    summary_data = []
    
    for table_name, config in tables_config.items():
        print(f'\n{"="*100}')
        print(f'📋 {config["title"]} ({table_name})')
        print('='*100)
        
        # إجمالي الصفوف
        c.execute(f'SELECT COUNT(*) FROM {table_name}')
        total_rows = c.fetchone()[0]
        print(f'\n📊 إجمالي الصفوف: {total_rows:,}')
        
        if total_rows == 0:
            print('⚠️  الجدول فارغ - تخطي التحليل')
            continue
        
        print(f'\n{"العمود":<30} {"ممتلئ":>15} {"فارغ":>15} {"النسبة":>10} {"الحالة":>10}')
        print('-'*85)
        
        table_stats = []
        
        for col in config['columns']:
            # عدد الحقول الممتلئة
            c.execute(f'''
                SELECT COUNT(*) FROM {table_name} 
                WHERE {col} IS NOT NULL AND {col} != ""
            ''')
            filled = c.fetchone()[0]
            empty = total_rows - filled
            percentage = (filled / total_rows * 100) if total_rows > 0 else 0
            
            # تحديد الحالة
            if percentage >= 95:
                status = '✅ ممتاز'
            elif percentage >= 70:
                status = '⚠️  جيد'
            elif percentage >= 40:
                status = '⚠️  متوسط'
            elif percentage > 0:
                status = '❌ ضعيف'
            else:
                status = '❌ فارغ'
            
            print(f'{col:<30} {filled:>15,} {empty:>15,} {percentage:>9.1f}% {status:>10}')
            
            table_stats.append({
                'table': table_name,
                'column': col,
                'filled': filled,
                'empty': empty,
                'percentage': percentage,
                'status': status
            })
        
        # خلاصة الجدول
        total_cells = total_rows * len(config['columns'])
        c.execute(f'SELECT COUNT(*) FROM {table_name}')
        
        filled_cells = sum(stat['filled'] for stat in table_stats)
        avg_fill = (filled_cells / total_cells * 100) if total_cells > 0 else 0
        
        print('\n' + '─'*85)
        print(f'📈 نسبة الملء الإجمالية للجدول: {avg_fill:.1f}%')
        
        summary_data.append({
            'table': table_name,
            'title': config['title'],
            'rows': total_rows,
            'columns': len(config['columns']),
            'fill_rate': avg_fill
        })
    
    # الخلاصة النهائية
    print(f'\n{"="*100}')
    print('📊 الخلاصة النهائية لجميع الجداول')
    print('='*100)
    print(f'\n{"الجدول":<40} {"الصفوف":>15} {"الأعمدة":>10} {"نسبة الملء":>15}')
    print('-'*85)
    
    for item in summary_data:
        print(f'{item["title"]:<40} {item["rows"]:>15,} {item["columns"]:>10} {item["fill_rate"]:>14.1f}%')
    
    # تقييم عام
    print('\n' + '='*100)
    print('🎯 التقييم النهائي:')
    print('='*100)
    
    issues = []
    for item in summary_data:
        if item['fill_rate'] < 70:
            issues.append(f"⚠️  {item['title']}: نسبة الملء منخفضة ({item['fill_rate']:.1f}%)")
        if item['rows'] == 0:
            issues.append(f"❌ {item['title']}: الجدول فارغ تماماً!")
    
    if not issues:
        print('✅ جميع الجداول في حالة ممتازة!')
        print('✅ البيانات جاهزة للمزامنة مع D1')
        return 0
    else:
        print('تم اكتشاف المشاكل التالية:')
        for issue in issues:
            print(f'  {issue}')
        return 1
    
    conn.close()

if __name__ == '__main__':
    db_path = sys.argv[1] if len(sys.argv) > 1 else 'mediswitch.db'
    exit_code = generate_detailed_stats(db_path)
    sys.exit(exit_code)
