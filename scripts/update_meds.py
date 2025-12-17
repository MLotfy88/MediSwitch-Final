#!/usr/bin/env python3
"""
Update Meds CSV from Scraped Details (Strict Overwrite Mode)
Reads: assets/meds_scraped_new.jsonl
Writes: assets/meds.csv (Complete Overwrite)
Backups: assets/meds_backup.csv, backups/meds_backup_DATE.csv
"""

import pandas as pd
import json
import os
import shutil
import sys
import datetime

# --- Path Configuration ---
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRAPED_DB = os.path.join(BASE_DIR, 'assets', 'meds_scraped_new.jsonl')
MEDS_CSV = os.path.join(BASE_DIR, 'assets', 'meds.csv')
MEDS_BACKUP_CSV = os.path.join(BASE_DIR, 'assets', 'meds_backup.csv')
BACKUP_DIR = os.path.join(BASE_DIR, 'backups')

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
    'tablet': 'أقراص', 'tablets': 'أقراص', 'tab': 'أقراص', 'tabs': 'أقراص', 'tabs.': 'أقراص',
    'capsule': 'كبسولات', 'capsules': 'كبسولات', 'cap': 'كبسولات', 'caps': 'كبسولات',
    'syrup': 'شراب', 'suspension': 'معلق', 'susp': 'معلق',
    'injection': 'حقن', 'inj': 'حقن', 'ampoule': 'أمبول', 'ampoules': 'أمبولات', 'amp': 'أمبول',
    'vial': 'فيال', 'syringe': 'حقنة', 'pen': 'قلم',
    'cream': 'كريم', 'ointment': 'مرهم', 'oint': 'مرهم', 'gel': 'جل',
    'lotion': 'لوشن', 'solution': 'محلول', 'sol': 'محلول',
    'spray': 'بخاخ', 'inhaler': 'جهاز استنشاق',
    'drops': 'نقط', 'drop': 'نقط', 'oral drops': 'نقط للفم', 'ear drops': 'نقط للأذن',
    'eye drops': 'نقط للعين', 'nasal drops': 'نقط للأنف', 'mouth drops': 'نقط للفم',
    'eye ointment': 'مرهم للعين',
    'suppository': 'لبوس', 'suppositories': 'لبوس', 'supp': 'لبوس',
    'powder': 'بودرة', 'sachet': 'أكياس', 'sachets': 'أكياس',
    'effervescent': 'فوار', 'eff': 'فوار',
    'lozenges': 'استحلاب',
    'mouth wash': 'غسول للفم', 'gargle': 'غرغرة', 'toothpaste': 'معجون أسنان',
    'shampoo': 'شامبو', 'conditioner': 'بلسم', 'hair oil': 'زيت شعر',
    'soap': 'صابون', 'facial wash': 'غسول للوجه', 'cleanser': 'منظف',
    'patch': 'لصقة', 'film': 'فيلم',
    'foam': 'فوم', 'paint': 'مس/دهان',
    'oil': 'زيت', 'serum': 'سيروم',
    'vaginal douche': 'دش مهبلي', 'vaginal wash': 'غسول مهبلي',
    'bottle': 'زجاجة', 'piece': 'قطعة',
    'unknown': 'غير محدد'
}

def safe_str_lower(value):
    return str(value).lower() if value else ''

