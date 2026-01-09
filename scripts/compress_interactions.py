import sqlite3
import zlib
import time

DB_PATH = 'assets/database/mediswitch.db'

def compress_interactions():
    print("="*80)
    print("📦 ضغط جداول التفاعلات (Drug & Disease Interactions)")
    print("="*80)
    
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    # Configuration: Table -> Columns to compress
    targets = {
        'drug_interactions': [
            'effect', 
            'management_text', 
            'recommendation', 
            'alternatives_a', 
            'alternatives_b'
        ],
        'disease_interactions': [
            'interaction_text'
        ]
    }
    
    for table, cols in targets.items():
        print(f"\n🔄 معالجة الجدول: {table}")
        
        # Check existing columns
        cursor.execute(f"PRAGMA table_info({table})")
        existing = {row['name'] for row in cursor.fetchall()}
        valid_cols = [c for c in cols if c in existing]
        
        if not valid_cols:
            print(f"   ⚠️ لا توجد أعمدة صالحة للضغط في هذا الجدول.")
            continue
            
        print(f"   📝 الأعمدة المستهدفة: {', '.join(valid_cols)}")
        
        # Get Rows
        cursor.execute(f"SELECT count(*) FROM {table}")
        count = cursor.fetchone()[0]
        print(f"   📊 عدد السجلات: {count:,}")
        
        cursor.execute(f"SELECT id FROM {table}")
        all_ids = [r[0] for r in cursor.fetchall()]
        
        BATCH_SIZE = 2000
        processed = 0
        
        for i in range(0, len(all_ids), BATCH_SIZE):
            batch_ids = all_ids[i:i+BATCH_SIZE]
            id_str = ','.join('?' * len(batch_ids))
            
            sel_query = f"SELECT id, {','.join(valid_cols)} FROM {table} WHERE id IN ({id_str})"
            cursor.execute(sel_query, batch_ids)
            rows = cursor.fetchall()
            
            updates = []
            for row in rows:
                vals = []
                for col in valid_cols:
                    val = row[col]
                    if isinstance(val, str) and len(val) > 0:
                        vals.append(zlib.compress(val.encode('utf-8')))
                    else:
                        vals.append(val)
                vals.append(row['id'])
                updates.append(vals)
                
            set_clause = ', '.join([f"{c}=?" for c in valid_cols])
            upd_query = f"UPDATE {table} SET {set_clause} WHERE id=?"
            cursor.executemany(upd_query, updates)
            conn.commit()
            
            processed += len(updates)
            if processed % 10000 == 0:
                print(f"     - تم {processed:,}...")

    print("\n🧹 جاري إعادة بناء قاعدة البيانات (VACUUM)...")
    cursor.execute("VACUUM")
    print("✅ تم تحرير المساحة بنجاح.")
    conn.close()

if __name__ == "__main__":
    compress_interactions()
