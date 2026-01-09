import sqlite3
import zlib
import time
import os

DB_PATH = 'assets/database/mediswitch.db'

def compress_database():
    print("="*80)
    print("📦 ضغط النصوص في قاعدة البيانات (ZLIB Compression)")
    print("="*80)
    
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    # 1. Identify columns to compress
    # We target the largest text columns
    targets = [
        'instructions', 
        'warnings', 
        'contraindications', 
        'precautions', 
        'adverse_reactions',
        'renal_adjustment', 
        'hepatic_adjustment', 
        'black_box_warning',
        'overdose_management',
        'indication',
        'special_populations',
        'pregnancy_category',
        'lactation_info'
    ]
    
    # Check which ones actually exist
    cursor.execute("PRAGMA table_info(dosage_guidelines)")
    existing_cols = {row['name'] for row in cursor.fetchall()}
    cols_to_compress = [c for c in targets if c in existing_cols]
    
    print(f"📝 الأعمدة المستهدفة ({len(cols_to_compress)}): {', '.join(cols_to_compress)}")
    
    # 2. Process Records
    cursor.execute("SELECT count(*) FROM dosage_guidelines WHERE source = 'DailyMed SPL Enhanced'")
    total_rows = cursor.fetchone()[0]
    
    print(f"🔄 جاري معالجة {total_rows} سجل...")
    
    start_time = time.time()
    
    # We fetch IDs first to batch process updates
    cursor.execute("SELECT id FROM dosage_guidelines WHERE source = 'DailyMed SPL Enhanced'")
    all_ids = [r[0] for r in cursor.fetchall()]
    
    BATCH_SIZE = 1000
    processed_count = 0
    total_compressed_bytes = 0
    total_original_bytes = 0
    
    for i in range(0, len(all_ids), BATCH_SIZE):
        batch_ids = all_ids[i:i+BATCH_SIZE]
        id_placeholders = ','.join('?' * len(batch_ids))
        
        # Select data
        sel_sql = f"SELECT id, {','.join(cols_to_compress)} FROM dosage_guidelines WHERE id IN ({id_placeholders})"
        cursor.execute(sel_sql, batch_ids)
        rows = cursor.fetchall()
        
        updates = []
        
        for row in rows:
            update_vals = []
            for col in cols_to_compress:
                original_val = row[col]
                
                # Only compress if it's a non-empty string
                if isinstance(original_val, str) and len(original_val) > 0:
                    original_bytes = original_val.encode('utf-8')
                    compressed_val = zlib.compress(original_bytes)
                    
                    total_original_bytes += len(original_bytes)
                    total_compressed_bytes += len(compressed_val)
                    
                    update_vals.append(compressed_val)
                else:
                    update_vals.append(original_val)
            
            update_vals.append(row['id'])
            updates.append(update_vals)
        
        # Update Database
        set_clause = ', '.join([f"{c} = ?" for c in cols_to_compress])
        upd_sql = f"UPDATE dosage_guidelines SET {set_clause} WHERE id = ?"
        cursor.executemany(upd_sql, updates)
        conn.commit()
        
        processed_count += len(batch_ids)
        if processed_count % 5000 == 0:
            print(f"   - تم إنجاز {processed_count}/{total_rows}...")

    print(f"✅ تم ضغط البيانات.")
    if total_original_bytes > 0:
        ratio = (1 - (total_compressed_bytes / total_original_bytes)) * 100
        print(f"📊 إحصائيات الضغط للنصوص:")
        print(f"   - الحجم الأصلي: {total_original_bytes / (1024*1024):.2f} MB")
        print(f"   - الحجم المضغوط: {total_compressed_bytes / (1024*1024):.2f} MB")
        print(f"   - نسبة التوفير: {ratio:.1f}%")

    # 3. VACUUM
    print("🧹 جاري إعادة بناء قاعدة البيانات (VACUUM) لتحرير المساحة...")
    cursor.execute("VACUUM")
    print("✅ تم تحرير المساحة.")
    
    conn.close()

if __name__ == "__main__":
    compress_database()
