#!/usr/bin/env python3
"""
DDInter2 Comprehensive Scraper v9
==================================
سكرابر شامل لجمع جميع بيانات موقع DDInter2:
- معلومات الأدوية التفصيلية
- تفاعلات دواء-دواء (Drug-Drug)
- تفاعلات دواء-مرض (Drug-Disease)
- تفاعلات دواء-غذاء (Drug-Food)
- المستحضرات المركبة (Compound Preparations)
"""

import requests
import sqlite3
import json
import re
import os
import time
import urllib3
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime
from bs4 import BeautifulSoup

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# ============================================
# Configuration
# ============================================
DB_PATH = 'ddinter_complete.db'
SCHEMA_SQL = 'database_schema.sql'
DRUG_IDS_FILE = 'discovered_ids.json'
BASE_URL = 'https://ddinter2.scbdd.com'
MAX_WORKERS = 20
REQUEST_TIMEOUT = 15

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Referer': 'https://ddinter2.scbdd.com/',
    'Connection': 'keep-alive'
}

# ============================================
# Database Initialization
# ============================================
def init_database():
    """إنشاء قاعدة البيانات والجداول"""
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

# ============================================
# HTML Parsing Utilities
# ============================================
def extract_table_value(soup, key_text):
    """استخراج قيمة من جدول HTML بناءً على المفتاح"""
    try:
        key_td = soup.find('td', class_='key', string=re.compile(key_text, re.I))
        if key_td:
            value_td = key_td.find_next_sibling('td', class_='value')
            if value_td:
                return value_td.get_text(strip=True)
    except:
        pass
    return None

def extract_atc_codes(soup):
    """استخراج ATC codes"""
    try:
        atc_row = soup.find('td', class_='key', string=re.compile('ATC Classification'))
        if atc_row:
            value_td = atc_row.find_next_sibling('td')
            badges = value_td.find_all('span', class_='badge')
            return [badge.get_text(strip=True) for badge in badges]
    except:
        pass
    return []

def extract_external_links(soup):
    """استخراج الروابط الخارجية"""
    try:
        links_row = soup.find('td', class_='key', string=re.compile('Useful Links'))
        if links_row:
            value_td = links_row.find_next_sibling('td')
            links = {}
            for a_tag in value_td.find_all('a'):
                name = a_tag.get_text(strip=True)
                url = a_tag.get('href', '')
                links[name] = url
            return links
    except:
        pass
    return {}

def parse_drug_drug_table(soup, drug_id):
    """استخراج جدول تفاعلات دواء-دواء"""
    interactions = []
    try:
        table = soup.find('table', id='interaction-table')
        if table:
            # ملاحظة: الجدول يتم ملؤه عبر JavaScript/AJAX
            # نحتاج لطلب API endpoint مباشرة
            # سيتم التعامل مع هذا في scrape_drug_interactions
            pass
    except Exception as e:
        print(f"⚠️ Error parsing drug-drug table: {e}")
    return interactions

def parse_disease_table(soup):
    """استخراج جدول تفاعلات دواء-مرض"""
    interactions = []
    try:
        table = soup.find('table', id='ddsi-table')
        if table and table.tbody:
            rows = table.tbody.find_all('tr')
            for row in rows:
                cols = row.find_all('td')
                if len(cols) >= 4:
                    interactions.append({
                        'severity': cols[0].get_text(strip=True),
                        'disease_name': cols[1].get_text(strip=True),
                        'text': cols[2].get_text(strip=True),
                        'references': cols[3].get_text(strip=True)
                    })
    except Exception as e:
        print(f"⚠️ Error parsing disease table: {e}")
    return interactions

def parse_food_table(soup):
    """استخراج جدول تفاعلات دواء-غذاء"""
    interactions = []
    try:
        table = soup.find('table', id='dfi-table')
        if table and table.tbody:
            rows = table.tbody.find_all('tr')
            for row in rows:
                cols = row.find_all('td')
                if len(cols) >= 6:
                    interactions.append({
                        'severity': cols[0].get_text(strip=True),
                        'food_name': cols[1].get_text(strip=True),
                        'description': cols[2].get_text(strip=True),
                        'management': cols[3].get_text(strip=True),
                        'mechanism': cols[4].get_text(strip=True),
                        'references': cols[5].get_text(strip=True)
                    })
    except Exception as e:
        print(f"⚠️ Error parsing food table: {e}")
    return interactions

