import sqlite3
import os

# --- Configuration ---
CHUNK_DIR = "d1_sql_chunks"
BATCH_SIZE = 1000

# Database Path
DB_PATH = "mediswitch.db"

def clean_sql_val(val):
    """تنظيف القيمة للSQL"""
    if val is None or val == "": return "NULL"
    if isinstance(val, (int, float)): return str(val)
    # Escape single quotes
    safe_v = str(val).replace("'", "''")
    return f"'{safe_v}'"

def write_chunk(table_name, alias, data_list, cols):
    """كتابة دفعة SQL"""
    if not data_list: return
    
    os.makedirs(CHUNK_DIR, exist_ok=True)
    
    for i in range(0, len(data_list), BATCH_SIZE):
        chunk_idx = i // BATCH_SIZE
        batch = data_list[i:i + BATCH_SIZE]
        
        sql_lines = []
        for row in batch:
            vals = [clean_sql_val(row.get(col)) for col in cols]
            sql_lines.append(f"INSERT OR REPLACE INTO {table_name} ({', '.join(cols)}) VALUES ({', '.join(vals)});")
        
        fname = f"{alias}_part_{chunk_idx:03d}.sql"
        with open(os.path.join(CHUNK_DIR, fname), "w", encoding="utf-8") as f:
            f.write("\n".join(sql_lines))
        print(f"  ✓ كتابة {fname}: {len(batch):,} سجل")

def export_from_db():
    """تصدير جميع البيانات من mediswitch.db"""
    
    if not os.path.exists(DB_PATH):
        print(f"❌ قاعدة البيانات غير موجودة: {DB_PATH}")
        return
    
    print("🚀 بدء تصدير البيانات من mediswitch.db...")
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    
    # 1. تصدير الأدوية (drugs)
    print("\n💊 تصدير جدول الأدوية (drugs)...")
    cursor = conn.execute("SELECT * FROM drugs")
    drugs = [dict(row) for row in cursor.fetchall()]
    drug_cols = ['id', 'trade_name', 'arabic_name', 'price', 'old_price', 'category', 'active', 'company', 
                 'dosage_form', 'dosage_form_ar', 'concentration', 'unit', 'usage', 'pharmacology', 
                 'barcode', 'qr_code', 'visits', 'last_price_update', 'updated_at', 'indication', 
                 'mechanism_of_action', 'pharmacodynamics', 'data_source_pharmacology', 
                 'has_drug_interaction', 'has_food_interaction', 'has_disease_interaction', 
                 'description', 'atc_codes', 'external_links']
    write_chunk("drugs", "d1_import", drugs, drug_cols)
    
    # Note: drug_interactions, food_interactions, and disease_interactions 
    # are now handled by migrate_interactions.py and synced to INTERACTIONS_DB.
    # They are removed from here to keep the main DB small.
    
    # 3. تصدير المكونات (med_ingredients)
    print("\n🧬 تصدير المكونات (med_ingredients)...")
    cursor = conn.execute("SELECT * FROM med_ingredients")
    ingredients = [dict(row) for row in cursor.fetchall()]
    if ingredients:
        write_chunk("med_ingredients", "d1_ingredients", ingredients, ['med_id', 'ingredient', 'updated_at'])
    else:
        print("  ⚠️ جدول المكونات فارغ - التخطي")
    
    # Food and Disease interactions are also moved to INTERACTIONS_DB.
    
    # 6. تصدير الجرعات (dosage_guidelines)
    print("\n💉 تصدير إرشادات الجرعات (dosage_guidelines)...")
    cursor = conn.execute("SELECT * FROM dosage_guidelines")
    dosages = [dict(row) for row in cursor.fetchall()]
    dosage_cols = ['id', 'med_id', 'dailymed_setid', 'min_dose', 'max_dose', 'frequency', 
                   'duration', 'instructions', 'condition', 'source', 'is_pediatric']
    write_chunk("dosage_guidelines", "d1_dosages", dosages, dosage_cols)
    
    conn.close()
    print("\n✅ اكتمل التصدير بنجاح!")
    print(f"📂 الملفات محفوظة في: {CHUNK_DIR}/")

if __name__ == "__main__":
    export_from_db()
