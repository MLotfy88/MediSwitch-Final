import sqlite3
import os
import json

DB_PATH = "mediswitch.db"
OUTPUT_DIR = "d1_migration_sql"

def export_for_d1():
    """تصدير البيانات بصيغة SQL مناسبة لـ Cloudflare D1"""
    
    if not os.path.exists(DB_PATH):
        print(f"❌ Database not found: {DB_PATH}")
        return
    
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    print("🚀 تحضير البيانات للمزامنة مع Cloudflare D1")
    print("="*80)
    
    # 1. Schema فقط (الجداول والـ Indexes)
    print("\n📋 خطوة 1: تصدير Schema...")
    cursor.execute("SELECT sql FROM sqlite_master WHERE type IN ('table', 'index') AND sql IS NOT NULL")
    schema_sql = []
    for row in cursor.fetchall():
        schema_sql.append(row[0] + ";")
    
    with open(f"{OUTPUT_DIR}/01_schema.sql", "w", encoding="utf-8") as f:
        f.write("-- Cloudflare D1 Schema\n")
        f.write("-- Generated for MediSwitch Database\n\n")
        f.write("\n\n".join(schema_sql))
    print(f"   ✅ تم حفظ Schema في 01_schema.sql")
    
    # 2. معلومات الحجم
    tables_info = []
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")
    for (table_name,) in cursor.fetchall():
        cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
        count = cursor.fetchone()[0]
        tables_info.append({
            "table": table_name,
            "rows": count,
            "size_mb": 0  # سيتم حسابه لاحقاً
        })
    
    # 3. خطة التقسيم
    print("\n📊 خطوة 2: تحليل حجم البيانات...")
    plan = {
        "total_tables": len(tables_info),
        "tables": tables_info,
        "strategy": "incremental",
        "notes": [
            "⚠️ حجم قاعدة البيانات كبير جداً (6.2 GB)",
            "💡 الحل: استخدام wrangler d1 execute مع batch inserts",
            "📦 تقسيم كل جدول لـ chunks صغيرة (1000 row/chunk)",
            "⚡ رفع كل chunk على حدة"
        ]
    }
    
    with open(f"{OUTPUT_DIR}/migration_plan.json", "w", encoding="utf-8") as f:
        json.dump(plan, f, indent=2, ensure_ascii=False)
    
    # 4. عرض الملخص
    print("\n" + "="*80)
    print("📊 ملخص البيانات:")
    print("-"*80)
    for info in sorted(tables_info, key=lambda x: x['rows'], reverse=True):
        print(f"   {info['table']:30} : {info['rows']:>12,} rows")
    
    print("\n" + "="*80)
    print("⚠️  تحذير مهم:")
    print("-"*80)
    print("   قاعدة البيانات كبيرة جداً (6.2 GB)")
    print("   Cloudflare D1 عنده حدود:")
    print("   - حد أقصى 10 GB للـ database")
    print("   - حد أقصى 100,000 صف لكل batch insert")
    print("   - حد أقصى 1 MB لكل SQL statement")
    
    print("\n💡 الخيارات المتاحة:")
    print("-"*80)
    print("   1️⃣  رفع بيانات الأدوية + تفاعلات الأدوية فقط (الأساسيات)")
    print("   2️⃣  تقليل تفاعلات الأمراض (حالياً 7.7 مليون → نخليها حسب الدواء الأساسي فقط)")
    print("   3️⃣  استخدام External Storage لتفاعلات الأمراض والطعام")
    
    conn.close()
    
    print("\n✅ انتهى التحضير. الملفات في: " + OUTPUT_DIR)
    return tables_info

if __name__ == "__main__":
    export_for_d1()
