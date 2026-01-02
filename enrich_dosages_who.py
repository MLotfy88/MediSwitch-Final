import json
import csv
import sqlite3
import re
import os
import time

# المسارات
WHO_CSV = "assets/external_research_data/WHO_ATC_DDD_2024.csv"
DOSAGE_JSON = "assets/data/dosage_guidelines.json"
DB_PATH = "mediswitch.db"

def clean_name(name):
    """تنظيف اسم المادة الفعالة (نفس الدالة الأصلية في populate_mediswitch_final.py)"""
    if not name: return ""
    name = re.sub(r'\(.*?\)', '', name)
    salts = ['tromethamine', 'sodium', 'potassium', 'hcl', 'hydrochloride', 'maleate', 'sulfate', 'phosphate', 'fumarate', 'citrate', 'calcium', 'magnesium', 'acetate', 'topical', 'systemic']
    name = name.lower().strip()
    for salt in salts:
        name = name.replace(f" {salt}", "").replace(f"{salt} ", "").strip()
    # تنظيف المسافات والرموز
    name = re.sub(r'[,;.\-\s]+', ' ', name).strip()
    return name

def enrich_data_high_fidelity():
    if not os.path.exists(WHO_CSV) or not os.path.exists(DB_PATH) or not os.path.exists(DOSAGE_JSON):
        print("❌ الملفات المطلوبة غير موجودة!")
        return

    print("🔗 جاري الاتصال بقاعدة البيانات وبناء خريطة المطابقة...")
    conn = sqlite3.connect(DB_PATH)
    conn.execute("PRAGMA busy_timeout = 10000")
    c = conn.cursor()

    # --- 1. بناء خريطة الأدوية المحلية بنفس منطق DDInter ---
    c.execute("SELECT id, active FROM drugs WHERE active IS NOT NULL")
    local_drug_map = {}
    for local_id, active in c.fetchall():
        cleaned = clean_name(active)
        if cleaned not in local_drug_map:
            local_drug_map[cleaned] = []
        local_drug_map[cleaned].append(local_id)
    print(f"✅ تم تحميل {len(local_drug_map):,} مادة فعالة محلية.")

    # --- 2. تحميل ملف الجرعات JSON للتحديث ---
    with open(DOSAGE_JSON, 'r', encoding='utf-8') as f:
        dosage_data = json.load(f)
    # خريطة لسهولة الوصول للجرعات بالـ med_id
    dosage_map = {g['med_id']: g for g in dosage_data.get('dosage_guidelines', [])}

    # --- 3. معالجة بيانات WHO ومطابقتها ---
    print("\n🧪 المباشرة في مطابقة بيانات WHO وتحديث الجداول...")
    atc_update_count = 0
    dosage_enrich_count = 0
    
    with open(WHO_CSV, mode='r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row['ddd'] == 'NA' and row['atc_name'] == 'NA': continue
            
            who_drug_name = row['atc_name']
            who_atc = row['atc_code']
            cleaned_who = clean_name(who_drug_name)
            
            # منطق المطابقة (Direct ثم Fuzzy) كما في DDInter
            matched_ids = local_drug_map.get(cleaned_who, [])
            
            if not matched_ids and len(cleaned_who) >= 4:
                for local_clean, ids in local_drug_map.items():
                    if len(local_clean) >= 4:
                        if cleaned_who in local_clean or local_clean in cleaned_who:
                            matched_ids = ids
                            break
            
            if matched_ids:
                for local_id in matched_ids:
                    # أ. تحديث كود ATC في جدول الأدوية (Enrichment)
                    c.execute("UPDATE drugs SET atc_codes = ? WHERE id = ? AND (atc_codes IS NULL OR atc_codes = '')", (who_atc, local_id))
                    if c.rowcount > 0: atc_update_count += 1
                    
                    # ب. تحديث بيانات الجرعات إذا كانت الجودة منخفضة
                    if local_id in dosage_map:
                        g = dosage_map[local_id]
                        if "See package insert" in g.get('instructions', '') or g.get('source') == 'Local_Scraper':
                            ddd = row['ddd']
                            uom = row['uom']
                            adm_r = row['adm_r']
                            route_map = {'O': 'عن طريق الفم', 'P': 'عن طريق الحقن', 'R': 'عن طريق الشرج', 'V': 'عن طريق المهبل', 'Inhal': 'استنشاق', 'N': 'عن طريق الأنف', 'TD': 'عن طريق الجلد'}
                            route_ar = route_map.get(adm_r, adm_r)
                            
                            if ddd != 'NA':
                                g['instructions'] = f"الجرعة اليومية المحددة (WHO DDD): {ddd} {uom} ({route_ar})."
                                g['min_dose'] = float(ddd)
                                g['source'] = 'WHO ATC/DDD 2024'
                                dosage_enrich_count += 1

    # حفظ التغييرات
    conn.commit()
    conn.close()
    
    with open(DOSAGE_JSON, 'w', encoding='utf-8') as f:
        json.dump(dosage_data, f, indent=2, ensure_ascii=False)

    print(f"\n✨ التقرير النهائي:")
    print(f"🔹 تم تحديث أكواد ATC لـ {atc_update_count:,} دواء.")
    print(f"🔹 تم إثراء {dosage_enrich_count:,} سجل جرعات من WHO.")
    print(f"💾 تم حفظ التغييرات في القاعدة و {DOSAGE_JSON}")

if __name__ == "__main__":
    enrich_data_high_fidelity()
