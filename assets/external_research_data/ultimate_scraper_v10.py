#!/usr/bin/env python3
"""
DDInter2 Ultimate Scraper v10 - API Edition
============================================
سكرابر نهائي يستخدم API endpoints المكتشفة
- سرعة فائقة (100x أسرع من Selenium)
- دعم Resume/استكمال كامل
- يعمل على GitHub Actions
- جمع شامل لجميع البيانات

API Endpoints المستخدمة:
- /server/interact-with/{drug_id}/       → Drug-Drug interactions
- /server/interact-with-food/{drug_id}/  → Drug-Food interactions  
- /server/interact-with-multi/{drug_id}/ → Compound preparations
"""

import re
import requests
import sqlite3
import json
import os
import time
import urllib3
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime
from collections import Counter
from bs4 import BeautifulSoup
import threading

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# ============================================
# Configuration
# ============================================
DB_PATH = 'ddinter_complete.db'
SCHEMA_SQL = 'database_schema.sql'
DRUG_IDS_FILE = 'unique_drugs.json'
BASE_URL = 'https://ddinter2.scbdd.com'
MAX_WORKERS = 20
REQUEST_TIMEOUT = 30

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Referer': 'https://ddinter2.scbdd.com/',
    'Connection': 'keep-alive'
}

# ============================================
# Utility Classes
# ============================================
class ThreadSafeCounter:
    def __init__(self):
        self._value = 0
        self._lock = threading.Lock()

    def increment(self):
        with self._lock:
            self._value += 1
            return self._value

    def get(self):
        with self._lock:
            return self._value

stats = {
    'drugs_processed': ThreadSafeCounter(),
    'ddi_fetched': ThreadSafeCounter(),
    'dfi_fetched': ThreadSafeCounter(),
    'dsi_fetched': ThreadSafeCounter(),
    'multi_fetched': ThreadSafeCounter(),
    'errors': ThreadSafeCounter(),
    'details_enriched': ThreadSafeCounter()
}

# ============================================
# Phase 2: Detail Enrichment Functions
# ============================================
def fetch_interaction_details(interaction_id):
    """جلب تفاصيل التفاعل النصية من صفحة HTML"""
    url = f"{BASE_URL}/server/interact/{interaction_id}/"
    try:
        response = requests.get(url, headers=HEADERS, timeout=REQUEST_TIMEOUT, verify=False)
        if response.status_code != 200:
            return None
        
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # 1. Interaction Description
        # البحث عن خلية تحتوي على "Interaction" ثم الخلية التي تليها
        desc_cell = soup.find('td', class_='key', string=re.compile(r'Interaction', re.I))
        description = None
        if desc_cell:
            val_cell = desc_cell.find_next_sibling('td', class_='value')
            if val_cell:
                description = val_cell.get_text(strip=True)

        # 2. Management
        # البحث عن خلية تحتوي على "Management"
        mgmt_cell = soup.find('td', class_='key', string=re.compile(r'Management', re.I))
        management = None
        if mgmt_cell:
            val_cell = mgmt_cell.find_next_sibling('td', class_='value')
            if val_cell:
                management = val_cell.get_text(strip=True)
                
        # 3. References
        # البحث عن عنصر بمعرف reference-text
        ref_elem = soup.find(id='reference-text')
        references = None
        if ref_elem:
            # استخراج النصوص من داخل span
            refs = [span.get_text(strip=True) for span in ref_elem.find_all('span')]
            if refs:
                references = "\\n".join(refs)
            else:
                references = ref_elem.get_text(strip=True)

        # إذا لم نجد أي بيانات، نعتبرها فشل
        if not description and not management:
            return None

        return {
            'interaction_id': interaction_id,
            'interaction_description': description,
            'management_text': management,
            'reference_text': references
        }

    except Exception as e:
        # print(f"⚠️ Error details for {interaction_id}: {e}") # Silent error to reduce noise
        return None

