#!/usr/bin/env python3
"""
Generate ALTER TABLE Migration Script for D1
Compares current schema (from scripts) with required schema and generates migration SQL
"""

# Current Schema (from scripts)
CURRENT_DRUGS = [
    'id', 'trade_name', 'arabic_name', 'old_price', 'price', 'active',
    'main_category', 'main_category_ar', 'category', 'category_ar',
    'company', 'dosage_form', 'dosage_form_ar', 'unit', 'usage', 'usage_ar',
    'description', 'last_price_update', 'concentration', 'visits'
]

CURRENT_MED_DOSAGES = [
    'med_id', 'trade_name', 'active_ingredient', 'adult_dose_mg',
    'pediatric_dose_mg_kg', 'dosage_text', 'json_data', 'last_updated'
]

CURRENT_DRUG_INTERACTIONS = [
    'id', 'ingredient1', 'ingredient2', 'severity', 'effect',
    'recommendation', 'source', 'created_at'
]

# Required Schema (from meds.csv + DailyMed requirements)
REQUIRED_DRUGS = [
    'id', 'trade_name', 'arabic_name', 'price', 'old_price', 'active',
    'company', 'dosage_form', 'dosage_form_ar', 'usage', 'usage_ar',
    'category', 'category_ar', 'main_category', 'main_category_ar',
    'concentration', 'pharmacology', 'barcode', 'unit', 'visits', 'last_price_update'
]

REQUIRED_MED_DOSAGES = [
    'med_id', 'dailymed_setid', 'dailymed_product_name', 'trade_name',
    'active_ingredient', 'adult_dose_mg', 'pediatric_dose_mg_kg',
   'dosage_text', 'matching_confidence', 'json_data', 'last_updated'
]

REQUIRED_DRUG_INTERACTIONS = [
    'id', 'egyptian_drug_id1', 'egyptian_drug_id2', 'dailymed_setid1',
    'dailymed_setid2', 'ingredient1', 'ingredient2', 'severity', 'effect',
    'mechanism', 'recommendation', 'clinical_significance', 'source',
    'confidence_score', 'last_verified', 'created_at'
]

def generate_alter_statements(table_name, current, required):
    """Generate ALTER TABLE ADD COLUMN statements"""
    print(f"\n-- {table_name} Table")
    print('-' * 60)
    
    missing = [col for col in required if col not in current]
    
    if not missing:
        print(f"-- ✅ No new columns needed")
        return
    
    print(f"-- Missing columns: {len(missing)}")
    for col in missing:
        # Determine type
        col_type = 'TEXT'
        default = ''
        
        if col in ['id', 'visits']:
            col_type = 'INTEGER'
        elif col in ['adult_dose_mg', 'pediatric_dose_mg_kg', 'matching_confidence', 'confidence_score']:
            col_type = 'REAL'
            if 'confidence' in col:
                default = ' DEFAULT 0.0' if 'matching' in col else ' DEFAULT 50.0'
        elif col in ['created_at', 'last_updated', 'last_verified']:
            col_type = 'TIMESTAMP'
            if col in ['created_at', 'last_updated']:
                default = ' DEFAULT CURRENT_TIMESTAMP'
        
        print(f"ALTER TABLE {table_name} ADD COLUMN {col} {col_type}{default};")

print("=" * 70)
print("D1 Schema Migration Generator")
print("=" * 70)

generate_alter_statements('drugs', CURRENT_DRUGS, REQUIRED_DRUGS)
generate_alter_statements('med_dosages', CURRENT_MED_DOSAGES, REQUIRED_MED_DOSAGES)
generate_alter_statements('drug_interactions', CURRENT_DRUG_INTERACTIONS, REQUIRED_DRUG_INTERACTIONS)

print("\n" + "=" * 70)
print("✅ Migration script generated")
print("=" * 70)
