
import sqlite3
import zlib
import textwrap

DB_PATH = "assets/database/mediswitch.db"

def decompress(blob):
    if not blob: return "NULL"
    try:
        return zlib.decompress(blob).decode('utf-8')
    except:
        try:
            return blob.decode('utf-8')
        except:
            return f"[BINARY LEN={len(blob)}]"

def print_section(title, content):
    print(f"\n🔹 {title}:")
    if content == "NULL":
        print("   (No Data)")
    else:
        # Wrap text for readability
        print(textwrap.fill(content, width=80, initial_indent="   ", subsequent_indent="   "))

def show_drug(cursor, trade_name_like):
    print("\n" + "#"*80)
    print(f"🔍 SEARCHING FOR: {trade_name_like}")
    print("#"*80)
    
    query = """
    SELECT 
        d.trade_name, g.source,
        g.wikem_min_dose, g.wikem_max_dose, g.wikem_dose_unit,
        g.wikem_route, g.wikem_frequency, g.wikem_patient_category,
        g.wikem_instructions,
        g.ncbi_indications, g.ncbi_contraindications, g.ncbi_adverse_effects
    FROM dosage_guidelines g
    JOIN drugs d ON g.med_id = d.id
    WHERE d.trade_name LIKE ?
    LIMIT 1
    """
    
    cursor.execute(query, (f"%{trade_name_like}%",))
    row = cursor.fetchone()
    
    if not row:
        print("❌ No data found.")
        return

    print(f"💊 DRUG: {row['trade_name']}")
    print(f"🏷️ SOURCE: {row['source']}")
    print("-" * 40)
    
    # Structured Data
    print("📊 STRUCTURED DOSAGE (WikEM):")
    print(f"   • Min Dose: {row['wikem_min_dose']}")
    print(f"   • Max Dose: {row['wikem_max_dose']}")
    print(f"   • Unit:     {row['wikem_dose_unit']}")
    print(f"   • Route:    {row['wikem_route']}")
    print(f"   • Freq:     {row['wikem_frequency']}")
    print(f"   • Category: {row['wikem_patient_category']}")
    
    # Text Data
    print_section("WikEM Instructions (Full Text)", decompress(row['wikem_instructions']))
    print_section("NCBI Indications", decompress(row['ncbi_indications']))
    print_section("NCBI Contraindications", decompress(row['ncbi_contraindications']))
    
def run():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    # Show the problematic drug and a standard one
    show_drug(cursor, "1 2 3")
    show_drug(cursor, "Haldol")
    show_drug(cursor, "Cyclophosphamide") 
    
    conn.close()

if __name__ == "__main__":
    run()
