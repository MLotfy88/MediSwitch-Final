#!/usr/bin/env python3
"""
Data Enrichment Script (Robust Version)
Enriches scraped data with missing columns, translations, and ensures full schema compliance.
Matches logic from scripts/update_meds_csv_from_scraped.py
"""

import pandas as pd
import sys
import os

# --- Translation Dictionaries ---
MAIN_CATEGORIES = {
    'oncology': 'علاج الأورام',
    'diabetes_care': 'العناية بمرضى السكري',
    'skin_care': 'العناية بالبشرة',
    'eye_care': 'العناية بالعيون',
    'ear_care': 'العناية بالأذن',
    'pain_management': 'مسكنات الألم',
    'anesthetics': 'التخدير',
    'anti_inflammatory': 'مضادات الالتهاب',
    'antihistamine': 'مضادات الهيستامين',
    'anti_infective': 'مضادات العدوى',
    'vitamins': 'الفيتامينات',
    'supplements': 'المكملات الغذائية',
    'probiotics': 'البروبيوتيك',
    'respiratory': 'الجهاز التنفسي',
    'digestive': 'الجهاز الهضمي',
    'cardiovascular': 'القلب والأوعية الدموية',
    'neurological': 'الجهاز العصبي',
    'urology': 'المسالك البولية',
    'soothing': 'مهدئات',
    'cosmetics': 'مستحضرات التجميل',
    'personal_care': 'العناية الشخصية',
    'medical_supplies': 'مستلزمات طبية',
    'hormonal': 'الهرمونات',
    'hematology': 'أمراض الدم',
    'musculoskeletal': 'الجهاز العضلي الهيكلي',
    'immunology': 'المناعة',
    'reproductive_health': 'الصحة الإنجابية',
    'herbal_natural': 'أعشاب ومواد طبيعية',
    'baby_care': 'العناية بالطفل',
    'medical_devices': 'أجهزة طبية',
    'diagnostics': 'التشخيص',
    'other': 'أخرى'
}

DOSAGE_FORM_TRANSLATIONS = {
    'tablets': 'أقراص', 'capsules': 'كبسولات', 'syrup': 'شراب', 'suspension': 'معلق',
    'injection': 'حقن', 'ampoules': 'أمبولات', 'ampoule': 'أمبولة', 'vial': 'فيال',
    'cream': 'كريم', 'ointment': 'مرهم', 'gel': 'جل', 'drops': 'نقط',
    'eye_drops': 'نقط للعين', 'eye_ointment': 'مرهم للعين', 'ear_drops': 'نقط للأذن',
    'effervescent': 'فوار', 'nasal_spray': 'بخاخ للأنف', 'inhaler': 'جهاز استنشاق',
    'suppositories': 'لبوس', 'suppository': 'لبوسة', 'powder': 'بودرة', 'sachets': 'أكياس',
    'lozenges': 'أقراص استحلاب', 'shampoo': 'شامبو', 'lotion': 'لوشن', 'solution': 'محلول',
    'spray': 'بخاخ', 'patch': 'لصقة', 'oral_gel': 'جل فموي', 'oral_drops': 'نقط بالفم',
    'oral_suspension': 'معلق فموي', 'effervescent_tablets': 'أقراص فوارة',
    'chewable_tablets': 'أقراص للمضغ', 'soft_gelatin_capsules': 'كبسولات جيلاتينية رخوة',
    'hard_gelatin_capsules': 'كبسولات جيلاتينية صلبة', 'hair_oil': 'زيت شعر',
    'vaginal_suppositories': 'لبوس مهبلي', 'vaginal_cream': 'كريم مهبلي',
    'vaginal_gel': 'جل مهبلي', 'vaginal_douche': 'دش مهبلي', 'enema': 'حقنة شرجية',
    'mouthwash': 'غسول فم', 'toothpaste': 'معجون أسنان', 'soap': 'صابون',
    'intravenous_infusion': 'تسريب وريدي', 'subcutaneous_injection': 'حقن تحت الجلد',
    'intramuscular_injection': 'حقن عضلي', 'topical_solution': 'محلول موضعي',
    'topical_spray': 'بخاخ موضعي', 'topical_gel': 'جل موضعي', 'topical_cream': 'كريم موضعي',
    'transdermal_patch': 'لصقة عبر الجلد', 'film-coated_tablets': 'أقراص مغلفة',
    'extended-release_tablets': 'أقراص ممتدة المفعول', 'delayed-release_capsules': 'كبسولات مؤجلة المفعول',
    'rectal_suppositories': 'لبوس شرجي', 'vaginal_tablets': 'أقراص مهبلية',
    'pre-filled_syringe': 'حقنة معبأة مسبقًا', 'pen': 'قلم', 'piece': 'قطعة',
    'unknown': 'غير معروف', 'tablet': 'قرص', 'capsule': 'كبسولة'
}

