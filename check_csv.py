
import csv
import sys

csv_file = 'assets/external_research_data/updated/csv_exports/drug_drug_interactions.csv'

print(f"📊 Analyzing CSV: {csv_file}")

try:
    with open(csv_file, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        total_rows = 0
        filled_mech = 0
        filled_desc = 0
        filled_mgmt = 0
        
        for row in reader:
            total_rows += 1
            
            # Check fields (adjust keys based on CSV header)
            if row.get('mechanism_flags') and row.get('mechanism_flags') != '[]':
                filled_mech += 1
            if row.get('interaction_description'):
                filled_desc += 1
            if row.get('management_text'):
                filled_mgmt += 1
                
        print(f"Total Rows: {total_rows:,}")
        print(f"Mechanism Flags: {filled_mech:,} ({(filled_mech/total_rows)*100:.1f}%)")
        print(f"Descriptions: {filled_desc:,} ({(filled_desc/total_rows)*100:.1f}%)")
        print(f"Management Text: {filled_mgmt:,} ({(filled_mgmt/total_rows)*100:.1f}%)")

except Exception as e:
    print(f"❌ Error: {e}")
