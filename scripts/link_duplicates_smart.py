import sqlite3
import re

DB_PATH = 'assets/database/mediswitch.db'

def normalize(text):
    if not text: return ""
    return text.lower().strip()

def smart_link():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    print("1. Fetching available dosages...")
    cursor.execute("""
        SELECT d.active, dg.* 
        FROM dosage_guidelines dg
        JOIN drugs d ON dg.med_id = d.id
        WHERE d.active IS NOT NULL AND d.active != ''
    """)
    available_rows = cursor.fetchall()
    
    # Get column names to handle indices properly
    cursor.execute("PRAGMA table_info(dosage_guidelines)")
    columns = [info[1] for info in cursor.fetchall()]
    id_idx = columns.index('id')
    med_id_idx = columns.index('med_id')
    
    # Map: active_string -> list of rows
    # Use a set of unique active strings for fast updating
    available_map = {}
    for row in available_rows:
        active = normalize(row[0])
        if active not in available_map:
            available_map[active] = row[1:] # Exclude active string from data
    
    print(f"Found {len(available_map)} unique active ingredients with dosage.")

    print("2. Finding missing drugs...")
    cursor.execute("""
        SELECT d.id, d.active 
        FROM drugs d 
        LEFT JOIN dosage_guidelines dg ON d.id = dg.med_id 
        WHERE dg.id IS NULL AND d.active IS NOT NULL AND d.active != ''
    """)
    missing_drugs = cursor.fetchall()
    print(f"Found {len(missing_drugs)} drugs without dosage.")
    
    rows_to_insert = []
    
    # 3. Matching Logic
    # We want to find if 'missing' matches any 'available'.
    # Rules:
    # 1. Exact match
    # 2. missing contains available (e.g. "Paracetamol (Acetaminophen)" contains "Paracetamol")
    # 3. available contains missing
    
    # Pre-compute available keys list for iteration
    avail_keys = list(available_map.keys())
    
    for drug_id, raw_active in missing_drugs:
        missing = normalize(raw_active)
        
        match_row = None
        
        # Strategy A: Check exact match
        if missing in available_map:
            match_row = available_map[missing]
        else:
            # Strategy B: Substring match
            # This is O(N*M), but N=2500, M=1000 -> 2.5M ops. Fast enough.
            for key in avail_keys:
                # Check simple containment
                if key in missing or missing in key:
                    # Potential false positive: "Cin" in "Cinacalcet"? No, usually active ingredients are distinct enough.
                    # But "Iron" in "Iron Sucrose" is good.
                    # "Cef" in "Cefalexin"? No, strict substring might be dangerous.
                    # Let's enforce length constraint or token match?
                    # "Paracetamol" in "Paracetamol + Caffeine" -> OK to use Paracetamol dosage?
                    # Maybe. The user wants to fill gaps.
                    # Safer: logic from "Paracetamol(Acetaminophen)" -> strip parens.
                    
                    # Clean parens
                    missing_clean = re.sub(r'\(.*?\)', '', missing).strip()
                    key_clean = re.sub(r'\(.*?\)', '', key).strip()
                    
                    if missing_clean == key_clean and missing_clean:
                        match_row = available_map[key]
                        break
                    
                    # Split by '+'
                    # If missing is "A+B" and we have dosage for "A", do we use it?
                    # Arguable. Maybe unsafe.
                    # User said "components duplicated (same drug different concentration)".
                    # This implies exact ingredient match.
                    # So "Paracetamol" vs "Paracetamol (Acetaminophen)" is the main case.
                    
                    if key in missing and len(key) > 4: # Avoid small matches like "Iron"
                         # Heuristic match
                         match_row = available_map[key]
                         break
                         
        if match_row:
            # Prepare row
            new_data = [drug_id] # New med_id
            for i, val in enumerate(match_row):
                # match_row indices follow schema excluding 'active'.
                # But match_row comes from SELECT dg.*.
                # So it has ID at id_idx, med_id at med_id_idx.
                # We need to skip ID and med_id from source, and put new med_id.
                
                # Wait, 'match_row' is exactly `row[1:]` from the first query.
                # The first query was `SELECT d.active, dg.*`.
                # So `row` len = 1 + sorted columns count.
                # `row[1]` is `id`. `row[2]` is `med_id`.
                
                # So match_row[0] is ID. match_row[1] is med_id.
                
                if i == 0: continue # Skip ID
                if i == 1: continue # Skip med_id
                
                new_data.append(val)
                
            rows_to_insert.append(tuple(new_data))
            
    # Insert
    if rows_to_insert:
        print(f"Linking {len(rows_to_insert)} matches...")
        insert_cols = [c for c in columns if c != 'id']
        placeholders = ', '.join(['?'] * len(insert_cols))
        cursor.executemany(f"INSERT INTO dosage_guidelines ({', '.join(insert_cols)}) VALUES ({placeholders})", rows_to_insert)
        conn.commit()
    else:
        print("No matches found.")
        
    conn.close()

if __name__ == "__main__":
    smart_link()
