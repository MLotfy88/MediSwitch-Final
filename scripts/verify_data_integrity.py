
import sqlite3
import zlib
import textwrap

DB_PATH = "assets/database/mediswitch.db"

def decompress_text(blob):
    if not blob: return "[NULL]"
    try:
        # Try zlib decompression
        return zlib.decompress(blob).decode('utf-8')
    except:
        try:
            # Maybe it's just utf-8 bytes?
            return blob.decode('utf-8')
        except:
            return f"[BINARY/COMPRESSED Data len={len(blob)}]"

def run_verification():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    print("🔍 Searching for drugs with FULL Data (WikEM + NCBI)...")
    
    # Query for records having WikEM Instructions AND NCBI Indications
    # This implies a successful merge of both data sources
    query = """
    SELECT 
        d.trade_name, 
        d.concentration,
        g.*
    FROM dosage_guidelines g
    JOIN drugs d ON g.med_id = d.id
    WHERE g.source = 'WikEM'
      AND g.wikem_instructions IS NOT NULL 
      AND (g.ncbi_indications IS NOT NULL OR g.ncbi_contraindications IS NOT NULL)
    LIMIT 5;
    """
    
    cursor.execute(query)
    rows = cursor.fetchall()
    
    if not rows:
        print("⚠️ No drugs found with BOTH WikEM and NCBI data populated in the same row.")
        print("Let's check them separately to understand the overlap coverage.")
        
        cursor.execute("SELECT COUNT(*) FROM dosage_guidelines WHERE wikem_instructions IS NOT NULL")
        wikem_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM dosage_guidelines WHERE ncbi_indications IS NOT NULL")
        ncbi_count = cursor.fetchone()[0]
        
        print(f"Stats:\n- Rows with WikEM: {wikem_count}\n- Rows with NCBI: {ncbi_count}")
        return

    print(f"✅ Found {len(rows)} perfect examples (Both sources present).\n")

    for i, row in enumerate(rows):
        print(f"💊 EXAMPLE #{i+1}: {row['trade_name']} (Conc: {row['concentration']})")
        print("="*60)
        
        # 1. Structured WikEM Data
        print(f"📊 [WikEM Structure]")
        print(f"   - Dose: {row['wikem_min_dose']} - {row['wikem_max_dose']} {row['wikem_dose_unit']}")
        print(f"   - Route: {row['wikem_route']}")
        print(f"   - Freq: {row['wikem_frequency']}")
        print(f"   - Cat: {row['wikem_patient_category']}")
        
        # 2. Text Content (Decompressed)
        w_instr = decompress_text(row['wikem_instructions'])
        n_ind = decompress_text(row['ncbi_indications'])
        n_contra = decompress_text(row['ncbi_contraindications'])
        
        print(f"\n📝 [WikEM Instructions] (First 200 chars):")
        print(textwrap.fill(w_instr[:200] + "...", width=60, initial_indent="   ", subsequent_indent="   "))
        
        print(f"\n🏛️ [NCBI Indications] (First 200 chars):")
        print(textwrap.fill(n_ind[:200] + "...", width=60, initial_indent="   ", subsequent_indent="   "))

        print(f"\n⛔ [NCBI Contraindications] (First 100 chars):")
        print(textwrap.fill(n_contra[:100] + "...", width=60, initial_indent="   ", subsequent_indent="   "))
        
        print("\n" + "-"*60 + "\n")

    conn.close()

if __name__ == "__main__":
    run_verification()