def fetch_interaction_alternatives(interaction_id):
    """جلب البدائل الآمنة من صفحة التفاعل"""
    url = f"{BASE_URL}/server/interact/{interaction_id}/"
    try:
        response = requests.get(url, headers=HEADERS, timeout=REQUEST_TIMEOUT, verify=False)
        if response.status_code != 200:
            return None, None
        
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # استخراج البدائل
        alternatives_a = []
        alternatives_b = []
        
        # البحث عن قسم "Alternative for"
        key_cells = soup.find_all('td', class_='key')
        for i, key_cell in enumerate(key_cells):
            text = key_cell.get_text(strip=True)
            if 'Alternative for' in text:
                value_cell = key_cell.find_next_sibling('td', class_='value')
                if value_cell:
                    # استخراج أسماء الأدوية من الروابط
                    links = value_cell.find_all('a', href=lambda x: x and 'drug-detail' in x)
                    alts = [link.get_text(strip=True) for link in links if link.get_text(strip=True)]
                    
                    # تحديد الدواء A أو B
                    if len(alternatives_a) == 0:
                        alternatives_a = alts
                    else:
                        alternatives_b = alts
        
        return alternatives_a if alternatives_a else None, alternatives_b if alternatives_b else None
        
    except Exception as e:
        # print(f"⚠️ Error fetching alternatives for {interaction_id}: {e}")
        return None, None


def update_interaction_details(details):
    """تحديث قاعدة البيانات بالتفاصيل الجديدة مع alternatives"""
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    try:
        c.execute('''
            UPDATE drug_drug_interactions
            SET interaction_description = ?,
                management_text = ?,
                reference_text = ?,
                alternative_drugs_a = ?,
                alternative_drugs_b = ?
            WHERE interaction_id = ?
        ''', (
            details.get('interaction_description'),
            details.get('management_text'),
            details.get('reference_text'),
            details.get('alternatives_a'),
            details.get('alternatives_b'),
            details.get('interaction_id')
        ))
        conn.commit()
        return True
    except Exception as e:
        print(f"❌ DB Error update {details['interaction_id']}: {e}")
        return False
    finally:
        conn.close()

def process_enrichment_item(interaction_id):
    """معالجة عنصر واحد في مرحلة الإثراء - مع alternatives"""
    details = fetch_interaction_details(interaction_id)
    if details:
        # جلب البدائل أيضاً
        alt_a, alt_b = fetch_interaction_alternatives(interaction_id)
        if alt_a or alt_b:
            details['alternatives_a'] = json.dumps(alt_a) if alt_a else None
            details['alternatives_b'] = json.dumps(alt_b) if alt_b else None
        
        if update_interaction_details(details):
            stats['details_enriched'].increment()
            return True
    return False

def get_interactions_needing_enrichment():
    """الحصول على التفاعلات التي تنقصها التفاصيل"""
    print("running query to find missing details...") 
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    # نختار التفاعلات التي فيها الوصف فارغ
    c.execute("SELECT interaction_id FROM drug_drug_interactions WHERE interaction_description IS NULL OR interaction_description = ''")
    ids = [row[0] for row in c.fetchall()]
    conn.close()
    return ids

def run_phase_2_enrichment():
    """تشغيل المرحلة الثانية: إثراء البيانات بالتفاصيل"""
    print("\n" + "="*70)
    print("🚀 Phase 2: Enriching Interaction Details (Texts)")
    print("="*70)
    
    missing_ids = get_interactions_needing_enrichment()
    
    if not missing_ids:
        print("✅ No interactions pending enrichment! (All have descriptions)")
        return

    print(f"📦 Found {len(missing_ids)} interactions needing text details.")
    print(f"🔄 Starting enrichment with {MAX_WORKERS} workers...")
    
    start_time = time.time()
    
    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        # تقسيم العمل إلى دفعات صغيرة لتحديث واجهة المستخدم
        batch_size = 1000
        total_processed = 0
        
        for i in range(0, len(missing_ids), batch_size):
            batch = missing_ids[i:i+batch_size]
            futures = {executor.submit(process_enrichment_item, iid): iid for iid in batch}
            
            for future in as_completed(futures):
                iid = futures[future]
                try:
                    future.result()
                except Exception:
                    pass
            
            total_processed += len(batch)
            elapsed = time.time() - start_time
            rate = total_processed / elapsed if elapsed > 0 else 0
            remaining = len(missing_ids) - total_processed
            eta = remaining / rate / 60 if rate > 0 else 0
            
            print(f"📈 Progress: {stats['details_enriched'].get()}/{len(missing_ids)} | Rate: {rate:.1f}/s | ETA: {eta:.1f} min")

    print("✅ Phase 2 Completed!")