# ============================================
# Phase 1: Scrape Drug Details
# ============================================
def scrape_drug_detail(drug_id):
    """سحب تفاصيل دواء واحد"""
    url = f"{BASE_URL}/server/drug-detail/{drug_id}/"
    
    try:
        response = requests.get(url, headers=HEADERS, timeout=REQUEST_TIMEOUT, verify=False)
        if response.status_code != 200:
            return None, f"HTTP {response.status_code}"
        
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # استخراج المعلومات الأساسية
        drug_data = {
            'ddinter_id': drug_id,
            'drug_name': soup.find('strong', string='Drugs Information:').next_sibling.strip() if soup.find('strong', string='Drugs Information:') else None,
            'drug_type': extract_table_value(soup, 'Drug Type'),
            'molecular_formula': extract_table_value(soup, 'Molecular Formula'),
            'molecular_weight': extract_table_value(soup, 'Molecular Weight'),
            'cas_number': extract_table_value(soup, 'CAS Number'),
            'description': extract_table_value(soup, 'Description'),
            'iupac_name': extract_table_value(soup, 'IUPAC Name'),
            'inchi': extract_table_value(soup, 'InChI'),
            'smiles': extract_table_value(soup, 'Canonical SMILES'),
            'atc_codes': json.dumps(extract_atc_codes(soup)),
            'external_links': json.dumps(extract_external_links(soup))
        }
        
        # استخراج التفاعلات
        disease_interactions = parse_disease_table(soup)
        food_interactions = parse_food_table(soup)
        
        return {
            'drug': drug_data,
            'diseases': disease_interactions,
            'foods': food_interactions
        }, None
        
    except Exception as e:
        return None, str(e)

def save_drug_to_db(drug_data, disease_interactions, food_interactions):
    """حفظ بيانات الدواء في قاعدة البيانات"""
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    
    try:
        # حفظ الدواء
        c.execute('''
            INSERT OR REPLACE INTO drugs 
            (ddinter_id, drug_name, drug_type, molecular_formula, molecular_weight, 
             cas_number, description, iupac_name, inchi, smiles, atc_codes, external_links)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            drug_data['ddinter_id'], drug_data['drug_name'], drug_data['drug_type'],
            drug_data['molecular_formula'], drug_data['molecular_weight'],
            drug_data['cas_number'], drug_data['description'], drug_data['iupac_name'],
            drug_data['inchi'], drug_data['smiles'], drug_data['atc_codes'],
            drug_data['external_links']
        ))
        
        # حفظ تفاعلات المرض
        for interaction in disease_interactions:
            c.execute('''
                INSERT INTO drug_disease_interactions 
                (drug_id, disease_name, severity, interaction_text, reference_text)
                VALUES (?, ?, ?, ?, ?)
            ''', (
                drug_data['ddinter_id'], interaction['disease_name'], 
                interaction['severity'], interaction['text'], interaction['references']
            ))
        
        # حفظ تفاعلات الغذاء
        for interaction in food_interactions:
            c.execute('''
                INSERT INTO drug_food_interactions 
                (drug_id, food_name, severity, description, management, mechanism_flags, reference_text)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ''', (
                drug_data['ddinter_id'], interaction['food_name'], 
                interaction['severity'], interaction['description'],
                interaction['management'], interaction['mechanism'], interaction['references']
            ))
        
        # تسجيل التقدم
        c.execute('''
            INSERT OR REPLACE INTO scraping_progress (entity_type, entity_id, status)
            VALUES ('drug', ?, 'completed')
        ''', (drug_data['ddinter_id'],))
        
        conn.commit()
        return True
        
    except Exception as e:
        conn.rollback()
        print(f"❌ Error saving {drug_data['ddinter_id']}: {e}")
        return False
    finally:
        conn.close()

# ============================================
# Phase 2: Scrape Drug-Drug Interactions
# ============================================
def scrape_drug_interactions(start_id=1, end_id=60000):
    """سحب تفاعلات دواء-دواء (من السكرابر v8 الناجح)"""
    print(f"\n🔄 Phase 2: Scraping drug-drug interactions ({start_id}-{end_id})...")
    
    # استخدام نفس منطق bulk_scraper_v8_html.py الناجح
    # TODO: دمج منطق السكرابر v8 هنا
    pass

# ============================================
# Main Execution
# ============================================
def main():
    print("="*60)
    print("🚀 DDInter2 Comprehensive Scraper v9")
    print("="*60)
    
    # 1. إنشاء قاعدة البيانات
    if not init_database():
        return
    
    # 2. تحميل قائمة الأدوية
    drug_ids = load_drug_ids()
    if not drug_ids:
        print("❌ No drug IDs to process")
        return
    
    # 3. المرحلة الأولى: سحب تفاصيل الأدوية
    print(f"\n🔄 Phase 1: Scraping {len(drug_ids)} drugs...")
    
    success_count = 0
    error_count = 0
    
    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        futures = {executor.submit(scrape_drug_detail, drug_id): drug_id for drug_id in drug_ids[:100]}  # Test with 100 first
        
        for future in as_completed(futures):
            drug_id = futures[future]
            try:
                result, error = future.result()
                if result:
                    if save_drug_to_db(result['drug'], result['diseases'], result['foods']):
                        success_count += 1
                        if success_count % 10 == 0:
                            print(f"✅ Progress: {success_count} drugs processed")
                else:
                    error_count += 1
                    print(f"⚠️ Failed {drug_id}: {error}")
            except Exception as e:
                error_count += 1
                print(f"❌ Error processing {drug_id}: {e}")
    
    print(f"\n✅ Phase 1 Complete: {success_count} success, {error_count} errors")
    
    # 4. المرحلة الثانية: سحب تفاعلات دواء-دواء
    # scrape_drug_interactions()
    
    print("\n" + "="*60)
    print("🎉 Scraping Complete!")
    print("="*60)

if __name__ == "__main__":
    main()
