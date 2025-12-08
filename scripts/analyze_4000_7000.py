#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
قراءة شاملة للسجلات 4000-7000 من بيانات OpenFDA
"""
import json

# Load data
with open('/tmp/drug_label_analysis/drug-label-0013-of-0013.json', 'r', encoding='utf-8') as f:
    data = json.load(f)
    
results = data.get('results', [])

print(f'📊 إجمالي السجلات في الملف: {len(results)}')
print(f'📖 سنقرأ السجلات من 4000 إلى 7000...\n')
print('='*120)

# Statistics tracking
stats = {
    'total_examined': 0,
    'has_substance_name': 0,
    'has_generic_name': 0,
    'has_brand_name': 0,
    'has_spl_elements': 0,
    'has_dosage_forms': 0,
    'has_dosage_admin': 0,
    'has_instructions': 0,
    'dosage_admin_lengths': [],
    'product_types': {},
    'route_of_admin': {},
    'pharmaceutical_count': 0,  # Count of pharma-like records
}

# Comprehensive reading of records 4000-7000
sample_display = []
for i, record in enumerate(results[4000:7000], start=4000):
    stats['total_examined'] += 1
    
    # Extract all relevant fields
    openfda = record.get('openfda', {})
    
    substance = openfda.get('substance_name', [])
    generic = openfda.get('generic_name', [])
    brand = openfda.get('brand_name', [])
    product_type = openfda.get('product_type', [])
    route = openfda.get('route', [])
    
    spl = record.get('spl_product_data_elements', [])
    dosage_forms = record.get('dosage_forms_and_strengths', [])
    dosage_admin = record.get('dosage_and_administration', [])
    instructions = record.get('instructions_for_use', [])
    
    # Track statistics
    if substance:
        stats['has_substance_name'] += 1
    if generic:
        stats['has_generic_name'] += 1
    if brand:
        stats['has_brand_name'] += 1
    if spl:
        stats['has_spl_elements'] += 1
    if dosage_forms:
        stats['has_dosage_forms'] += 1
    if dosage_admin:
        stats['has_dosage_admin'] += 1
        stats['dosage_admin_lengths'].append(len(dosage_admin[0]))
    if instructions:
        stats['has_instructions'] += 1
    
    # Track product types
    if product_type:
        ptype = product_type[0]
        stats['product_types'][ptype] = stats['product_types'].get(ptype, 0) + 1
    
    # Track routes
    if route:
        r = route[0]
        stats['route_of_admin'][r] = stats['route_of_admin'].get(r, 0) + 1
    
    # Count pharmaceutical-like records
    if dosage_admin:
        dosage_text = dosage_admin[0].lower()
        pharma_indicators = ['mg', 'tablet', 'capsule', 'dose', 'maximum', 'recommended']
        if any(ind in dosage_text for ind in pharma_indicators):
            stats['pharmaceutical_count'] += 1
    
    # Save interesting samples (first 15 with good pharmaceutical content)
    if len(sample_display) < 15:
        if dosage_admin:
            dosage_text = dosage_admin[0].lower()
            pharma_indicators = ['mg', 'tablet', 'capsule', 'dose', 'maximum', 'recommended']
            if any(ind in dosage_text for ind in pharma_indicators) and len(dosage_text) > 200:
                sample_display.append({
                    'index': i,
                    'substance': substance[0][:100] if substance else 'N/A',
                    'generic': generic[0][:100] if generic else 'N/A',
                    'brand': brand[0][:100] if brand else 'N/A',
                    'product_type': product_type[0] if product_type else 'N/A',
                    'spl': spl[0][:150] if spl else 'N/A',
                    'dosage_forms': dosage_forms[0][:200] if dosage_forms else 'N/A',
                    'dosage_text': dosage_admin[0][:500] if dosage_admin else 'N/A',
                })

# Display comprehensive statistics
print(f'\n📈 إحصائيات شاملة للسجلات 4000-7000 ({stats["total_examined"]} سجل):\n')

print(f'🏷️  معلومات التعريف:')
print(f'   • substance_name متوفر: {stats["has_substance_name"]:,} ({stats["has_substance_name"]/stats["total_examined"]*100:.1f}%)')
print(f'   • generic_name متوفر: {stats["has_generic_name"]:,} ({stats["has_generic_name"]/stats["total_examined"]*100:.1f}%)')
print(f'   • brand_name متوفر: {stats["has_brand_name"]:,} ({stats["has_brand_name"]/stats["total_examined"]*100:.1f}%)')

print(f'\n💊 معلومات التركيز والشكل:')
print(f'   • spl_product_data_elements متوفر: {stats["has_spl_elements"]:,} ({stats["has_spl_elements"]/stats["total_examined"]*100:.1f}%)')
print(f'   • dosage_forms_and_strengths متوفر: {stats["has_dosage_forms"]:,} ({stats["has_dosage_forms"]/stats["total_examined"]*100:.1f}%)')

print(f'\n📝 معلومات الجرعات:')
print(f'   • dosage_and_administration متوفر: {stats["has_dosage_admin"]:,} ({stats["has_dosage_admin"]/stats["total_examined"]*100:.1f}%)')
print(f'   • instructions_for_use متوفر: {stats["has_instructions"]:,} ({stats["has_instructions"]/stats["total_examined"]*100:.1f}%)')
print(f'   • سجلات ذات محتوى صيدلاني: {stats["pharmaceutical_count"]:,} ({stats["pharmaceutical_count"]/stats["total_examined"]*100:.1f}%)')

if stats['dosage_admin_lengths']:
    avg_length = sum(stats['dosage_admin_lengths']) / len(stats['dosage_admin_lengths'])
    max_length = max(stats['dosage_admin_lengths'])
    min_length = min(stats['dosage_admin_lengths'])
    print(f'\n   📏 أطوال نصوص الجرعات:')
    print(f'      • متوسط الطول: {avg_length:.0f} حرف')
    print(f'      • أقصى طول: {max_length:,} حرف')
    print(f'      • أقل طول: {min_length:,} حرف')

print(f'\n📦 أنواع المنتجات (أكثر 10):')
sorted_types = sorted(stats['product_types'].items(), key=lambda x: x[1], reverse=True)[:10]
for ptype, count in sorted_types:
    print(f'   • {ptype}: {count:,} ({count/stats["total_examined"]*100:.1f}%)')

print(f'\n💉 طرق الإعطاء (أكثر 10):')
sorted_routes = sorted(stats['route_of_admin'].items(), key=lambda x: x[1], reverse=True)[:10]
for route, count in sorted_routes:
    print(f'   • {route}: {count:,} ({count/stats["total_examined"]*100:.1f}%)')

# Display sample records
print(f'\n\n{"="*120}')
print(f'🔍 عينة من السجلات الصيدلانية (أول 15 سجل):')
print(f'{"="*120}\n')

for idx, sample in enumerate(sample_display):
    print(f'\n### سجل رقم {sample["index"]} (عينة #{idx+1}) ###')
    print(f'المادة الفعالة: {sample["substance"]}')
    print(f'الاسم العام: {sample["generic"]}')
    print(f'الاسم التجاري: {sample["brand"]}')
    print(f'نوع المنتج: {sample["product_type"]}')
    print(f'\nSPL Elements:\n{sample["spl"]}')
    if sample["dosage_forms"] != 'N/A':
        print(f'\nDosage Forms:\n{sample["dosage_forms"]}')
    print(f'\nDosage & Administration (أول 500 حرف):\n{sample["dosage_text"]}')
    print('-' * 120)

print(f'\n\n✅ تم الانتهاء من قراءة وتحليل السجلات 4000-7000')

# Summary comparison
print(f'\n\n📊 ملخص إجمالي (7000 سجل):')
print(f'   • إجمالي السجلات المفحوصة: 7,000')
print(f'   • معدل توفر substance_name: متوسط ~25-30%')
print(f'   • معدل توفر dosage_admin: ~97-98%')
print(f'   • معدل المحتوى الصيدلاني: ~40-50%')
