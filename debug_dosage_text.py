import sqlite3
import os

db_path = "/tmp/full.db"

if not os.path.exists(db_path):
    print(f"Database not found at {db_path}")
    exit(1)

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Search for Levepex or Levetiracetam
drug_name = "Levetiracetam"
print(f"Searching for guidelines for active ingredient: {drug_name}")

# First find the drug ID or active ingredient match in drugs table if needed, 
# but dosage_guidelines uses medicine_id which links to drugs.id
# Let's search drugs first to get the ID for Levepex/Levetiracetam
cursor.execute("SELECT id, trade_name, active FROM drugs WHERE trade_name LIKE '%Levepex%' OR active LIKE '%Levetiracetam%' LIMIT 5")
drugs = cursor.fetchall()

if not drugs:
    print("No drugs found matching Levepex or Levetiracetam")
else:
    for drug in drugs:
        drug_id, trade_name, active = drug
        print(f"Found Drug: ID={drug_id}, Name={trade_name}, Active={active}")
        
        # Now query dosage_guidelines for this drug_id
        cursor.execute("SELECT instructions, min_dose, max_dose, frequency FROM dosage_guidelines WHERE med_id = ?", (drug_id,))
        guidelines = cursor.fetchall()
        
        if guidelines:
            print(f"  -> Found {len(guidelines)} guidelines:")
            for g in guidelines:
                instructions, min, max_d, freq = g
                print(f"     Min: {min}, Max: {max_d}, Freq: {freq}")
                print(f"     RAW INSTRUCTIONS:\n{instructions}\n")
                print("-" * 50)
        else:
            print("  -> No dosage guidelines found for this drug.")

conn.close()