USAGE_TRANSLATIONS = {
    'eff': 'فوار', 'oral': 'عن طريق الفم', 'oral.liquid': 'سائل فموي', 'oral.solid': 'صلب فموي',
    'topical': 'موضعي', 'unknown': 'غير معروف', 'injection': 'حقن', 'inhalation': 'استنشاق',
    'rectal': 'شرجي', 'soap': 'صابون', 'spray': 'بخاخ', 'vaginal': 'مهبلي',
    'ophthalmic': 'للعين', 'otic': 'للأذن', 'nasal': 'للأنف', 'sublingual': 'تحت اللسان',
    'buccal': 'شدقي', 'transdermal': 'عبر الجلد', 'intravenous': 'وريدي',
    'intramuscular': 'عضلي', 'subcutaneous': 'تحت الجلد'
}

def safe_str_lower(value):
    return str(value).lower() if value else ''

def enrich_data(input_file, output_file):
    print(f"Reading scraped data from {input_file}...")
    try:
        df = pd.read_csv(input_file, encoding='utf-8-sig', dtype=str)
    except FileNotFoundError:
        print(f"Error: Input file {input_file} not found.")
        return

    print(f"Loaded {len(df)} records")

    # --- Enrichment Logic ---
    records = []
    for idx, row in df.iterrows():
        # Clean row data (handle NaN)
        row_data = {k: str(v).strip() if pd.notna(v) and str(v) != 'nan' else '' for k, v in row.items()}
        
        enriched_record = {
            'id': row_data.get('id', ''),
            'trade_name': row_data.get('trade_name', ''),
            'arabic_name': row_data.get('arabic_name', ''),
            'price': row_data.get('price', '0'),
            'old_price': row_data.get('old_price', '0'),
            'active': row_data.get('active', ''),
            'company': row_data.get('company', ''),
            'description': row_data.get('description', ''),
            'last_price_update': row_data.get('last_price_update', ''),
            'visits': row_data.get('visits', '0'),
            # Retain captured new columns
            'concentration': row_data.get('concentration', ''),
            'pharmacology': row_data.get('pharmacology', ''),
            'barcode': row_data.get('barcode', ''),
            'unit': row_data.get('unit', ''),
            # Fields for translation
            'dosage_form': row_data.get('dosage_form', ''),
            'usage': row_data.get('usage', ''),
            'category': row_data.get('category', ''),
            'main_category': row_data.get('main_category', 'Other')
        }

        # Dosage Form AR
        form_lower = safe_str_lower(enriched_record['dosage_form'])
        enriched_record['dosage_form_ar'] = row_data.get('dosage_form_ar', '')
        if not enriched_record['dosage_form_ar']:
             enriched_record['dosage_form_ar'] = DOSAGE_FORM_TRANSLATIONS.get(form_lower, '')
             if not enriched_record['dosage_form_ar']:
                for key, val in DOSAGE_FORM_TRANSLATIONS.items():
                    if key in form_lower:
                        enriched_record['dosage_form_ar'] = val
                        break

        # Usage AR
        usage_lower = safe_str_lower(enriched_record['usage'])
        enriched_record['usage_ar'] = row_data.get('usage_ar', '')
        if not enriched_record['usage_ar']:
             enriched_record['usage_ar'] = USAGE_TRANSLATIONS.get(usage_lower, '')

        # Category AR
        cat_lower = safe_str_lower(enriched_record['category'])
        enriched_record['category_ar'] = row_data.get('category_ar', '')
        
        main_lower = safe_str_lower(enriched_record['main_category'])
        enriched_record['main_category_ar'] = row_data.get('main_category_ar', '')
        if not enriched_record['main_category_ar']:
             enriched_record['main_category_ar'] = MAIN_CATEGORIES.get(main_lower, 'أخرى')

        records.append(enriched_record)

    # Make DataFrame
    enriched_df = pd.DataFrame(records)

    # Schema Enforcement: Ensure all target columns exist
    final_columns = [
        'id', 'trade_name', 'arabic_name', 'price', 'old_price', 'active', 
        'company', 'description', 'dosage_form', 'dosage_form_ar', 
        'usage', 'usage_ar', 'category', 'category_ar', 
        'main_category', 'main_category_ar', 'concentration', 
        'pharmacology', 'barcode', 'unit', 'visits', 'last_price_update'
    ]

    for col in final_columns:
        if col not in enriched_df.columns:
            enriched_df[col] = ''
    
    # Reorder
    enriched_df = enriched_df[final_columns]

    print(f"\nSaving enriched data to {output_file}...")
    enriched_df.to_csv(output_file, index=False, encoding='utf-8-sig')

    # Stats
    print("\n" + "="*60)
    print("ENRICHMENT STATISTICS")
    print("="*60)
    print(f"Total records: {len(enriched_df)}")
    print(f"Records with concentration: {enriched_df['concentration'].replace('', pd.NA).notna().sum()}")
    print(f"Records with pharmacology: {enriched_df['pharmacology'].replace('', pd.NA).notna().sum()}")
    print("="*60)

