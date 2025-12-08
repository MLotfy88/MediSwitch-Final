#!/usr/bin/env python3
"""
Verify Local SQLite Database and Sync with D1
Checks local app database integrity and compares with D1
"""

import sqlite3
import requests
import argparse
import sys
import os
from pathlib import Path

def check_local_database(db_path: str):
    """Check local SQLite database"""
    print("\n" + "="*60)
    print("📱 فحص قاعدة البيانات المحلية (SQLite)")
    print("="*60)
    
    if not os.path.exists(db_path):
        print(f"❌ الملف غير موجود: {db_path}")
        return None
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Check drugs table
        cursor.execute("SELECT COUNT(*) FROM drugs")
        local_drug_count = cursor.fetchone()[0]
        print(f"✅ الأدوية المحلية: {local_drug_count:,}")
        
        # Check interactions table
        try:
            cursor.execute("SELECT COUNT(*) FROM drug_interactions")
            local_interaction_count = cursor.fetchone()[0]
            print(f"✅ التفاعلات المحلية: {local_interaction_count:,}")
        except sqlite3.OperationalError:
            local_interaction_count = 0
            print("ℹ️ جدول التفاعلات غير موجود أو فارغ")
        
        # Check for data quality
        cursor.execute("SELECT COUNT(*) FROM drugs WHERE trade_name IS NULL OR trade_name = ''")
        empty_names = cursor.fetchone()[0]
        if empty_names > 0:
            print(f"⚠️ تحذير: {empty_names} أدوية بدون أسماء")
        else:
            print("✅ جميع الأدوية لها أسماء")
        
        # Sample latest drugs
        cursor.execute("SELECT id, trade_name, arabic_name, price FROM drugs ORDER BY id DESC LIMIT 5")
        latest = cursor.fetchall()
        if latest:
            print("\n📋 آخر 5 أدوية في القاعدة المحلية:")
            for row in latest:
                print(f"   ID {row[0]}: {row[1]} ({row[2]}) - {row[3]} ج.م")
        
        # Check for 'multiple' in interactions
        if local_interaction_count > 0:
            cursor.execute("SELECT COUNT(*) FROM drug_interactions WHERE ingredient2 = 'multiple'")
            multiple_count = cursor.fetchone()[0]
            if multiple_count > 0:
                pct = (multiple_count / local_interaction_count * 100)
                print(f"\n⚠️ تفاعلات مع 'multiple' في القاعدة المحلية: {multiple_count:,} ({pct:.1f}%)")
        
        conn.close()
        
        return {
            'drugs': local_drug_count,
            'interactions': local_interaction_count
        }
        
    except Exception as e:
        print(f"❌ خطأ في قراءة القاعدة المحلية: {e}")
        return None

def check_d1_database(account_id: str, database_id: str, api_token: str):
    """Check D1 database"""
    print("\n" + "="*60)
    print("☁️ فحص قاعدة البيانات السحابية (D1)")
    print("="*60)
    
    url = f"https://api.cloudflare.com/client/v4/accounts/{account_id}/d1/database/{database_id}/query"
    headers = {
        "Authorization": f"Bearer {api_token}",
        "Content-Type": "application/json"
    }
    
    try:
        # Check drugs
        response = requests.post(url, headers=headers, json={"sql": "SELECT COUNT(*) as total FROM drugs"}, timeout=10)
        response.raise_for_status()
        result = response.json()
        
        if result.get("success"):
            d1_drug_count = result["result"][0]["results"][0]["total"]
            print(f"✅ الأدوية في D1: {d1_drug_count:,}")
        else:
            print(f"❌ فشل الاستعلام: {result.get('errors')}")
            return None
        
        # Check interactions
        response = requests.post(url, headers=headers, json={"sql": "SELECT COUNT(*) as total FROM drug_interactions"}, timeout=10)
        if response.status_code == 200:
            result = response.json()
            if result.get("success"):
                d1_interaction_count = result["result"][0]["results"][0]["total"]
                print(f"✅ التفاعلات في D1: {d1_interaction_count:,}")
            else:
                d1_interaction_count = 0
        else:
            d1_interaction_count = 0
        
        return {
            'drugs': d1_drug_count,
            'interactions': d1_interaction_count
        }
        
    except Exception as e:
        print(f"❌ خطأ في الاتصال بـ D1: {e}")
        return None

