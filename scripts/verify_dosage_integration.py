#!/usr/bin/env python3
"""
Integration Verification Script
================================
Quick validation of WikEM + NCBI hybrid dosage integration
"""

import sqlite3
from pathlib import Path

DB_PATH = Path("assets/database/mediswitch.db")

def verify_integration():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    print("=" * 60)
    print("📊 DOSAGE INTEGRATION VERIFICATION REPORT")
    print("=" * 60)
    print()
    
    # 1. Total dosage records
    cursor.execute("SELECT COUNT(*) FROM dosage_guidelines")
    total_records = cursor.fetchone()[0]
    print(f"📌 Total Dosage Records: {total_records:,}")
    
    # 2. WikEM coverage
    cursor.execute("""
        SELECT COUNT(DISTINCT med_id) FROM dosage_guidelines 
        WHERE source = 'WikEM'
    """)
    wikem_count = cursor.fetchone()[0]
    print(f"✅ Drugs with WikEM data: {wikem_count:,}")
    
    # 3. NCBI coverage
    cursor.execute("""
        SELECT COUNT(DISTINCT med_id) FROM dosage_guidelines 
        WHERE source = 'NCBI'
    """)
    ncbi_count = cursor.fetchone()[0]
    print(f"🔬 Drugs with NCBI data: {ncbi_count:,}")
    
    # 4. Total unique drugs with dosage info
    cursor.execute("""
        SELECT COUNT(DISTINCT med_id) FROM dosage_guidelines
    """)
    total_drugs = cursor.fetchone()[0]
    print(f"💊 Total Drugs with Dosage Info: {total_drugs:,}")
    
    # 5. Sample WikEM record
    print("\n" + "=" * 60)
    print("🔍 SAMPLE WikEM RECORD:")
    print("=" * 60)
    cursor.execute("""
        SELECT 
            wikem_min_dose, wikem_max_dose, wikem_dose_unit, 
            wikem_route, wikem_patient_category, wikem_instructions
        FROM dosage_guidelines 
        WHERE source = 'WikEM' AND wikem_instructions IS NOT NULL
        LIMIT 1
    """)
    row = cursor.fetchone()
    if row:
        print(f"Min Dose: {row[0]}")
        print(f"Max Dose: {row[1]}")
        print(f"Unit: {row[2]}")
        print(f"Route: {row[3]}")
        print(f"Category: {row[4]}")
        print(f"Instructions: {row[5][:100]}...")
    
    # 6. Sample NCBI record
    print("\n" + "=" * 60)
    print("🔍 SAMPLE NCBI RECORD:")
    print("=" * 60)
    cursor.execute("""
        SELECT 
            ncbi_indications, ncbi_administration, ncbi_contraindications
        FROM dosage_guidelines 
        WHERE source = 'NCBI' AND ncbi_administration IS NOT NULL
        LIMIT 1
    """)
    row = cursor.fetchone()
    if row:
        print(f"Indications: {row[0][:100] if row[0] else 'N/A'}...")
        print(f"Administration: {row[1][:100] if row[1] else 'N/A'}...")
        print(f"Contraindications: {row[2][:100] if row[2] else 'N/A'}...")
    
    # 7. Coverage percentage
    cursor.execute("SELECT COUNT(DISTINCT id) FROM drugs")
    total_drugs_in_db = cursor.fetchone()[0]
    coverage = (total_drugs / total_drugs_in_db) * 100 if total_drugs_in_db > 0 else 0
    
    print("\n" + "=" * 60)
    print(f"📈 COVERAGE: {coverage:.1f}% of drugs have dosage information")
    print("=" * 60)
    
    conn.close()

if __name__ == "__main__":
    verify_integration()
