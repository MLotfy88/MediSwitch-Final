import json
import sqlite3
import pandas as pd
import os
import time
import gzip
import re

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# المسارات
WHO_CSV = "assets/external_research_data/WHO_ATC_DDD_2024.csv"
DOSAGE_JSON = os.path.join(BASE_DIR, 'assets', 'data', 'dosage_guidelines.json.gz')
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
    if not os.path.exists(WHO_CSV):
        print(f"❌ ملف WHO غير موجود: {WHO_CSV}")
        return

    # Create empty list if dosage file doesn't exist
    if not os.path.exists(DOSAGE_JSON):
        print("⚠️ ملف الجرعات غير موجود، سيتم إنشاؤه.")
        dosage_data = [] # Will be populated later or used as base
    else:
        # Check happens later in loading block
        pass

    # --- 0. تجميع قاعدة البيانات (لضمان وجودها) ---
    print("🧩 تجميع قاعدة البيانات من الأجزاء...")
    base_dir = os.path.dirname(os.path.abspath(__file__))
    parts_dir = os.path.join(base_dir, 'assets', 'database', 'parts')
    temp_db_path = os.path.join(base_dir, 'mediswitch.db')
    
    # دائماً نجمع النسخة الطازجة
    if os.path.exists(temp_db_path):
        os.remove(temp_db_path)
    
    parts = sorted([f for f in os.listdir(parts_dir) if f.startswith('mediswitch.db.part-')])
    if not parts:
        print("❌ لم يتم العثور على أجزاء قاعدة البيانات!")
        return
        
    with open(temp_db_path, 'wb') as outfile:
        for part in parts:
            part_path = os.path.join(parts_dir, part)
            with open(part_path, 'rb') as infile:
                outfile.write(infile.read())
    print(f"✅ تم تجميع قاعدة البيانات: {temp_db_path}")

    print("🔗 جاري الاتصال بقاعدة البيانات وبناء خريطة المطابقة...")
    conn = sqlite3.connect(temp_db_path)
    conn.execute("PRAGMA busy_timeout = 10000")
    c = conn.cursor()

    # --- 1. بناء خريطة الأدوية المحلية من جدول med_ingredients ---
    # نستخدم med_ingredients لأنه أدق ويربط كل مادة فعالة بالـ ID
    c.execute("SELECT med_id, ingredient FROM med_ingredients")
    local_drug_map = {}
    
    for med_id, ingredient in c.fetchall():
        if not ingredient: continue
        cleaned = clean_name(ingredient)
        if not cleaned: continue
        
        if cleaned not in local_drug_map:
            local_drug_map[cleaned] = []
        # تجنب التكرار لنفس الدواء
        if med_id not in local_drug_map[cleaned]:
            local_drug_map[cleaned].append(med_id)
            
    print(f"✅ تم تحميل {len(local_drug_map):,} مادة فعالة محلية (من med_ingredients).")

    # --- 2. تحميل ملف الجرعات JSON للتحديث ---
    with open(DOSAGE_JSON, 'r', encoding='utf-8') as f:
        dosage_data = json.load(f)
    
    # خريطة لمعرفة هل يوجد سجل WHO مسبقاً لتجنب التكرار
    # (med_id, atc_code, ddd, route) -> record
    who_existing_map = {}
    for g in dosage_data:
        if g.get('source') == 'WHO ATC/DDD 2024':
            who_existing_map[(g['med_id'], g.get('atc_code'), g.get('min_dose'), g.get('route_code'))] = g

    # أعلى ID مستخدم
    max_id = max([g.get('id', 0) for g in dosage_data]) if dosage_data else 0

    # --- 3. معالجة بيانات WHO ومطابقتها ---
    print("\n🧪 المباشرة في مطابقة بيانات WHO وتحديث الجداول...")
    atc_update_count = 0
    added_count = 0
    
    with open(WHO_CSV, mode='r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row['ddd'] == 'NA' and row['atc_name'] == 'NA': continue
            
            who_drug_name = row['atc_name']
            who_atc = row['atc_code']
            ddd_val = row['ddd']
            adm_r = row['adm_r']
            
            cleaned_who = clean_name(who_drug_name)
            
            # منطق المطابقة
            matched_ids = local_drug_map.get(cleaned_who, [])
            
            if not matched_ids and len(cleaned_who) >= 4:
                for local_clean, ids in local_drug_map.items():
                    if len(local_clean) >= 4:
                        if cleaned_who in local_clean or local_clean in cleaned_who:
                            matched_ids = ids
                            break
            
            if matched_ids:
                for local_id in matched_ids:
                    # أ. تحديث كود ATC
                    c.execute("UPDATE drugs SET atc_codes = ? WHERE id = ? AND (atc_codes IS NULL OR atc_codes = '')", (who_atc, local_id))
                    if c.rowcount > 0: atc_update_count += 1
                    
                    # ب. إضافة سجل WHO إذا لم يكن موجوداً لهذا الدواء (بناءً على med_id + code + ddd + route)
                    try:
                        numeric_ddd = float(ddd_val) if ddd_val != 'NA' else None
                    except: numeric_ddd = None

                    if ddd_val != 'NA' and (local_id, who_atc, numeric_ddd, adm_r) not in who_existing_map:
                        uom = row['uom']
                        note = row['note']
                        
                        route_map = {'O': 'عن طريق الفم', 'P': 'عن طريق الحقن', 'R': 'عن طريق الشرج', 'V': 'عن طريق المهبل', 'Inhal': 'استنشاق', 'N': 'عن طريق الأنف', 'TD': 'عن طريق الجلد'}
                        route_ar = route_map.get(adm_r, adm_r)
                        
                        max_id += 1
                        new_g = {
                            "id": max_id,
                            "med_id": local_id,
                            "dailymed_setid": "N/A",
                            "min_dose": numeric_ddd,
                            "max_dose": None,
                            "frequency": 24,
                            "duration": 7,
                            "instructions": f"الجرعة اليومية المحددة (WHO DDD): {ddd_val} {uom} ({route_ar}). {note if note != 'NA' else ''}".strip(),
                            "condition": "General",
                            "source": "WHO ATC/DDD 2024",
                            "is_pediatric": 0,
                            "atc_code": who_atc,
                            "route_code": adm_r
                        }
                        dosage_data.append(new_g)
                        who_existing_map[(local_id, who_atc, numeric_ddd, adm_r)] = new_g
                        added_count += 1
    
    # حفظ التغييرات
    conn.commit()
    conn.close()
    
    with gzip.open(DOSAGE_JSON, 'wt', encoding='utf-8') as f:
        json.dump(dosage_data, f, ensure_ascii=False, separators=(',', ':'))

    print(f"\n✨ التقرير النهائي:")
    print(f"🔹 تم تحديث أكواد ATC لـ {atc_update_count:,} دواء.")
    print(f"🔹 تم إضافة {added_count:,} سجل جرعات جديد من WHO.")
    print(f"💾 تم حفظ التغييرات في القاعدة و {DOSAGE_JSON}")

    # --- 4. إعادة تقسيم قاعدة البيانات لحفظ التغييرات ---
    print("🧩 إعادة تقسيم قاعدة البيانات إلى أجزاء لحفظها في Git...")
    split_database(temp_db_path, parts_dir)

def split_database(input_file, output_dir, chunk_size=50*1024*1024): # 50MB matches existing parts roughly
    """Split the DB back into parts matching 'split' command naming (aa, ab, ...)"""
    if not os.path.exists(input_file): return
    
    # Clean old parts
    for f in os.listdir(output_dir):
        if f.startswith('mediswitch.db.part-'):
            os.remove(os.path.join(output_dir, f))
            
    # Generate suffixes: aa, ab, ac...
    import string
    chars = string.ascii_lowercase
    suffixes = []
    for c1 in chars:
        for c2 in chars:
            suffixes.append(c1 + c2)
            
    part_num = 0
    with open(input_file, 'rb') as infile:
        while True:
            chunk = infile.read(chunk_size)
            if not chunk: break
            
            if part_num >= len(suffixes):
                print("❌ Too many parts!")
                break
                
            suffix = suffixes[part_num]
            filename = f"mediswitch.db.part-{suffix}"
            output_path = os.path.join(output_dir, filename)
            
            with open(output_path, 'wb') as outfile:
                outfile.write(chunk)
            
            print(f"  ✅ Created {filename}")
            part_num += 1
            
    print(f"✅ تم إنشاء {part_num} جزء بنجاح.")

if __name__ == "__main__":
    enrich_data_high_fidelity()
