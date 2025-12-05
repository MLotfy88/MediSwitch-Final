import csv
import sys
import os
import shutil
from datetime import datetime

def merge_csv(main_file, update_file, output_file=None):
    """
    Merges update_file into main_file based on the 'id' column.
    Updates existing records and appends new ones.
    """
    if output_file is None:
        output_file = main_file

    print(f"Loading main database from: {main_file}")
    if not os.path.exists(main_file):
        print(f"Error: Main file {main_file} not found.")
        return

    # Read main file
    meds_db = {}
    fieldnames = []
    
    try:
        with open(main_file, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            fieldnames = reader.fieldnames
            for row in reader:
                if 'id' in row and row['id']:
                    meds_db[row['id']] = row
    except Exception as e:
        print(f"Error reading main file: {e}")
        return

    print(f"Loaded {len(meds_db)} records from main database.")

    print(f"Loading updates from: {update_file}")
    if not os.path.exists(update_file):
        print(f"Error: Update file {update_file} not found.")
        return

    updates_count = 0
    new_count = 0
    
    changes_report = []
    
    try:
        with open(update_file, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            # Ensure we have all fields from the update file too
            for field in reader.fieldnames:
                if field not in fieldnames:
                    fieldnames.append(field)
            
            for row in reader:
                if 'id' not in row or not row['id']:
                    continue
                
                drug_id = row['id']
                
                # Check for price change
                if drug_id in meds_db:
                    old_row = meds_db[drug_id]
                    try:
                        old_price = float(old_row.get('price', 0))
                        new_price = float(row.get('price', 0))
                        
                        if abs(new_price - old_price) > 0.01: # Check for meaningful difference
                            change_pct = ((new_price - old_price) / old_price * 100) if old_price != 0 else 0
                            arrow = "📈" if new_price > old_price else "📉"
                            name_ar = row.get('arabic_name', 'Unknown')
                            name_en = row.get('trade_name', 'Unknown')
                            
                            changes_report.append(f"• *{name_ar}* ({name_en})\n  {old_price} ← {new_price} ج.م {arrow} ({change_pct:+.1f}%)")
                    except ValueError:
                        pass # Skip valid price checks if data is bad

                    # Update existing record
                    meds_db[drug_id].update(row)
                    updates_count += 1
                else:
                    # New record logic (Optional: Add to report as NEW)
                    # meds_db[drug_id] = row
                    # new_count += 1
                    try:
                         new_price = float(row.get('price', 0))
                         name_ar = row.get('arabic_name', 'Unknown')
                         name_en = row.get('trade_name', 'Unknown')
                         changes_report.append(f"• 🆕 *{name_ar}* ({name_en})\n  السعر: {new_price} ج.م")
                    except:
                        pass
                    
                    meds_db[drug_id] = row
                    new_count += 1
    except Exception as e:
        print(f"Error reading update file: {e}")
        return

    print(f"Processed updates: {updates_count} updated, {new_count} new.")
    
    # Save formatted report for Slack
    with open('changes_report.txt', 'w', encoding='utf-8') as report_file:
        if changes_report:
            report_file.write("\n".join(changes_report[:10])) # Limit to top 10 to avoid spam
            if len(changes_report) > 10:
                report_file.write(f"\n... و {len(changes_report)-10} منتجات أخرى")

    # Create backup before writing
    backup_file = f"{main_file}.backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    shutil.copy2(main_file, backup_file)
    print(f"Created backup at: {backup_file}")

    # Write merged data
    print(f"Writing merged database to: {output_file}")
    try:
        with open(output_file, 'w', encoding='utf-8', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(meds_db.values())
        print("Merge completed successfully.")
    except Exception as e:
        print(f"Error writing output file: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python merge_meds.py <main_file> <update_file> [output_file]")
        sys.exit(1)
    
    main_csv = sys.argv[1]
    update_csv = sys.argv[2]
    output_csv = sys.argv[3] if len(sys.argv) > 3 else main_csv
    

