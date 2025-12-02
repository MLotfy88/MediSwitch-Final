#!/usr/bin/env python3
"""
Data Enrichment Script
Enriches scraped data with missing columns from original database
Applies translations and fills missing fields
"""

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