if __name__ == "__main__":
    input_f = sys.argv[1] if len(sys.argv) > 1 else "meds_updated.csv"
    output_f = sys.argv[2] if len(sys.argv) > 2 else "meds_enriched.csv"
    enrich_data(input_f, output_f)


import pandas as pd
import re
from datetime import datetime

# Column mapping
ORIGINAL_COLUMNS = [
    'trade_name', 'arabic_name', 'old_price', 'price', 'active',
    'main_category', 'main_category_ar', 'category', 'category_ar',
    'company', 'dosage_form', 'dosage_form_ar', 'unit', 'usage',
    'usage_ar', 'description', 'last_price_update', 'concentration'
]

# Translation dictionaries
DOSAGE_FORM_TRANSLATIONS = {
    'tablet': 'قرص',
    'capsule': 'كبسولة',
    'syrup': 'شراب',
    'suspension': 'معلق',
    'cream': 'كريم',
    'ointment': 'مرهم',
    'gel': 'جل',
    'drops': 'نقط',
    'oral drops': 'نقط فموي',
    'injection': 'حقن',
    'ampoule': 'أمبول',
    'vial': 'فيال',
    'spray': 'بخاخ',
    'inhaler': 'بخاخة',
    'powder': 'بودرة',
    'lotion': 'لوشن',
    'solution': 'محلول',
    'patches': 'لاصقة',
    'suppositories': 'لبوس',
    'pessaries': 'أقماع مهبلية'
}

CATEGORY_MAPPING = {
    'antifungal': ('Dermatology', 'الجلدية'),
    'antibiotic': ('Anti Infective', 'مضادات العدوى'),
    'analgesic': ('Pain Relief', 'مسكنات'),
    'antipyretic': ('Pain Relief', 'مسكنات'),
    'antihistamine': ('Immunology', 'المناعة'),
    'antidepressant': ('Psychiatric', 'الأمراض النفسية'),
    'antipsychotic': ('Psychiatric', 'الأمراض النفسية'),
    'antihypertensive': ('Cardiovascular', 'القلب والأوعية'),
    'antidiabetic': ('Endocrinology', 'الغدد الصماء'),
    'vitamin': ('Nutrition', 'التغذية'),
    'probiotic': ('Nutrition', 'التغذية'),
    'cough': ('Respiratory', 'الجهاز التنفسي'),
    'cold': ('Respiratory', 'الجهاز التنفسي'),
    'gastrointestinal': ('Gastroenterology', 'الجهاز الهضمي'),
    'massage': ('Dermatology', 'الجلدية'),
    'topical': ('Dermatology', 'الجلدية'),
}

USAGE_MAPPING = {
    'tablet': ('Oral.Solid', 'صلب فموي'),
    'capsule': ('Oral.Solid', 'صلب فموي'),
    'syrup': ('Oral.Liquid', 'سائل فموي'),
    'suspension': ('Oral.Liquid', 'سائل فموي'),
    'cream': ('Topical', 'موضعي'),
    'ointment': ('Topical', 'موضعي'),
    'gel': ('Topical', 'موضعي'),
    'drops': ('Drops', 'نقط'),
    'oral drops': ('Oral.Liquid', 'سائل فموي'),
    'injection': ('Injectable', 'حقن'),
    'lotion': ('Topical', 'موضعي'),
    'spray': ('Spray', 'بخاخ'),
}

def translate_dosage_form(form):
    """Translate dosage form to Arabic"""
    if not form or pd.isna(form):
        return ''
    
    form_lower = str(form).lower().strip()
    
    # Exact match
    if form_lower in DOSAGE_FORM_TRANSLATIONS:
        return DOSAGE_FORM_TRANSLATIONS[form_lower]
    
    # Partial match
    for en, ar in DOSAGE_FORM_TRANSLATIONS.items():
        if en in form_lower:
            return ar
    
    return ''

