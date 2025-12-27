import csv
import os
import glob
import json

def discover_ids():
    csv_files = glob.glob("ddinter_downloads_code_*.csv")
    unique_drugs = set()
    pairs = []
    
    for f in csv_files:
        print(f"Processing {f}...")
        try:
            with open(f, mode='r', encoding='utf-8') as csvfile:
                # Use Sniffer to handle delimiters if needed, or assume comma
                reader = csv.DictReader(csvfile)
                for row in reader:
                    id_a = row.get('DDInterID_A')
                    id_b = row.get('DDInterID_B')
                    level = row.get('Level')
                    
                    if id_a: unique_drugs.add(id_a)
                    if id_b: unique_drugs.add(id_b)
                    
                    if id_a and id_b:
                        pairs.append({
                            "a": id_a,
                            "b": id_b,
                            "level": level
                        })
        except Exception as e:
            print(f"Error reading {f}: {e}")
            
    result = {
        "unique_drug_count": len(unique_drugs),
        "unique_drugs": sorted(list(unique_drugs)),
        "total_pairs": len(pairs)
    }
    
    # Store only drug list initially to keep it light
    with open("unique_drugs.json", "w") as f:
        json.dump(result, f, indent=2)
    
    print(f"Discovery complete. Found {len(unique_drugs)} unique drugs.")

if __name__ == "__main__":
    discover_ids()
