import pandas as pd
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
            df = pd.read_csv(f)
            # Standard DDInter CSV columns: DDInterID_A, Drug_A, DDInterID_B, Drug_B, Level
            if 'DDInterID_A' in df.columns:
                unique_drugs.update(df['DDInterID_A'].dropna().unique())
            if 'DDInterID_B' in df.columns:
                unique_drugs.update(df['DDInterID_B'].dropna().unique())
            
            for _, row in df.iterrows():
                pairs.append({
                    "a": row['DDInterID_A'],
                    "b": row['DDInterID_B'],
                    "level": row['Level']
                })
        except Exception as e:
            print(f"Error reading {f}: {e}")
            
    result = {
        "unique_drug_count": len(unique_drugs),
        "unique_drugs": sorted(list(unique_drugs)),
        "total_pairs": len(pairs),
        "pairs": pairs
    }
    
    with open("discovered_ids.json", "w") as f:
        json.dump(result, f, indent=2)
    
    print(f"Discovery complete. Found {len(unique_drugs)} unique drugs and {len(pairs)} pairs.")

if __name__ == "__main__":
    discover_ids()
