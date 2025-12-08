#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
تحليل بيانات OpenFDA الخام لفهم أنماط كتابة الجرعات
"""
import json
import re

# Load data
with open('/tmp/drug_label_analysis/drug-label-0013-of-0013.json', 'r', encoding='utf-8') as f:
    data = json.load(f)
    
results = data.get('results', [])

print(f'📊 إجمالي السجلات: {len(results)}')
print('='*100)

# Find pharmaceutical drugs with complex dosage info
pharma_examples = []

for i, record in enumerate(results):
    if len(pharma_examples) >= 10:
        break
    
    dosage_admin = record.get('dosage_and_administration', [])
    if not dosage_admin:
        continue
    
    dosage_text = dosage_admin[0]
    
    # Look for pharmaceutical keywords
    pharma_keywords = ['mg', 'tablet', 'capsule', 'recommended dose', 'adult', 'maximum', 'daily']
    if not any(kw in dosage_text.lower() for kw in pharma_keywords):
        continue
    
    # Skip simple OTC products
    skip_keywords = ['hand sanitizer', 'toothpaste', 'apply a film', 'mouthwash']
    if any(skip in dosage_text.lower() for skip in skip_keywords):
        continue
    
    # Must have substantial dosage text (not just directions for use)
    if len(dosage_text) < 100:
        continue
    
    openfda = record.get('openfda', {})
    substance = openfda.get('substance_name', ['Unknown'])[0] if openfda.get('substance_name') else None
    generic = openfda.get('generic_name', ['Unknown'])[0] if openfda.get('generic_name') else None
    brand = openfda.get('brand_name', ['Unknown'])[0] if openfda.get('brand_name') else None
    
    # Need at least one name
    if not substance and not generic:
        continue
    
    pharma_examples.append({
        'substance': substance or generic,
        'generic': generic,
        'brand': brand,
        'spl': record.get('spl_product_data_elements', []),
        'dosage_forms': record.get('dosage_forms_and_strengths', []),
        'dosage_text': dosage_text,
        'instructions': record.get('instructions_for_use', []),
    })

print(f'\n✅ تم العثور على {len(pharma_examples)} دواء صيدلاني\n')

# Analyze patterns
for idx, ex in enumerate(pharma_examples):
    print(f'\n{"#"*100}')
    print(f'مثال رقم {idx+1}')
    print(f'{"#"*100}')
    
    print(f'\n🏷️  معلومات الدواء:')
    print(f'   • المادة الفعالة: {ex["substance"]}')
    print(f'   • الاسم العام: {ex["generic"]}')
    print(f'   • الاسم التجاري: {ex["brand"]}')
    
    # Strength analysis
    if ex['spl']:
        print(f'\n💊 SPL Elements (حقل التركيز):')
        spl_text = ex['spl'][0][:200]
        print(f'   {spl_text}')
        
        # Try to extract strength
        strength_match = re.search(r'\b(\d+(?:\.\d+)?\s*(?:mg|mcg|g|ml|%|mg/ml))\b', spl_text, re.IGNORECASE)
        if strength_match:
            print(f'   ✓ التركيز المستخرج: {strength_match.group(1)}')
    
    if ex['dosage_forms']:
        print(f'\n📋 Dosage Forms & Strengths:')
        print(f'   {ex["dosage_forms"][0][:200]}')
    
    # Dosage text analysis
    print(f'\n📝 نص الجرعة الكامل (Dosage & Administration):')
    dosage = ex['dosage_text']
    
    # Show first 600 characters
    print(dosage[:600])
    if len(dosage) > 600:
        print(f'   ... (و {len(dosage) - 600} حرف إضافي)')
    
    # Pattern matching analysis
    print(f'\n🔍 تحليل الأنماط المكتشفة:')
    
    # Standard dose patterns
    standard_patterns = [
        (r'recommended dose.*?(\d+(?:\.\d+)?\s*(?:mg|mcg|g|tablet|capsule))', 'جرعة موصى بها'),
        (r'usual dose.*?(\d+(?:\.\d+)?\s*(?:mg|mcg|g|tablet|capsule))', 'جرعة معتادة'),
        (r'(\d+(?:\.\d+)?\s*(?:mg|mcg|g))\s+(?:once|twice|three times)', 'جرعة مع توقيت'),
        (r'(\d+\s*to\s*\d+)\s*(?:tablet|capsule)', 'جرعة بنطاق'),
        (r'take\s*(\d+(?:\.\d+)?\s*(?:tablet|capsule))', 'تعليمات الأخذ'),
    ]
    
    for pattern, description in standard_patterns:
        matches = re.findall(pattern, dosage.lower())
        if matches:
            print(f'   ✓ {description}: {matches[0]}')
    
    # Max dose patterns
    max_patterns = [
        (r'maximum.*?(\d+(?:\.\d+)?\s*(?:mg|mcg|g|tablet))', 'الجرعة القصوى'),
        (r'not.*?exceed.*?(\d+(?:\.\d+)?\s*(?:mg|mcg|g|tablet))', 'لا تتجاوز'),
        (r'up to\s*(\d+(?:\.\d+)?\s*(?:mg|mcg|g))', 'حتى'),
    ]
    
    for pattern, description in max_patterns:
        matches = re.findall(pattern, dosage.lower())
        if matches:
            print(f'   ✓ {description}: {matches[0]}')
    
    print('\n' + '-'*100)

# Summary Statistics
print(f'\n\n📊 ملخص الإحصائيات:')
print(f'   • إجمالي السجلات المفحوصة: {len(results)}')
print(f'   • سجلات الأدوية الصيدلانية: {len(pharma_examples)}')
print(f'   • نسبة الأدوية الصيدلانية: {len(pharma_examples)/len(results)*100:.2f}%')

# Analyze extraction success rate
with_substance = sum(1 for ex in pharma_examples if ex['substance'])
with_spl = sum(1 for ex in pharma_examples if ex['spl'])
with_dosage_forms = sum(1 for ex in pharma_examples if ex['dosage_forms'])

print(f'\n   📌 معدل توفر الحقول:')
print(f'      • substance_name: {with_substance}/{len(pharma_examples)} ({with_substance/len(pharma_examples)*100:.0f}%)')
print(f'      • spl_product_data_elements: {with_spl}/{len(pharma_examples)} ({with_spl/len(pharma_examples)*100:.0f}%)')
print(f'      • dosage_forms_and_strengths: {with_dosage_forms}/{len(pharma_examples)} ({with_dosage_forms/len(pharma_examples)*100:.0f}%)')
