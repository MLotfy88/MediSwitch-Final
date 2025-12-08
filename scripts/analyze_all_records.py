#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
قراءة شاملة لكل السجلات في ملف OpenFDA بالكامل
"""
import json
import re

print('⏳ جاري تحميل الملف الكامل...')

# Load data
with open('/tmp/drug_label_analysis/drug-label-0013-of-0013.json', 'r', encoding='utf-8') as f:
    data = json.load(f)
    
results = data.get('results', [])

print(f'✅ تم تحميل {len(results):,} سجل')
print(f'\n{"="*120}')
print(f'📊 قراءة وتحليل كل السجلات بالكامل...')
print(f'{"="*120}\n')

# Comprehensive statistics
stats = {
    'total': len(results),
    'has_substance': 0,
    'has_generic': 0,
    'has_brand': 0,
    'has_spl': 0,
    'has_dosage_forms': 0,
    'has_dosage_admin': 0,
    'has_instructions': 0,
    'has_patient_med_info': 0,
    'has_warnings': 0,
    'has_adverse_reactions': 0,
    'product_types': {},
    'routes': {},
    'dosage_lengths': [],
    'extractable_strength': 0,
    'extractable_standard_dose': 0,
    'extractable_max_dose': 0,
}

# Sample collection (stratified sampling)
samples = {
    'with_complete_data': [],
    'with_partial_data': [],
    'otc_simple': [],
    'prescription_complex': [],
}

print('📈 معالجة السجلات...')

for i, record in enumerate(results):
    if (i + 1) % 1000 == 0:
        print(f'   معالجة سجل {i+1:,} / {len(results):,}')
    
    openfda = record.get('openfda', {})
    
    # Extract fields
    substance = openfda.get('substance_name', [])
    generic = openfda.get('generic_name', [])
    brand = openfda.get('brand_name', [])
    product_type = openfda.get('product_type', [])
    route = openfda.get('route', [])
    
    spl = record.get('spl_product_data_elements', [])
    dosage_forms = record.get('dosage_forms_and_strengths', [])
    dosage_admin = record.get('dosage_and_administration', [])
    instructions = record.get('instructions_for_use', [])
    patient_info = record.get('patient_medication_information', [])
    warnings = record.get('warnings', [])
    adverse = record.get('adverse_reactions', [])
    
    # Track statistics
    if substance:
        stats['has_substance'] += 1
    if generic:
        stats['has_generic'] += 1
    if brand:
        stats['has_brand'] += 1
    if spl:
        stats['has_spl'] += 1
    if dosage_forms:
        stats['has_dosage_forms'] += 1
    if dosage_admin:
        stats['has_dosage_admin'] += 1
        stats['dosage_lengths'].append(len(dosage_admin[0]))
    if instructions:
        stats['has_instructions'] += 1
    if patient_info:
        stats['has_patient_med_info'] += 1
    if warnings:
        stats['has_warnings'] += 1
    if adverse:
        stats['has_adverse_reactions'] += 1
    
    # Product types
    if product_type:
        pt = product_type[0]
        stats['product_types'][pt] = stats['product_types'].get(pt, 0) + 1
    
    # Routes
    if route:
        r = route[0]
        stats['routes'][r] = stats['routes'].get(r, 0) + 1
    
    # Check extractability
    if spl:
        spl_text = spl[0]
        if re.search(r'\b(\d+(?:\.\d+)?\s*(?:mg|mcg|g|ml|%))\b', spl_text, re.IGNORECASE):
            stats['extractable_strength'] += 1
    
    if dosage_admin:
        dosage_text = dosage_admin[0].lower()
        # Standard dose patterns
        if re.search(r'(?:recommended|usual|take)\s*.*?\d+\s*(?:mg|tablet|capsule)', dosage_text):
            stats['extractable_standard_dose'] += 1
        # Max dose patterns
        if re.search(r'(?:maximum|not.*?exceed|up to)\s*.*?\d+\s*(?:mg|tablet)', dosage_text):
            stats['extractable_max_dose'] += 1
    
    # Collect samples (stratified)
    if len(samples['with_complete_data']) < 10:
        if substance and dosage_forms and dosage_admin and len(dosage_admin[0]) > 300:
            samples['with_complete_data'].append({
                'index': i,
                'substance': substance[0][:80],
                'generic': generic[0][:80] if generic else 'N/A',
                'brand': brand[0][:80] if brand else 'N/A',
                'product_type': product_type[0] if product_type else 'N/A',
                'has_dosage_forms': bool(dosage_forms),
                'dosage_length': len(dosage_admin[0]) if dosage_admin else 0,
            })
    
    if len(samples['with_partial_data']) < 10:
        if not substance and brand and dosage_admin and len(dosage_admin[0]) > 200:
            samples['with_partial_data'].append({
                'index': i,
                'brand': brand[0][:80],
                'spl_snippet': spl[0][:100] if spl else 'N/A',
                'dosage_length': len(dosage_admin[0]),
            })
    
    if len(samples['otc_simple']) < 5:
        if product_type and 'OTC' in product_type[0] and dosage_admin:
            samples['otc_simple'].append({
                'index': i,
                'type': product_type[0],
                'has_data': bool(brand or generic),
            })
    
    if len(samples['prescription_complex']) < 10:
        if product_type and 'PRESCRIPTION' in product_type[0] and dosage_admin and len(dosage_admin[0]) > 500:
            samples['prescription_complex'].append({
                'index': i,
                'substance': substance[0][:80] if substance else 'N/A',
                'dosage_length': len(dosage_admin[0]),
            })

print('\n✅ تم الانتهاء من المعالجة!\n')

# Display comprehensive statistics
print(f'{"="*120}')
print(f'📊 الإحصائيات الشاملة لكل الـ {stats["total"]:,} سجل:')
print(f'{"="*120}\n')

print(f'🏷️  معلومات التعريف:')
print(f'   • substance_name: {stats["has_substance"]:,} ({stats["has_substance"]/stats["total"]*100:.1f}%)')
print(f'   • generic_name: {stats["has_generic"]:,} ({stats["has_generic"]/stats["total"]*100:.1f}%)')
print(f'   • brand_name: {stats["has_brand"]:,} ({stats["has_brand"]/stats["total"]*100:.1f}%)')
print(f'   • لديه أي معرّف (substance OR generic OR brand): {max(stats["has_substance"], stats["has_generic"], stats["has_brand"]):,}')

print(f'\n💊 معلومات التركيز والجرعات:')
print(f'   • spl_product_data_elements: {stats["has_spl"]:,} ({stats["has_spl"]/stats["total"]*100:.1f}%)')
print(f'   • dosage_forms_and_strengths: {stats["has_dosage_forms"]:,} ({stats["has_dosage_forms"]/stats["total"]*100:.1f}%)')
print(f'   • dosage_and_administration: {stats["has_dosage_admin"]:,} ({stats["has_dosage_admin"]/stats["total"]*100:.1f}%)')
print(f'   • instructions_for_use: {stats["has_instructions"]:,} ({stats["has_instructions"]/stats["total"]*100:.1f}%)')
print(f'   • patient_medication_information: {stats["has_patient_med_info"]:,} ({stats["has_patient_med_info"]/stats["total"]*100:.1f}%)')

print(f'\n⚠️  معلومات السلامة:')
print(f'   • warnings: {stats["has_warnings"]:,} ({stats["has_warnings"]/stats["total"]*100:.1f}%)')
print(f'   • adverse_reactions: {stats["has_adverse_reactions"]:,} ({stats["has_adverse_reactions"]/stats["total"]*100:.1f}%)')

if stats['dosage_lengths']:
    avg = sum(stats['dosage_lengths']) / len(stats['dosage_lengths'])
    print(f'\n📏 تحليل أطوال نصوص الجرعات:')
    print(f'   • متوسط الطول: {avg:.0f} حرف')
    print(f'   • أقصى طول: {max(stats["dosage_lengths"]):,} حرف')
    print(f'   • أقل طول: {min(stats["dosage_lengths"]):,} حرف')

print(f'\n✅ قابلية الاستخراج (باستخدام regex):')
print(f'   • يمكن استخراج التركيز (strength): {stats["extractable_strength"]:,} ({stats["extractable_strength"]/stats["total"]*100:.1f}%)')
print(f'   • يمكن استخراج الجرعة القياسية: {stats["extractable_standard_dose"]:,} ({stats["extractable_standard_dose"]/stats["has_dosage_admin"]*100:.1f}% من السجلات بجرعات)')
print(f'   • يمكن استخراج الجرعة القصوى: {stats["extractable_max_dose"]:,} ({stats["extractable_max_dose"]/stats["has_dosage_admin"]*100:.1f}% من السجلات بجرعات)')

print(f'\n📦 أنواع المنتجات (الكل):')
sorted_types = sorted(stats['product_types'].items(), key=lambda x: x[1], reverse=True)
for ptype, count in sorted_types:
    print(f'   • {ptype}: {count:,} ({count/stats["total"]*100:.1f}%)')

print(f'\n💉 طرق الإعطاء (أكثر 15):')
sorted_routes = sorted(stats['routes'].items(), key=lambda x: x[1], reverse=True)[:15]
for route, count in sorted_routes:
    print(f'   • {route}: {count:,} ({count/stats["total"]*100:.1f}%)')

# Display sample analysis
print(f'\n\n{"="*120}')
print(f'🔍 تحليل العينات:')
print(f'{"="*120}\n')

print(f'✅ سجلات ببيانات كاملة ({len(samples["with_complete_data"])} عينة):')
for s in samples['with_complete_data'][:5]:
    print(f'   • السجل {s["index"]}: {s["substance"]} | {s["brand"]} | طول الجرعة: {s["dosage_length"]} حرف')

print(f'\n⚠️  سجلات ببيانات جزئية ({len(samples["with_partial_data"])} عينة):')
for s in samples['with_partial_data'][:5]:
    print(f'   • السجل {s["index"]}: Brand: {s["brand"]} | طول الجرعة: {s["dosage_length"]} حرف')

print(f'\n💊 أدوية بوصفة طبية معقدة ({len(samples["prescription_complex"])} عينة):')
for s in samples['prescription_complex'][:5]:
    print(f'   • السجل {s["index"]}: {s["substance"]} | طول: {s["dosage_length"]} حرف')

# Final recommendation
print(f'\n\n{"="*120}')
print(f'🎯 التوصيات النهائية:')
print(f'{"="*120}\n')

potential_records = stats['has_dosage_admin']
with_identifiers = max(stats['has_substance'], stats['has_generic'], stats['has_brand'])

print(f'📈 التقدير المتحفظ للاستخراج:')
print(f'   • السجلات الحالية المستخرجة: ~4,072')
print(f'   • السجلات التي تحتوي على dosage_admin: {potential_records:,}')
print(f'   • السجلات التي تحتوي على معرّف: ~{with_identifiers:,}')
print(f'   • السجلات التي يمكن استخراج strength منها: {stats["extractable_strength"]:,}')
print(f'   • السجلات التي يمكن استخراج standard_dose منها: {stats["extractable_standard_dose"]:,}')
print(f'\n💡 العدد المتوقع بعد التحسين: ~{min(potential_records, stats["extractable_standard_dose"] * 2):,} سجل')
print(f'   (زيادة من 4,072 إلى ~{min(potential_records, stats["extractable_standard_dose"] * 2):,})')