# ============================================
# Main Execution
# ============================================
def main():
    print("="*70)
    print("🚀 DDInter2 Ultimate Scraper v10.1 - Full Stack")
    print("="*70)
    print(f"⏰ Start time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # 1. تهيئة قاعدة البيانات
    if not os.path.exists(DB_PATH):
        if not init_database():
            return
    else:
        print(f"📦 Using existing database: {DB_PATH}")
    
    # Phase 1: API Scraping (IDs & Lists)
    print("\n🔹 Checking Phase 1 (Core Data)...")
    all_drug_ids = load_drug_ids()
    if all_drug_ids:
        pending_drugs = get_pending_drugs(all_drug_ids)
        if pending_drugs:
            print(f"\n🔄 Phase 1: Processing {len(pending_drugs)} remaining drugs...")
            with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
                futures = {executor.submit(process_single_drug, drug_id): drug_id for drug_id in pending_drugs}
                for future in as_completed(futures):
                    try:
                        future.result()
                    except:
                        pass
        else:
            print("✅ Phase 1 Complete (All drugs processed).")

    # Phase 2: Detail Enrichment
    print("\n🔹 Checking Phase 2 (Text Details)...")
    run_phase_2_enrichment()
    
    # Final Stats
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute("SELECT COUNT(*) FROM drugs")
    total_drugs = c.fetchone()[0]
    c.execute("SELECT COUNT(*) FROM drug_drug_interactions")
    total_ddi = c.fetchone()[0]
    c.execute("SELECT COUNT(*) FROM drug_drug_interactions WHERE interaction_description IS NOT NULL AND interaction_description != ''")
    enriched_ddi = c.fetchone()[0]
    conn.close()
    
    print(f"\n📊 Final Statistics:")
    print(f"   Drugs: {total_drugs}")
    print(f"   Interactions: {total_ddi}")
    print(f"   Enriched with Text: {enriched_ddi} ({(enriched_ddi/total_ddi*100) if total_ddi else 0:.1f}%)")
    print("="*70)

# ============================================
# Database Functions
# ============================================
def init_database():
    """إنشاء قاعدة البيانات"""
    print("📦 Initializing database...")
    
    if not os.path.exists(SCHEMA_SQL):
        print(f"❌ Schema file not found: {SCHEMA_SQL}")
        return False
    
    conn = sqlite3.connect(DB_PATH)
    with open(SCHEMA_SQL, 'r', encoding='utf-8') as f:
        conn.executescript(f.read())
    conn.commit()
    conn.close()
    
    print(f"✅ Database initialized: {DB_PATH}")
    return True

def load_drug_ids():
    """تحميل قائمة معرفات الأدوية"""
    if not os.path.exists(DRUG_IDS_FILE):
        print(f"❌ Drug IDs file not found: {DRUG_IDS_FILE}")
        return []
    
    with open(DRUG_IDS_FILE, 'r') as f:
        data = json.load(f)
        drug_ids = data.get('unique_drugs', [])
        print(f"📋 Loaded {len(drug_ids)} drug IDs")
        return drug_ids

def mark_drug_processed(drug_id, status='completed', error_msg=None):
    """تسجيل حالة معالجة الدواء"""
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    try:
        c.execute('''
            INSERT OR REPLACE INTO scraping_progress (entity_type, entity_id, status, error_message)
            VALUES ('drug', ?, ?, ?)
        ''', (drug_id, status, error_msg))
        conn.commit()
    finally:
        conn.close()

def get_pending_drugs(all_drug_ids):
    """الحصول على قائمة الأدوية التي لم تتم معالجتها"""
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute("SELECT entity_id FROM scraping_progress WHERE entity_type='drug' AND status='completed'")
    processed = set(row[0] for row in c.fetchall())
    conn.close()
    
    pending = [drug_id for drug_id in all_drug_ids if drug_id not in processed]
    print(f"📊 Status: {len(processed)} completed, {len(pending)} pending")
    return pending

# ============================================
# HTML Scraping (Basic Info)
# ============================================
def extract_table_value(soup, key_text):
    """استخراج قيمة من جدول HTML"""
    try:
        import re
        key_td = soup.find('td', class_='key', string=re.compile(key_text, re.I))
        if key_td:
            value_td = key_td.find_next_sibling('td', class_='value')
            if value_td:
                return value_td.get_text(strip=True)
    except:
        pass
    return None

def extract_drug_basic_info(drug_id):
    """جلب المعلومات الأساسية للدواء من صفحة drug-detail"""
    url = f"{BASE_URL}/server/drug-detail/{drug_id}/"
    
    try:
        response = requests.get(url, headers=HEADERS, timeout=REQUEST_TIMEOUT, verify=False)
        if response.status_code != 200:
            return None
        
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # استخراج اسم الدواء من العنوان
        drug_name = None
        title_elem = soup.find('strong', string=re.compile('Drugs Information:', re.I))
        if title_elem and title_elem.next_sibling:
            drug_name = title_elem.next_sibling.strip()
        
        # 2D SVG
        svg_elem = soup.find('svg')
        svg_content = str(svg_elem) if svg_elem else None

        # ATC Codes
        atc_td = soup.find('td', class_='key', string=re.compile('ATC Classification', re.I))
        atc_codes = []
        if atc_td:
            val_td = atc_td.find_next_sibling('td', class_='value')
            if val_td:
                atc_codes = [span.get_text(strip=True) for span in val_td.find_all('span', class_='badge')]

        # External Links
        links_td = soup.find('td', class_='key', string=re.compile('Useful Links', re.I))
        external_links = {}
        if links_td:
            val_td = links_td.find_next_sibling('td', class_='value')
            if val_td:
                for a in val_td.find_all('a', href=True):
                    site_name = a.get_text(strip=True)
                    url = a['href']
                    if site_name:
                        external_links[site_name] = url

        drug_data = {
            'ddinter_id': drug_id,
            'drug_name': drug_name,
            'drug_type': extract_table_value(soup, 'Drug Type'),
            'molecular_formula': extract_table_value(soup, 'Molecular Formula'),
            'molecular_weight': extract_table_value(soup, 'Molecular Weight'),
            'cas_number': extract_table_value(soup, 'CAS Number'),
            'description': extract_table_value(soup, 'Description'),
            'iupac_name': extract_table_value(soup, 'IUPAC Name'),
            'inchi': extract_table_value(soup, 'InChI'),
            'smiles': extract_table_value(soup, 'Canonical SMILES'),
            'atc_codes': json.dumps(atc_codes),
            'external_links': json.dumps(external_links),
            'structure_2d_svg': svg_content
        } 
        
        return drug_data
        
    except Exception as e:
        print(f"⚠️ Error fetching basic info for {drug_id}: {e}")
        return None

# ============================================
# API Calls (Interactions)
# ============================================
def fetch_drug_drug_interactions(drug_id):
    """جلب تفاعلات دواء-دواء عبر API مع استخراج mechanisms"""
    url = f"{BASE_URL}/server/interact-with/{drug_id}/"
    interactions = []
    
    try:
        # جلب الصفحة الأولى لمعرفة العدد الكلي
        data = {
            'draw': 1,
            'start': 0,
            'length': 100,  # جلب 100 في كل مرة
            'severity': '',
            'mechanism': ''
        }
        
        response = requests.post(url, data=data, headers=HEADERS, timeout=REQUEST_TIMEOUT, verify=False)
        if response.status_code != 200:
            return []
        
        json_response = response.json()
        total_records = json_response.get('recordsTotal', 0)
        
        # معالجة البيانات مع استخراج mechanisms
        for item in json_response.get('data', []):
            mechanisms = []
            if str(item.get('metabolism', '0')) == '1':
                mechanisms.append('Metabolism')
            if str(item.get('synergistic_effect', '0')) == '1':
                mechanisms.append('Synergism')
            if str(item.get('antagonistic_effect', '0')) == '1':
                mechanisms.append('Antagonism')
            if str(item.get('absorption', '0')) == '1':
                mechanisms.append('Absorption')
            if str(item.get('distribution', '0')) == '1':
                mechanisms.append('Distribution')
            if str(item.get('excretion', '0')) == '1':
                mechanisms.append('Excretion')
            if str(item.get('others', '0')) == '1':
                mechanisms.append('Others')
            
            interactions.append({
                'interaction_id': item.get('interaction_id'),
                'drug_id': item.get('drug_id'),
                'level': item.get('level'),
                'mechanisms': json.dumps(mechanisms) if mechanisms else None
            })
        
        # جلب الصفحات المتبقية
        for offset in range(100, total_records, 100):
            data['start'] = offset
            data['draw'] += 1
            
            response = requests.post(url, data=data, headers=HEADERS, timeout=REQUEST_TIMEOUT, verify=False)
            if response.status_code == 200:
                json_response = response.json()
                for item in json_response.get('data', []):
                    mechanisms = []
                    if str(item.get('metabolism', '0')) == '1':
                        mechanisms.append('Metabolism')
                    if str(item.get('synergistic_effect', '0')) == '1':
                        mechanisms.append('Synergism')
                    if str(item.get('antagonistic_effect', '0')) == '1':
                        mechanisms.append('Antagonism')
                    if str(item.get('absorption', '0')) == '1':
                        mechanisms.append('Absorption')
                    if str(item.get('distribution', '0')) == '1':
                        mechanisms.append('Distribution')
                    if str(item.get('excretion', '0')) == '1':
                        mechanisms.append('Excretion')
                    if str(item.get('others', '0')) == '1':
                        mechanisms.append('Others')
                    
                    interactions.append({
                        'interaction_id': item.get('interaction_id'),
                        'drug_id': item.get('drug_id'),
                        'level': item.get('level'),
                        'mechanisms': json.dumps(mechanisms) if mechanisms else None
                    })
                
        stats['ddi_fetched'].increment()
        return interactions
        
    except Exception as e:
        print(f"⚠️ Error fetching DDI for {drug_id}: {e}")
        return []

def fetch_drug_food_interactions(drug_id):
    """جلب تفاعلات دواء-غذاء عبر API"""
    url = f"{BASE_URL}/server/interact-with-food/{drug_id}/"
    interactions = []
    
    try:
        data = {
            'draw': 1,
            'start': 0,
            'length': 100,
            'severity': '',
            'mechanism': ''
        }
        
        response = requests.post(url, data=data, headers=HEADERS, timeout=REQUEST_TIMEOUT, verify=False)
        if response.status_code != 200:
            return []
        
        json_response = response.json()
        total_records = json_response.get('recordsTotal', 0)
        interactions.extend(json_response.get('data', []))
        
        for offset in range(100, total_records, 100):
            data['start'] = offset
            data['draw'] += 1
            
            response = requests.post(url, data=data, headers=HEADERS, timeout=REQUEST_TIMEOUT, verify=False)
            if response.status_code == 200:
                json_response = response.json()
                interactions.extend(json_response.get('data', []))
        
        stats['dfi_fetched'].increment()
        return interactions
        
    except Exception as e:
        print(f"⚠️ Error fetching DFI for {drug_id}: {e}")
        return []

def fetch_compound_preparations(drug_id):
    """جلب المستحضرات المركبة عبر API"""
    url = f"{BASE_URL}/server/interact-with-multi/{drug_id}/"
    preparations = []
    
    try:
        data = {
            'draw': 1,
            'start': 0,
            'length': 100
        }
        
        response = requests.post(url, data=data, headers=HEADERS, timeout=REQUEST_TIMEOUT, verify=False)
        if response.status_code != 200:
            return []
        
        json_response = response.json()
        total_records = json_response.get('recordsTotal', 0)
        preparations.extend(json_response.get('data', []))
        
        for offset in range(100, total_records, 100):
            data['start'] = offset
            data['draw'] += 1
            
            response = requests.post(url, data=data, headers=HEADERS, timeout=REQUEST_TIMEOUT, verify=False)
            if response.status_code == 200:
                json_response = response.json()
                preparations.extend(json_response.get('data', []))
        
        stats['multi_fetched'].increment()
        return preparations
        
    except Exception as e:
        print(f"⚠️ Error fetching preparations for {drug_id}: {e}")
        return []

def fetch_drug_disease_interactions(drug_id):
    """جلب تفاعلات دواء-مرض عبر API"""
    url = f"{BASE_URL}/server/interact-with-dis/{drug_id}/"
    interactions = []
    
    try:
        data = {
            'draw': 1,
            'start': 0,
            'length': 100,
            'severity': ''
        }
        
        response = requests.post(url, data=data, headers=HEADERS, timeout=REQUEST_TIMEOUT, verify=False)
        if response.status_code != 200:
            return []
        
        json_response = response.json()
        total_records = json_response.get('recordsTotal', 0)
        interactions.extend(json_response.get('data', []))
        
        for offset in range(100, total_records, 100):
            data['start'] = offset
            data['draw'] += 1
            
            response = requests.post(url, data=data, headers=HEADERS, timeout=REQUEST_TIMEOUT, verify=False)
            if response.status_code == 200:
                json_response = response.json()
                interactions.extend(json_response.get('data', []))
        
        stats['dsi_fetched'].increment()
        return interactions
        
    except Exception as e:
        print(f"⚠️ Error fetching DSI for {drug_id}: {e}")
        return []

# ============================================
# Database Saving
# ============================================
def save_drug_data(drug_data, ddi_list, dfi_list, prep_list, dsi_list):
    """حفظ جميع بيانات الدواء في قاعدة البيانات"""
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    
    try:
        # 1. حفظ معلومات الدواء الأساسية
        c.execute('''
            INSERT OR REPLACE INTO drugs 
            (ddinter_id, drug_name, drug_type, molecular_formula, molecular_weight, 
             cas_number, description, iupac_name, inchi, smiles, atc_codes, external_links, structure_2d_svg)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            drug_data['ddinter_id'], drug_data['drug_name'], drug_data['drug_type'],
            drug_data['molecular_formula'], drug_data['molecular_weight'],
            drug_data['cas_number'], drug_data['description'], drug_data['iupac_name'],
            drug_data['inchi'], drug_data['smiles'], drug_data['atc_codes'],
            drug_data['external_links'], drug_data['structure_2d_svg']
        ))
        
        # 2. حفظ تفاعلات دواء-دواء مع mechanism_flags
        for interaction in ddi_list:
            c.execute('''
                INSERT OR IGNORE INTO drug_drug_interactions 
                (interaction_id, drug_a_id, drug_b_id, severity, mechanism_flags, source_url)
                VALUES (?, ?, ?, ?, ?, ?)
            ''', (
                interaction.get('interaction_id'),
                drug_data['ddinter_id'],
                interaction.get('drug_id'),
                {1: 'Minor', 2: 'Moderate', 3: 'Major'}.get(interaction.get('level'), 'Unknown'),
                interaction.get('mechanisms'),
                f"{BASE_URL}/server/interact/{interaction.get('interaction_id')}/"
            ))
        
        # 3. حفظ تفاعلات دواء-غذاء
        for interaction in dfi_list:
            c.execute('''
                INSERT OR IGNORE INTO drug_food_interactions 
                (drug_id, food_name, severity, description, management, mechanism_flags)
                VALUES (?, ?, ?, ?, ?, ?)
            ''', (
                drug_data['ddinter_id'],
                interaction.get('foodName'),
                {1: 'Minor', 2: 'Moderate', 3: 'Major'}.get(int(interaction.get('level', 0)), 'Unknown'),
                interaction.get('newInteraction'),
                interaction.get('newManagement'),
                interaction.get('magnesium')
            ))
        
        # 4. حفظ المستحضرات المركبة
        for prep in prep_list:
            c.execute('''
                INSERT OR IGNORE INTO compound_preparations 
                (drug_id, preparation_name, components, interaction_info)
                VALUES (?, ?, ?, ?)
            ''', (
                drug_data['ddinter_id'],
                prep.get('trade_name'),
                json.dumps(prep.get('multi_drug', [])),
                prep.get('warning')
            ))
        
        # 5. حفظ تفاعلات الأمراض
        for dsi in dsi_list:
            # معالجة المراجع كقائمة JSON إذا كانت موجودة
            refs = dsi.get('references', [])
            if isinstance(refs, str):
                refs = refs.split('|')
            
            c.execute('''
                INSERT OR IGNORE INTO drug_disease_interactions 
                (drug_id, disease_name, severity, interaction_text, reference_text)
                VALUES (?, ?, ?, ?, ?)
            ''', (
                drug_data['ddinter_id'],
                dsi.get('diseaseName'),
                {1: 'Minor', 2: 'Moderate', 3: 'Major'}.get(int(dsi.get('level', 0)), 'Unknown'),
                dsi.get('text'),
                json.dumps(refs)
            ))
        
        conn.commit()
        return True
        
    except Exception as e:
        conn.rollback()
        print(f"❌ Error saving {drug_data['ddinter_id']}: {e}")
        return False
    finally:
        conn.close()

# ============================================
# Main Processing
# ============================================
def process_single_drug(drug_id):
    """معالجة دواء واحد - جلب جميع بياناته"""
    try:
        # 1. المعلومات الأساسية
        drug_data = extract_drug_basic_info(drug_id)
        if not drug_data:
            mark_drug_processed(drug_id, 'failed', 'Failed to fetch basic info')
            stats['errors'].increment()
            return False
        
        # 2. تفاعلات دواء-دواء
        ddi_list = fetch_drug_drug_interactions(drug_id)
        
        # 3. تفاعلات دواء-غذاء
        dfi_list = fetch_drug_food_interactions(drug_id)
        
        # 4. المستحضرات المركبة
        prep_list = fetch_compound_preparations(drug_id)

        # 5. تفاعلات الأمراض
        dsi_list = fetch_drug_disease_interactions(drug_id)
        
        # 6. حفظ كل شيء
        if save_drug_data(drug_data, ddi_list, dfi_list, prep_list, dsi_list):
            mark_drug_processed(drug_id, 'completed')
            
            count = stats['drugs_processed'].increment()
            if count % 10 == 0:
                print(f"✅ Progress: {count} drugs | DDI: {stats['ddi_fetched'].get()} | DFI: {stats['dfi_fetched'].get()} | Multi: {stats['multi_fetched'].get()} | Errors: {stats['errors'].get()}")
            
            return True
        else:
            mark_drug_processed(drug_id, 'failed', 'Database save failed')
            stats['errors'].increment()
            return False
            
    except Exception as e:
        mark_drug_processed(drug_id, 'failed', str(e))
        stats['errors'].increment()
        print(f"❌ Error processing {drug_id}: {e}")
        return False



if __name__ == "__main__":
    main()
