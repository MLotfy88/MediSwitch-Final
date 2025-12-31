#!/usr/bin/env python3
import json
import sys

# فتح الملف
with open('assets/data/interactions/enriched/enriched_rules_part_001.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

print("=" * 60)
print("📊 تحليل بيانات التفاعلات الدوائية")
print("=" * 60)

interactions = data.get('data', [])
print(f"\n✅ عدد التفاعلات في الملف الأول: {len(interactions)}")

if len(interactions) > 0:
    sample = interactions[0]
    
    print(f"\n📋 الحقول المتوفرة في كل تفاعل:")
    print("-" * 60)
    
    fields_to_check = [
        'ingredient1',
        'ingredient2', 
        'severity',
        'effect',
        'arabic_effect',
        'recommendation',
        'arabic_recommendation',
        'management_text',
        'mechanism_text',
        'risk_level',
        'ddinter_id',
        'source'
    ]
    
    for field in fields_to_check:
        value = sample.get(field, '')
        status = "✅ موجود" if value else "❌ فارغ"
        preview = ""
        if value and isinstance(value, str):
            preview = f" (مثال: {value[:50]}...)" if len(value) > 50 else f" ({value})"
        print(f"  {field:25} {status}{preview}")
    
    print(f"\n📈 إحصائيات من أول 50 تفاعل:")
    print("-" * 60)
    
    sample_size = min(50, len(interactions))
    samples = interactions[:sample_size]
    
    rec_count = sum(1 for s in samples if s.get('recommendation'))
    ar_rec_count = sum(1 for s in samples if s.get('arabic_recommendation'))
    mgmt_count = sum(1 for s in samples if s.get('management_text'))
    mech_count = sum(1 for s in samples if s.get('mechanism_text'))
    risk_count = sum(1 for s in samples if s.get('risk_level'))
    
    print(f"  recommendation:         {rec_count}/{sample_size} ({rec_count*100//sample_size}%)")
    print(f"  arabic_recommendation:  {ar_rec_count}/{sample_size} ({ar_rec_count*100//sample_size}%)")
    print(f"  management_text:        {mgmt_count}/{sample_size} ({mgmt_count*100//sample_size}%)")
    print(f"  mechanism_text:         {mech_count}/{sample_size} ({mech_count*100//sample_size}%)")
    print(f"  risk_level:             {risk_count}/{sample_size} ({risk_count*100//sample_size}%)")
    
    print(f"\n🔍 مثال كامل على تفاعل واحد:")
    print("-" * 60)
    print(json.dumps(sample, indent=2, ensure_ascii=False))

print("\n" + "=" * 60)
