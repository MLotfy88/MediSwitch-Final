#!/usr/bin/env python3
"""
Enhanced D1 Database Verification Script  
Checks drug count, interactions count, and validates data integrity
Prefers Global API Key over Custom Token
"""

import requests
import argparse
import sys
from typing import Dict, Optional

def execute_d1_query(account_id: str, database_id: str, sql: str, 
                     api_token: str = None, email: str = None, global_key: str = None) -> Optional[Dict]:
    """Execute SQL query on D1 database with flexible auth"""
    url = f"https://api.cloudflare.com/client/v4/accounts/{account_id}/d1/database/{database_id}/query"
    
    # Prefer Global Key (more reliable)
    if email and global_key:
        headers = {
            "X-Auth-Email": email,
            "X-Auth-Key": global_key,
            "Content-Type": "application/json"
        }
    elif api_token:
        headers = {
            "Authorization": f"Bearer {api_token}",
            "Content-Type": "application/json"
        }
    else:
        print("❌ Error: Must provide either (--email and --global-key) OR --api-token")
        return None
    
    try:
        response = requests.post(url, headers=headers, json={"sql": sql}, timeout=10)
        response.raise_for_status()
        result = response.json()
        
        if result.get("success") and result.get("result"):
            return result["result"][0]["results"]
        else:
            print(f"❌ Query failed: {result.get('errors', 'Unknown error')}")
            return None
    except Exception as e:
        print(f"❌ Error executing query: {e}")
        return None

def check_drugs_table(account_id: str, database_id: str, **auth):
    """Check drugs table"""
    print("\n" + "="*60)
    print("🩺 فحص جدول الأدوية (drugs)")
    print("="*60)
    
    # Count
    results = execute_d1_query(account_id, database_id, 
                               "SELECT COUNT(*) as total FROM drugs", **auth)
    if results:
        total = results[0]["total"]
        print(f"✅ إجمالي الأدوية: {total:,}")
        
        # Latest updates
        latest = execute_d1_query(account_id, database_id,
                                  "SELECT trade_name, arabic_name, price, last_price_update FROM drugs ORDER BY id DESC LIMIT 5",
                                  **auth)
        if latest:
            print("\n📋 آخر 5 أدوية محدثة:")
            for row in latest:
                print(f"   • {row['trade_name']} ({row['arabic_name']})")
                print(f"     السعر: {row['price']} ج.م | آخر تحديث: {row['last_price_update']}")
        
        # Check for duplicates by ID
        dupes = execute_d1_query(account_id, database_id,
                                 "SELECT id, COUNT(*) as count FROM drugs GROUP BY id HAVING count > 1 LIMIT 5",
                                 **auth)
        if dupes and len(dupes) > 0:
            print(f"\n⚠️ تحذير: وجدت {len(dupes)} معرفات مكررة!")
            for row in dupes:
                print(f"   ID {row['id']}: {row['count']} نسخ")
        else:
            print("\n✅ لا توجد معرفات مكررة (جيد)")
        
        return total
    return 0

def check_interactions_table(account_id: str, database_id: str, **auth):
    """Check interactions table"""
    print("\n" + "="*60)
    print("⚛️ فحص جدول التفاعلات (drug_interactions)")
    print("="*60)
    
    # Count
    results = execute_d1_query(account_id, database_id,
                               "SELECT COUNT(*) as total FROM drug_interactions", **auth)
    if results:
        total = results[0]["total"]
        print(f"✅ إجمالي التفاعلات: {total:,}")
        
        # Count 'multiple' and 'other_medications' in ingredient2
        problematic = execute_d1_query(account_id, database_id,
                                       """SELECT 
                                          SUM(CASE WHEN ingredient2 = 'multiple' THEN 1 ELSE 0 END) as multiple_count,
                                          SUM(CASE WHEN ingredient2 = 'other_medications' THEN 1 ELSE 0 END) as other_count
                                          FROM drug_interactions""", **auth)
        if problematic:
            multiple_count = problematic[0]["multiple_count"] or 0
            other_count = problematic[0]["other_count"] or 0
            
            if multiple_count > 0:
                pct = (multiple_count / total * 100) if total > 0 else 0
                print(f"⚠️ تفاعلات مع 'multiple': {multiple_count:,} ({pct:.1f}%)")
            if other_count > 0:
                pct = (other_count / total * 100) if total > 0 else 0
                print(f"ℹ️ تفاعلات مع 'other_medications': {other_count:,} ({pct:.1f}%)")
            
            if multiple_count == 0 and other_count < total * 0.1:
                print("✅ جودة استخراج المواد الفعالة ممتازة!")
        
        # Sample interactions
        sample = execute_d1_query(account_id, database_id,
                                  "SELECT ingredient1, ingredient2, severity FROM drug_interactions LIMIT 5",
                                  **auth)
        if sample:
            print("\n📋 عينة من التفاعلات:")
            for row in sample:
                print(f"   • {row['ingredient1']} ↔ {row['ingredient2']} ({row['severity']})")
        
        return total
    return 0

def main():
    parser = argparse.ArgumentParser(description='Verify D1 database integrity (Prefers Global API Key)')
    parser.add_argument('--account-id', required=True, help='Cloudflare Account ID')
    parser.add_argument('--database-id', required=True, help='D1 Database ID')
    
    # Auth options (Global Key preferred)
    parser.add_argument('--api-token', help='Cloudflare API Token (fallback)')
    parser.add_argument('--email', help='Cloudflare Email (for Global Key - preferred)')
    parser.add_argument('--global-key', help='Cloudflare Global API Key (preferred)')
    
    args = parser.parse_args()
    
    # Validate auth
    if not args.api_token and not (args.email and args.global_key):
        print("❌ Error: Must provide either --api-token OR (--email and --global-key)")
        return 1
    
    print("\n" + "="*60)
    print("🔍 بدء فحص قاعدة بيانات D1")
    print("="*60)
    print(f"🆔 Database ID: {args.database_id[:8]}...")
    
    if args.email and args.global_key:
        print("🔑 Auth: Global API Key (preferred)")
    else:
        print("🔑 Auth: Custom API Token (fallback)")
    
    # Prepare auth kwargs
    auth = {
        "api_token": args.api_token,
        "email": args.email,
        "global_key": args.global_key
    }
    
    # Check drugs
    drug_count = check_drugs_table(args.account_id, args.database_id, **auth)
    
    # Check interactions
    interaction_count = check_interactions_table(args.account_id, args.database_id, **auth)
    
    # Summary
    print("\n" + "="*60)
    print("📊 ملخص النتائج")
    print("="*60)
    print(f"✅ الأدوية: {drug_count:,}")
    print(f"✅ التفاعلات: {interaction_count:,}")
    
    if drug_count > 0 and interaction_count > 0:
        print("\n🎉 قاعدة البيانات تعمل بشكل صحيح!")
        return 0
    else:
        print("\n⚠️ تحذير: بعض الجداول فارغة!")
        return 1

if __name__ == '__main__':
    sys.exit(main())
