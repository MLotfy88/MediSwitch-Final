import sqlite3
import zlib
import json

DB_PATH = 'assets/database/mediswitch.db'

def compress_data(data):
    if not data:
        return None
    if isinstance(data, str):
        return zlib.compress(data.encode('utf-8'))
    return data

def optimize_database():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    print("1. Reading existing schema...")
    cursor.execute("PRAGMA table_info(dosage_guidelines)")
    columns_info = cursor.fetchall()
    columns = [info[1] for info in columns_info]
    print(f"Source columns: {columns}")
    
    # Define which columns should be compressed
    compress_targets = {
        'wikem_instructions',
        'ncbi_indications',
        'ncbi_contraindications',
        'ncbi_mechanism',
        'ncbi_adverse_effects',
        'ncbi_monitoring',
        'ncbi_administration',
        'ncbi_toxicity'
    }
    
    # Build CREATE TABLE statement preserving types but changing targets to BLOB
    create_parts = []
    for info in columns_info:
        name = info[1]
        type_ = info[2]
        if name in compress_targets:
            type_ = 'BLOB'
        
        part = f"{name} {type_}"
        if info[5] == 1: # PK
            part += " PRIMARY KEY AUTOINCREMENT"
        create_parts.append(part)
        
    create_sql = f"CREATE TABLE dosage_guidelines_optimized ({', '.join(create_parts)})"
    
    print("2. Creating optimized table...")
    cursor.execute("DROP TABLE IF EXISTS dosage_guidelines_optimized")
    cursor.execute(create_sql)
    
    print("3. Reading and compressing data...")
    cursor.execute(f"SELECT {', '.join(columns)} FROM dosage_guidelines")
    rows = cursor.fetchall()
    
    compressed_rows = []
    for row in rows:
        new_row = []
        for idx, val in enumerate(row):
            col_name = columns[idx]
            if col_name in compress_targets and val is not None:
                new_row.append(compress_data(val))
            else:
                new_row.append(val)
        compressed_rows.append(tuple(new_row))
        
    print(f"Compressing {len(compressed_rows)} rows...")
    placeholders = ', '.join(['?'] * len(columns))
    cursor.executemany(f"INSERT INTO dosage_guidelines_optimized VALUES ({placeholders})", compressed_rows)
    
    print("4. Replacing old table...")
    cursor.execute("DROP TABLE dosage_guidelines")
    cursor.execute("ALTER TABLE dosage_guidelines_optimized RENAME TO dosage_guidelines")
    
    print("5. Linking duplicate ingredients (filling gaps)...")
    # Find drugs with NO dosage data
    cursor.execute("""
    SELECT d.id, d.active 
    FROM drugs d 
    LEFT JOIN dosage_guidelines dg ON d.id = dg.med_id 
    WHERE dg.id IS NULL AND d.active IS NOT NULL AND d.active != ''
    """)
    missing_drugs = cursor.fetchall()
    print(f"Found {len(missing_drugs)} drugs with missing dosage data.")
    
    # Get all available dosages keyed by active ingredient
    # We select ALL columns. Note: med_id is usually column at index 1 (0-based) but we must check.
    # We should exclude ID (PK) and med_id when copying.
    
    # Get indices for ID and MED_ID
    id_idx = columns.index('id')
    med_id_idx = columns.index('med_id')
    
    cursor.execute(f"SELECT * FROM dosage_guidelines")
    available_rows = cursor.fetchall()
    
    # Create valid dosage map: Active -> List of Row Tuples
    # To map active ingredient back to rows, we need a lookup of med_id -> active
    cursor.execute("SELECT id, active FROM drugs")
    drug_actives = {row[0]: row[1].lower().strip() for row in cursor.fetchall() if row[1]}
    
    dosage_map = {}
    for row in available_rows:
        mid = row[med_id_idx]
        if mid in drug_actives:
            active = drug_actives[mid]
            if active not in dosage_map:
                dosage_map[active] = []
            dosage_map[active].append(row)
            
    # Insert missing links
    new_links = 0
    insert_cols = [c for c in columns if c != 'id'] # All except ID
    insert_sql = f"INSERT INTO dosage_guidelines ({', '.join(insert_cols)}) VALUES ({', '.join(['?'] * len(insert_cols))})"
    
    rows_to_insert = []
    
    for drug_id, active in missing_drugs:
        active_key = active.lower().strip()
        if active_key in dosage_map:
            # Found a match!
            source_row = dosage_map[active_key][0]
            
            # Create new row: Copy source, but replace med_id with current drug_id
            # Also skip the source ID
            valid_data = []
            for i, val in enumerate(source_row):
                if i == id_idx:
                    continue # Skip ID (autoincrement)
                elif i == med_id_idx:
                    valid_data.append(drug_id) # Set new med_id
                else:
                    valid_data.append(val)
            
            rows_to_insert.append(tuple(valid_data))
            new_links += 1
            
    if rows_to_insert:
        print(f"Linking {len(rows_to_insert)} records...")
        cursor.executemany(insert_sql, rows_to_insert)
    
    print(f"Linked {new_links} missing drugs.")
    
    # Commit transaction before VACUUM
    conn.commit()
    
    print("6. Vacuuming database...")
    # VACUUM cannot run in a transaction
    original_isolation = conn.isolation_level
    conn.isolation_level = None
    cursor.execute("VACUUM")
    conn.isolation_level = original_isolation
    
    conn.close()
    print("Optimization complete.")

if __name__ == "__main__":
    optimize_database()