def infer_category(description, active):
    """Infer category from description and active ingredient"""
    text = f"{description} {active}".lower()
    
    for keyword, (cat, cat_ar) in CATEGORY_MAPPING.items():
        if keyword in text:
            return cat, cat_ar
    
    return 'General', 'عام'

def infer_usage(dosage_form):
    """Infer usage from dosage form"""
    if not dosage_form or pd.isna(dosage_form):
        return 'Oral.Solid', 'صلب فموي'
    
    form_lower = str(dosage_form).lower().strip()
    
    for keyword, (usage, usage_ar) in USAGE_MAPPING.items():
        if keyword in form_lower:
            return usage, usage_ar
    
    return 'Oral.Solid', 'صلب فموي'

def enrich_data(scraped_file, output_file):
    """Main enrichment function"""
    print(f"Reading scraped data from {scraped_file}...")
    df = pd.read_csv(scraped_file, encoding='utf-8-sig')
    
    print(f"Loaded {len(df)} records")
    print(f"Current columns: {list(df.columns)}")
    
    # Create new enriched dataframe
    enriched_data = []
    
    for index, row in df.iterrows():
        # Translate dosage form
        dosage_form_ar = translate_dosage_form(row.get('dosage_form', ''))
        
        # Infer category
        main_category, main_category_ar = infer_category(
            row.get('description', ''),
            row.get('active', '')
        )
        
        # Infer usage
        usage, usage_ar = infer_usage(row.get('dosage_form', ''))
        
        # Build enriched record
        enriched_record = {
            'trade_name': row.get('trade_name', ''),
            'arabic_name': row.get('arabic_name', ''),
            'old_price': row.get('old_price', ''),
            'price': row.get('price', ''),
            'active': row.get('active', ''),
            'main_category': main_category,
            'main_category_ar': main_category_ar,
            'category': main_category,  # Same as main for now
            'category_ar': main_category_ar,
            'company': row.get('company', ''),
            'dosage_form': row.get('dosage_form', ''),
            'dosage_form_ar': dosage_form_ar,
            'unit': '1',  # Default to 1
            'usage': usage,
            'usage_ar': usage_ar,
            'description': row.get('description', ''),
            'last_price_update': row.get('last_price_update', ''),
            'concentration': row.get('concentration', ''),
            'visits': row.get('visits', ''),
            'id': row.get('id', '')
        }
        
        enriched_data.append(enriched_record)
        
        if (index + 1) % 1000 == 0:
            print(f"Processed {index + 1}/{len(df)} records...")
    
    # Create final dataframe
    enriched_df = pd.DataFrame(enriched_data)
    
    # Reorder columns to match original schema
    final_columns = [
        'trade_name', 'arabic_name', 'old_price', 'price', 'active',
        'main_category', 'main_category_ar', 'category', 'category_ar',
        'company', 'dosage_form', 'dosage_form_ar', 'unit', 'usage',
        'usage_ar', 'description', 'last_price_update', 'concentration',
        'visits', 'id'
    ]
    
    enriched_df = enriched_df[final_columns]
    
    # Save enriched data
    print(f"\nSaving enriched data to {output_file}...")
    enriched_df.to_csv(output_file, index=False, encoding='utf-8-sig')
    
    # Statistics
    print("\n" + "="*60)
    print("ENRICHMENT STATISTICS")
    print("="*60)
    print(f"Total records: {len(enriched_df)}")
    print(f"Records with dosage_form_ar: {enriched_df['dosage_form_ar'].notna().sum()}")
    print(f"Records with category: {enriched_df['main_category'].notna().sum()}")
    print(f"Records with usage: {enriched_df['usage'].notna().sum()}")
    print("="*60)
    
    # Sample
    print("\nSample of enriched data:")
    print(enriched_df[['trade_name', 'dosage_form', 'dosage_form_ar', 'main_category', 'usage']].head(10).to_string())
    
    return enriched_df

if __name__ == "__main__":
    import sys
    
    input_file = sys.argv[1] if len(sys.argv) > 1 else "meds_updated.csv"
    output_file = sys.argv[2] if len(sys.argv) > 2 else "meds_enriched.csv"
    
    enrich_data(input_file, output_file)
    print(f"\n✓ Enrichment complete! Data saved to {output_file}")
