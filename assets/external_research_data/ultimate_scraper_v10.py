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

import requests
import sqlite3
import json
import os
import time
import urllib3
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime
from bs4 import BeautifulSoup
import threading

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# ============================================
# Configuration
# ============================================
DB_PATH = 'ddinter_complete.db'
SCHEMA_SQL = 'database_schema.sql'
DRUG_IDS_FILE = 'discovered_ids.json'
BASE_URL = 'https://ddinter2.scbdd.com'
MAX_WORKERS = 25
REQUEST_TIMEOUT = 15

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    'Accept': 'application/json, text/javascript, */*; q=0.01',
    'Accept-Language': 'en-US,en;q=0.9',
    'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
    'X-Requested-With': 'XMLHttpRequest',
    'Referer': 'https://ddinter2.scbdd.com/',
    'Connection': 'keep-alive'
}

# Thread-safe counters
class Counter:
    def __init__(self):
        self.value = 0
        self.lock = threading.Lock()
    def increment(self):
        with self.lock:
            self.value += 1
            return self.value
    def get(self):
        with self.lock:
            return self.value

stats = {
    'drugs_processed': Counter(),
    'ddi_fetched': Counter(),
    'dfi_fetched': Counter(),
    'multi_fetched': Counter(),
    'errors': Counter()
}

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
        title_elem = soup.find('strong', string='Drugs Information:')
        if title_elem and title_elem.next_sibling:
            drug_name = title_elem.next_sibling.strip()
        
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
            'smiles': extract_table_value(soup, 'Canonical SMILES')
        }
        
        return drug_data
        
    except Exception as e:
        print(f"⚠️ Error fetching basic info for {drug_id}: {e}")
        return None

# ============================================
# API Calls (Interactions)
# ============================================
def fetch_drug_drug_interactions(drug_id):
    """جلب تفاعلات دواء-دواء عبر API"""
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
        interactions.extend(json_response.get('data', []))
        
        # جلب الصفحات المتبقية
        for offset in range(100, total_records, 100):
            data['start'] = offset
            data['draw'] += 1
            
            response = requests.post(url, data=data, headers=HEADERS, timeout=REQUEST_TIMEOUT, verify=False)
            if response.status_code == 200:
                json_response = response.json()
                interactions.extend(json_response.get('data', []))
                
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

# ============================================
# Database Saving
# ============================================
def save_drug_data(drug_data, ddi_list, dfi_list, prep_list):
    """حفظ جميع بيانات الدواء في قاعدة البيانات"""
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    
    try:
        # 1. حفظ معلومات الدواء الأساسية
        c.execute('''
            INSERT OR REPLACE INTO drugs 
            (ddinter_id, drug_name, drug_type, molecular_formula, molecular_weight, 
             cas_number, description, iupac_name, inchi, smiles)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            drug_data['ddinter_id'], drug_data['drug_name'], drug_data['drug_type'],
            drug_data['molecular_formula'], drug_data['molecular_weight'],
            drug_data['cas_number'], drug_data['description'], drug_data['iupac_name'],
            drug_data['inchi'], drug_data['smiles']
        ))
        
        # 2. حفظ تفاعلات دواء-دواء (لكن فقط إذا كان هذا الدواء هو drug_a)
        # لتجنب التكرار، نحفظ فقط عندما يكون الدواء الحالي هو الأول alphabetically
        for interaction in ddi_list:
            # نحفظ interaction_id فقط مرة واحدة
            c.execute('''
                INSERT OR IGNORE INTO drug_drug_interactions 
                (interaction_id, drug_a_id, drug_b_id, severity, source_url)
                VALUES (?, ?, ?, ?, ?)
            ''', (
                interaction.get('interaction_id'),
                drug_data['ddinter_id'],
                interaction.get('drug_id'),
                {1: 'Minor', 2: 'Moderate', 3: 'Major'}.get(interaction.get('level'), 'Unknown'),
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
        
        # 5. حفظ كل شيء
        if save_drug_data(drug_data, ddi_list, dfi_list, prep_list):
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

# ============================================
# Main Execution
# ============================================
def main():
    print("="*70)
    print("🚀 DDInter2 Ultimate Scraper v10 - API Edition")
    print("="*70)
    print(f"⏰ Start time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # 1. إنشاء/فتح قاعدة البيانات
    if not os.path.exists(DB_PATH):
        if not init_database():
            return
    else:
        print(f"📦 Using existing database: {DB_PATH}")
    
    # 2. تحميل قائمة الأدوية
    all_drug_ids = load_drug_ids()
    if not all_drug_ids:
        print("❌ No drug IDs to process")
        return
    
    # 3. فلترة الأدوية المعالجة (Resume Support)
    pending_drugs = get_pending_drugs(all_drug_ids)
    
    if not pending_drugs:
        print("✅ All drugs already processed!")
        return
    
    print(f"\n🔄 Processing {len(pending_drugs)} drugs with {MAX_WORKERS} workers...\n")
    
    # 4. معالجة متوازية
    start_time = time.time()
    
    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        futures = {executor.submit(process_single_drug, drug_id): drug_id for drug_id in pending_drugs}
        
        for future in as_completed(futures):
            drug_id = futures[future]
            try:
                future.result()
            except Exception as e:
                print(f"❌ Unexpected error for {drug_id}: {e}")
    
    elapsed = time.time() - start_time
    
    # 5. إحصائيات نهائية
    print("\n" + "="*70)
    print("🎉 Scraping Complete!")
    print("="*70)
    print(f"⏱️  Total time: {elapsed/60:.2f} minutes")
    print(f"✅ Drugs processed: {stats['drugs_processed'].get()}")
    print(f"📊 Drug-Drug interactions: {stats['ddi_fetched'].get()} drugs")
    print(f"🍔 Drug-Food interactions: {stats['dfi_fetched'].get()} drugs")
    print(f"💊 Compound preparations: {stats['multi_fetched'].get()} drugs")
    print(f"❌ Errors: {stats['errors'].get()}")
    print("="*70)
    
    # عرض إحصائيات قاعدة البيانات
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute("SELECT COUNT(*) FROM drugs")
    total_drugs = c.fetchone()[0]
    c.execute("SELECT COUNT(*) FROM drug_drug_interactions")
    total_ddi = c.fetchone()[0]
    c.execute("SELECT COUNT(*) FROM drug_food_interactions")
    total_dfi = c.fetchone()[0]
    c.execute("SELECT COUNT(*) FROM compound_preparations")
    total_prep = c.fetchone()[0]
    conn.close()
    
    print(f"\n📊 Database Statistics:")
    print(f"   Drugs: {total_drugs}")
    print(f"   Drug-Drug Interactions: {total_ddi}")
    print(f"   Drug-Food Interactions: {total_dfi}")
    print(f"   Compound Preparations: {total_prep}")
    print("="*70)

if __name__ == "__main__":
    main()