def main():
    print(f"🔄 Updating meds.csv from {SCRAPED_DB}...")
    
    if not os.path.exists(SCRAPED_DB):
        print("❌ Scraped DB not found. Run scraper first.")
        sys.exit(1)
        
    # 1. Backup Existing CSVs (Safe Backup)
    if os.path.exists(MEDS_CSV):
        # Check if MEDS_CSV is valid/substantial before backing up
        # This prevents the scraper's "wipe" from destroying the backup source
        is_valid_csv = False
        try:
            if os.path.getsize(MEDS_CSV) > 100: # Arbitrary small threshold
                is_valid_csv = True
            else:
                # Double check line count
                with open(MEDS_CSV, 'r') as f:
                    if len(f.readlines()) > 5:
                         is_valid_csv = True
        except: pass

        if is_valid_csv:
            print("💾 Creating Backups...")
            os.makedirs(BACKUP_DIR, exist_ok=True)
            timestamp = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
            
            # Backup 1: To backups/ folder with timestamp
            backup_path = os.path.join(BACKUP_DIR, f'meds_backup_{timestamp}.csv')
            shutil.copy(MEDS_CSV, backup_path)
            print(f"   -> {backup_path}")
            
            # Backup 2: To assets/meds_backup.csv (Overwrite previous backup)
            shutil.copy(MEDS_CSV, MEDS_BACKUP_CSV)
            print(f"   -> {MEDS_BACKUP_CSV}")
        else:
            print("⚠️ Skipping backup: meds.csv is too small/empty (preventing data loss).")

    # 2. Load Scraped Data
    scraped_map = {}
    print(f"📂 Loading scraped data...")
    with open(SCRAPED_DB, 'r', encoding='utf-8') as f:
        for line in f:
            if line.strip():
                try:
                    rec = json.loads(line)
                    mid = str(rec.get('id', ''))
                    if mid:
                        scraped_map[mid] = rec
                except json.JSONDecodeError as e:
                    print(f"❌ JSON Error in line: {e} | Content: {line[:50]}...")
                except Exception as e:
                    print(f"❌ Error parsing line: {e}")
    
    count = len(scraped_map)
    print(f"✅ Loaded {count} scraped records.")
    
    if count == 0:
        print("⚠️  Warning: Scraped data is empty! Aborting overwrite to prevent data loss.")
        sys.exit(1)

    # 3. Build New Records (Strict Overwrite)
    print("🔨 Processing records (Wiping old data)...")
    records = []
    
    for mid, rec in scraped_map.items():
        # Handle date mapping robustly
        date_val = rec.get('last_update') or rec.get('last_price_update') or ''
        
        # Base Row
        row = {
            'id': mid,
            'trade_name': rec.get('trade_name', ''),
            'arabic_name': rec.get('arabic_name', ''),
            'price': rec.get('price', ''),
            'old_price': rec.get('old_price', ''),
            'active': rec.get('active', ''),
            'company': rec.get('company', ''),
            'category': rec.get('category', ''),
            'last_price_update': date_val,
            'visits': rec.get('visits', ''),
            'concentration': rec.get('concentration', ''),
            'pharmacology': rec.get('pharmacology', ''),
            'barcode': rec.get('barcode', ''),
            'unit': rec.get('units', ''),
            'dosage_form': rec.get('dosage_form', ''),
            'usage': rec.get('usage', ''),
        }
        
        # --- Translation & Enrichment ---
        
        # Dosage Form AR
        # 1. Try Scraper's translation first
        row['dosage_form_ar'] = rec.get('dosage_form_ar', '')
        
        # 2. If empty, try matching from map
        if not row['dosage_form_ar']:
            form_lower = safe_str_lower(row['dosage_form'])
            # Direct match
            row['dosage_form_ar'] = DOSAGE_FORM_TRANSLATIONS.get(form_lower, '')
            # Substring match fallback
            if not row['dosage_form_ar']:
                for key, val in DOSAGE_FORM_TRANSLATIONS.items():
                    if key in form_lower:
                        row['dosage_form_ar'] = val
                        break
        
        records.append(row)

    # 4. Create DataFrame & Save
    df = pd.DataFrame(records)
    
    # Define Column Order (Schema) - Removed usage_ar, category_ar, etc. per user request
    desired_columns = [
        'id', 'trade_name', 'arabic_name', 'price', 'old_price', 'active', 
        'company', 'dosage_form', 'dosage_form_ar', 
        'usage', 'category', 'concentration', 
        'pharmacology', 'barcode', 'unit', 'visits', 'last_price_update'
    ]
    
    # Ensure all columns exist
    for col in desired_columns:
        if col not in df.columns:
            df[col] = ''
            
    # Remove duplicates columns if any (by name)
    df = df.loc[:, ~df.columns.duplicated()]
    
    # Reorder and Select (Strict)
    df = df[desired_columns]
    
    # Save (Overwrite)
    df.to_csv(MEDS_CSV, index=False, encoding='utf-8-sig') # Use utf-8-sig for Excel compatibility
    print(f"✅ SUCCESS: Wiped old data and wrote {len(df)} records to {MEDS_CSV}")

if __name__ == "__main__":
    main()
