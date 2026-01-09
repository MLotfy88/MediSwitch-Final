
import sqlite3
import zlib
import os

DB_PATH = '/home/adminlotfy/project/assets/database/mediswitch.db'
OUTPUT_FILE = '/home/adminlotfy/project/Dormicum_Full_Text_Analysis.txt'

def decompress_text(data):
    if data is None:
        return "NULL"
    if isinstance(data, str):
        return data
    if isinstance(data, bytes):
        try:
            return zlib.decompress(data).decode('utf-8')
        except:
            try:
                return data.decode('utf-8', errors='ignore')
            except:
                return f"<BINARY DATA: {len(data)} bytes>"
    return str(data)

conn = sqlite3.connect(DB_PATH)
cursor = conn.cursor()

# 1. Get Drug ID
cursor.execute("SELECT id, trade_name FROM drugs WHERE trade_name LIKE '%Dormicum%' LIMIT 1")
drug = cursor.fetchone()

if not drug:
    print("❌ Dormicum not found.")
else:
    drug_id, drug_name = drug
    
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        f.write(f"==================================================\n")
        f.write(f"FULL TEXT ANALYSIS FOR: {drug_name} (ID: {drug_id})\n")
        f.write(f"==================================================\n\n")

        # 2. Get All Text Columns from dosage_guidelines
        # Columns based on what we know exist and usually have big text
        columns = [
            'instructions', 
            'warnings', 
            'contraindications', 
            'adverse_reactions', 
            'black_box_warning', 
            'overdose_management',
            'special_populations', 
            'renal_adjustment', 
            'hepatic_adjustment'
        ]
        
        query_cols = ", ".join(columns)
        cursor.execute(f"SELECT source, {query_cols} FROM dosage_guidelines WHERE med_id = ?", (drug_id,))
        rows = cursor.fetchall()
        
        if not rows:
            f.write("❌ No dosage guidelines found.\n")
        else:
            for i, row in enumerate(rows):
                source = row[0]
                f.write(f"--- RECORD #{i+1} (Source: {source}) ---\n")
                
                for col_idx, col_name in enumerate(columns):
                    raw_data = row[col_idx + 1] # +1 because source is 0
                    
                    full_text = decompress_text(raw_data)
                    
                    f.write(f"\n>>> COLUMN: {col_name.upper()}\n")
                    f.write(f"    Raw Type: {type(raw_data)}\n")
                    f.write(f"    Length: {len(full_text)} chars\n")
                    f.write(f"    Content Preview (First 500 chars):\n")
                    f.write(f"{'-'*40}\n")
                    f.write(f"{full_text[:500]}...\n") # First 500 for quick view
                    f.write(f"{'-'*40}\n")
                    
                    # Also write full content section if it's large
                    if len(full_text) > 500:
                         f.write(f"\n    [FULL CONTENT DUMP FOR {col_name.upper()}]\n")
                         f.write(f"{full_text}\n")
                         f.write(f"{'='*20} END OF COLUMN {'='*20}\n")
                
                f.write(f"\n{'#'*60}\n\n")

conn.close()
print(f"✅ Full analysis saved to: {OUTPUT_FILE}")