def compare_databases(local_stats, d1_stats):
    """Compare local and D1 databases"""
    print("\n" + "="*60)
    print("⚖️ مقارنة القواعد (المحلية vs السحابية)")
    print("="*60)
    
    if not local_stats or not d1_stats:
        print("❌ لا يمكن المقارنة - بيانات غير كافية")
        return False
    
    # Compare drugs
    drug_diff = d1_stats['drugs'] - local_stats['drugs']
    drug_pct = (local_stats['drugs'] / d1_stats['drugs'] * 100) if d1_stats['drugs'] > 0 else 0
    
    print(f"\n💊 الأدوية:")
    print(f"   المحلية: {local_stats['drugs']:,}")
    print(f"   D1: {d1_stats['drugs']:,}")
    print(f"   الفرق: {drug_diff:+,}")
    print(f"   نسبة التطابق: {drug_pct:.1f}%")
    
    if abs(drug_diff) == 0:
        print("   ✅ متطابقة تماماً!")
    elif abs(drug_diff) < 100:
        print("   ✅ فرق طفيف - مقبول")
    elif drug_pct >= 95:
        print("   ⚠️ فرق ملحوظ لكن قريب")
    else:
        print("   ❌ فرق كبير - يحتاج مزامنة")
    
    # Compare interactions
    interaction_diff = d1_stats['interactions'] - local_stats['interactions']
    interaction_pct = (local_stats['interactions'] / d1_stats['interactions'] * 100) if d1_stats['interactions'] > 0 else 0
    
    print(f"\n⚛️ التفاعلات:")
    print(f"   المحلية: {local_stats['interactions']:,}")
    print(f"   D1: {d1_stats['interactions']:,}")
    print(f"   الفرق: {interaction_diff:+,}")
    if d1_stats['interactions'] > 0:
        print(f"   نسبة التطابق: {interaction_pct:.1f}%")
    
    if abs(interaction_diff) == 0:
        print("   ✅ متطابقة تماماً!")
    elif interaction_pct >= 95:
        print("   ✅ فرق طفيف - مقبول")
    else:
        print("   ⚠️ فرق كبير - قد تحتاج مزامنة")
    
    # Overall sync status
    print("\n" + "="*60)
    if abs(drug_diff) < 100 and (interaction_diff == 0 or interaction_pct >= 90):
        print("✅ حالة المزامنة: ممتازة")
        return True
    elif drug_pct >= 95:
        print("⚠️ حالة المزامنة: جيدة لكن يُنصح بالتحديث")
        return True
    else:
        print("❌ حالة المزامنة: يحتاج مزامنة فورية")
        return False

def main():
    parser = argparse.ArgumentParser(description='Verify local database and sync with D1')
    parser.add_argument('--db-path', default='assets/meds.db', help='Path to local SQLite database')
    parser.add_argument('--account-id', help='Cloudflare Account ID')
    parser.add_argument('--database-id', help='D1 Database ID')
    parser.add_argument('--api-token', help='Cloudflare API Token')
    parser.add_argument('--skip-d1', action='store_true', help='Skip D1 check')
    
    args = parser.parse_args()
    
    print("\n" + "="*60)
    print("🔍 فحص قواعد البيانات والمزامنة")
    print("="*60)
    
    # Check local database
    local_stats = check_local_database(args.db_path)
    
    # Check D1 if credentials provided
    d1_stats = None
    if not args.skip_d1 and args.account_id and args.database_id and args.api_token:
        d1_stats = check_d1_database(args.account_id, args.database_id, args.api_token)
    else:
        print("\nℹ️ تم تخطي فحص D1 (لم يتم توفير بيانات الاعتماد)")
    
    # Compare if both available
    sync_ok = True
    if local_stats and d1_stats:
        sync_ok = compare_databases(local_stats, d1_stats)
    
    # Summary
    print("\n" + "="*60)
    print("📊 ملخص الفحص")
    print("="*60)
    
    if local_stats:
        print(f"✅ القاعدة المحلية: {local_stats['drugs']:,} دواء، {local_stats['interactions']:,} تفاعل")
    else:
        print("❌ القاعدة المحلية: فشل الفحص")
    
    if d1_stats:
        print(f"✅ قاعدة D1: {d1_stats['drugs']:,} دواء، {d1_stats['interactions']:,} تفاعل")
    
    if local_stats and d1_stats:
        print(f"{'✅' if sync_ok else '⚠️'} المزامنة: {'ممتازة' if sync_ok else 'تحتاج مراجعة'}")
    
    return 0 if (local_stats and (not d1_stats or sync_ok)) else 1

if __name__ == '__main__':
    sys.exit(main())
