#!/usr/bin/env python3
"""
سكربت فحص قاعدة بيانات D1 عن بعد
يولد تقرير تفصيلي مشابه للتقرير المحلي
"""

import subprocess
import json
import sys

DB_NAME = "mediswitsh-db"

def run_d1_query(query):
    """تنفيذ استعلام على D1"""
    try:
        result = subprocess.run(
            ['npx', 'wrangler', 'd1', 'execute', DB_NAME, '--remote', '--yes', 
             '--command', query],
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout
    except subprocess.CalledProcessError as e:
        print(f"خطأ في الاستعلام: {e.stderr}", file=sys.stderr)
        return None

def parse_count_result(output):
    """استخراج العدد من نتيجة wrangler"""
    try:
        # البحث عن الرقم في المخرجات
        lines = output.strip().split('\n')
        for line in lines:
            line = line.strip()
            if line.isdigit():
                return int(line)
            # محاولة استخراج من جدول
            if '│' in line and any(c.isdigit() for c in line):
                parts = [p.strip() for p in line.split('│') if p.strip()]
                for part in parts:
                    if part.replace(',', '').isdigit():
                        return int(part.replace(',', ''))
        return 0
    except:
        return 0

def generate_d1_report():
    """توليد تقرير شامل لـ D1"""
    
    print('='*100)
    print('📊 تقرير مزامنة Cloudflare D1 - تقرير ما بعد المزامنة')
    print('='*100)
    
    tables_config = {
        'drugs': {
            'title': 'جدول الأدوية',
            'key_columns': ['id', 'trade_name', 'active', 'description', 'atc_codes']
        },
        'drug_interactions': {
            'title': 'التفاعلات الدوائية',
            'key_columns': ['id', 'ingredient1', 'ingredient2', 'severity', 
                           'alternatives_a', 'alternatives_b', 'reference_text']
        },
        'food_interactions': {
            'title': 'تفاعلات الغذاء',
            'key_columns': ['id', 'med_id', 'ingredient', 'severity', 'management_text']
        },
        'disease_interactions': {
            'title': 'تفاعلات الأمراض',
            'key_columns': ['id', 'med_id', 'disease_name', 'severity', 'reference_text']
        },
        'dosage_guidelines': {
            'title': 'إرشادات الجرعات',
            'key_columns': ['id', 'med_id', 'instructions', 'source']
        },
        'med_ingredients': {
            'title': 'مكونات الأدوية',
            'key_columns': ['med_id', 'ingredient']
        }
    }
    
    summary = []
    
    for table_name, config in tables_config.items():
        print(f'\n{"="*100}')
        print(f'📋 {config["title"]} ({table_name})')
        print('='*100)
        
        # عدد الصفوف
        count_query = f'SELECT COUNT(*) as count FROM {table_name}'
        result = run_d1_query(count_query)
        
        if result is None:
            print(f'⚠️  فشل الاتصال بالجدول')
            continue
        
        total_rows = parse_count_result(result)
        print(f'\n📊 إجمالي الصفوف: {total_rows:,}')
        
        if total_rows == 0:
            print('⚠️  الجدول فارغ!')
            summary.append({
                'table': table_name,
                'title': config['title'],
                'rows': 0,
                'status': '❌ فارغ'
            })
            continue
        
        # فحص أعمدة مهمة
        print(f'\n{"العمود":<30} {"الحالة":>15}')
        print('-'*50)
        
        columns_ok = 0
        for col in config['key_columns']:
            # فحص وجود بيانات في العمود
            check_query = f'SELECT COUNT(*) FROM {table_name} WHERE {col} IS NOT NULL AND {col} != "" LIMIT 1'
            check_result = run_d1_query(check_query)
            
            if check_result and parse_count_result(check_result) > 0:
                print(f'{col:<30} {"✅ يحتوي بيانات":>15}')
                columns_ok += 1
            else:
                print(f'{col:<30} {"⚠️ فارغ":>15}')
        
        fill_pct = (columns_ok / len(config['key_columns']) * 100)
        status = '✅ ممتاز' if fill_pct >= 80 else '⚠️ جيد' if fill_pct >= 50 else '❌ ضعيف'
        
        print(f'\n📈 نسبة ملء الأعمدة الرئيسية: {fill_pct:.1f}%')
        
        summary.append({
            'table': table_name,
            'title': config['title'],
            'rows': total_rows,
            'fill': fill_pct,
            'status': status
        })
    
    # الخلاصة النهائية
    print(f'\n{"="*100}')
    print('📊 خلاصة المزامنة - جميع الجداول')
    print('='*100)
    print(f'\n{"الجدول":<40} {"الصفوف":>15} {"الحالة":>20}')
    print('-'*80)
    
    for item in summary:
        print(f'{item["title"]:<40} {item["rows"]:>15,} {item["status"]:>20}')
    
    # التقييم النهائي
    print('\n' + '='*100)
    print('🎯 التقييم النهائي:')
    print('='*100)
    
    issues = [item for item in summary if item['rows'] == 0]
    
    if not issues:
        print('✅ المزامنة ناجحة 100%!')
        print('✅ جميع الجداول تحتوي على بيانات')
        print('\n🚀 قاعدة البيانات D1 جاهزة للاستخدام!')
        return 0
    else:
        print('⚠️ تم اكتشاف جداول فارغة:')
        for issue in issues:
            print(f'  ❌ {issue["title"]}')
        return 1

if __name__ == '__main__':
    exit_code = generate_d1_report()
    sys.exit(exit_code)
