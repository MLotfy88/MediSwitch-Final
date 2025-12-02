import pandas as pd
from datetime import datetime

# --- Configuration ---
DRUGLIST_FILE = 'druglist-18-04-2025.csv'
FORMATTED_PRICES_FILE = 'cleaned_newprices.xlsx' # Use the cleaned file
OUTPUT_FILE = 'druglist-18-04-2025_updated.csv' # Changed output to CSV

# Columns in druglist file
DRUGLIST_NAME_COL = 'trade_name'
DRUGLIST_PRICE_COL = 'price'
DRUGLIST_OLD_PRICE_COL = 'old_price'
DRUGLIST_UPDATE_DATE_COL = 'last_price_update'

# Columns in the cleaned prices file (cleaned_newprices.xlsx)
FORMATTED_NAME_COL = 'Cleaned Drug Name' # Column with cleaned English names
FORMATTED_NEW_PRICE_COL = 'السعر الجديد'   # Column with the new price
FORMATTED_OLD_PRICE_COL = 'السعر القديم'   # Column with the old price
FORMATTED_DATE_COL = 'Formatted Date'     # Column with the formatted update date
# --- End Configuration ---

def update_prices():
    """
    Updates drug prices in the main drug list based on the formatted prices file.
    """
    try:
        # Read the CSV and Excel files
        print(f"Reading drug list from: {DRUGLIST_FILE}")
        druglist_df = pd.read_csv(DRUGLIST_FILE) # Use read_csv for the .csv file
        print(f"Reading formatted prices from: {FORMATTED_PRICES_FILE}")
        # Specify engine for reading xlsx, requires 'openpyxl' installed (pip install openpyxl)
        cleaned_prices_df = pd.read_excel(FORMATTED_PRICES_FILE, engine='openpyxl')

        print(f"Read {len(druglist_df)} rows from {DRUGLIST_FILE}")
        print(f"Read {len(cleaned_prices_df)} rows from {FORMATTED_PRICES_FILE}")

        # Ensure necessary columns exist in druglist_df
        if DRUGLIST_OLD_PRICE_COL not in druglist_df.columns:
             druglist_df[DRUGLIST_OLD_PRICE_COL] = pd.NA # Use pd.NA for consistency
             print(f"Created '{DRUGLIST_OLD_PRICE_COL}' column in druglist DataFrame.")

        if DRUGLIST_UPDATE_DATE_COL not in druglist_df.columns:
            druglist_df[DRUGLIST_UPDATE_DATE_COL] = pd.NaT # Use pd.NaT for dates
            print(f"Created '{DRUGLIST_UPDATE_DATE_COL}' column in druglist DataFrame.")

        # --- Data Type Conversions ---
        # Druglist: Convert price columns to numeric, coercing errors
        druglist_df[DRUGLIST_PRICE_COL] = pd.to_numeric(druglist_df[DRUGLIST_PRICE_COL], errors='coerce')
        druglist_df[DRUGLIST_OLD_PRICE_COL] = pd.to_numeric(druglist_df[DRUGLIST_OLD_PRICE_COL], errors='coerce')
        # Druglist: Convert date column to datetime, coercing errors
        druglist_df[DRUGLIST_UPDATE_DATE_COL] = pd.to_datetime(druglist_df[DRUGLIST_UPDATE_DATE_COL], errors='coerce')

        # Cleaned Prices: Convert price columns to numeric, coercing errors
        cleaned_prices_df[FORMATTED_NEW_PRICE_COL] = pd.to_numeric(cleaned_prices_df[FORMATTED_NEW_PRICE_COL], errors='coerce')
        cleaned_prices_df[FORMATTED_OLD_PRICE_COL] = pd.to_numeric(cleaned_prices_df[FORMATTED_OLD_PRICE_COL], errors='coerce')
        # Cleaned Prices: Convert date column to datetime (it should be dd/mm/yyyy string format from previous script)
        # Specify dayfirst=True because the format is dd/mm/yyyy
        cleaned_prices_df[FORMATTED_DATE_COL] = pd.to_datetime(cleaned_prices_df[FORMATTED_DATE_COL], errors='coerce', dayfirst=True)
        # Cleaned Prices: Ensure name column is string
        cleaned_prices_df[FORMATTED_NAME_COL] = cleaned_prices_df[FORMATTED_NAME_COL].astype(str)

        # --- Update Logic ---
        update_count = 0
        not_found_count = 0
        drugs_not_found = []

        # Iterate through the cleaned prices data
        for index, row in cleaned_prices_df.iterrows():
            cleaned_drug_name = row[FORMATTED_NAME_COL]
            new_price = row[FORMATTED_NEW_PRICE_COL]
            old_price = row[FORMATTED_OLD_PRICE_COL]
            update_date = row[FORMATTED_DATE_COL] # This is now a datetime object or NaT

            # Basic validation for the row from cleaned_prices_df
            if pd.isna(cleaned_drug_name) or cleaned_drug_name.strip() == '':
                print(f"Skipping row {index+2} in {FORMATTED_PRICES_FILE} due to missing cleaned drug name.")
                continue
            if pd.isna(new_price):
                 print(f"Skipping row {index+2} ('{cleaned_drug_name}') in {FORMATTED_PRICES_FILE} due to missing new price.")
                 continue
            # Old price and date can be missing, we'll handle that during update

            # Find the matching drug in the main list using DRUGLIST_NAME_COL ('trade_name')
            # Match against the cleaned_drug_name from the prices file
            # Ensure druglist name column is also treated as string for comparison
            match_mask = druglist_df[DRUGLIST_NAME_COL].astype(str).str.strip().str.lower() == cleaned_drug_name.strip().lower()
            match_indices = druglist_df.index[match_mask].tolist()

            if match_indices:
                for idx in match_indices:
                    # Update directly using values from cleaned_prices_df
                    druglist_df.loc[idx, DRUGLIST_OLD_PRICE_COL] = old_price if not pd.isna(old_price) else druglist_df.loc[idx, DRUGLIST_OLD_PRICE_COL] # Keep existing if NaN
                    druglist_df.loc[idx, DRUGLIST_PRICE_COL] = new_price # Already checked new_price is not NaN
                    druglist_df.loc[idx, DRUGLIST_UPDATE_DATE_COL] = update_date if not pd.isna(update_date) else druglist_df.loc[idx, DRUGLIST_UPDATE_DATE_COL] # Keep existing if NaT

                    update_count += 1
                    # Optional: print(f"Updated '{cleaned_drug_name}' (Index: {idx}): Old Price={old_price}, New Price={new_price}, Date={update_date.strftime('%d/%m/%Y') if not pd.isna(update_date) else 'N/A'}")
            else:
                not_found_count += 1
                drugs_not_found.append(cleaned_drug_name)
                # print(f"Warning: Drug '{drug_name}' from {FORMATTED_PRICES_FILE} not found in {DRUGLIST_FILE}.") # Optional: verbose logging

        print(f"\nUpdate Summary:")
        print(f" - Successfully updated {update_count} records.")
        print(f" - Could not find {not_found_count} drugs from '{FORMATTED_PRICES_FILE}' in '{DRUGLIST_FILE}'.")
        if drugs_not_found:
            print("   - Drugs not found:", ', '.join(map(str, drugs_not_found[:10])) + ('...' if len(drugs_not_found) > 10 else '')) # Show first 10

        # Save the updated DataFrame to a new Excel file
        # Convert date column back to string format 'dd/mm/yyyy' for saving, handling NaT
        druglist_df[DRUGLIST_UPDATE_DATE_COL] = druglist_df[DRUGLIST_UPDATE_DATE_COL].dt.strftime('%d/%m/%Y').fillna('')

        # Save the updated DataFrame to a new CSV file
        druglist_df.to_csv(OUTPUT_FILE, index=False, encoding='utf-8-sig') # Use to_csv and specify encoding
        print(f"\nUpdated drug list saved to '{OUTPUT_FILE}'")

    except FileNotFoundError as e:
        print(f"Error: File not found - {e}. Please ensure both Excel files exist in the correct path ({DRUGLIST_FILE}, {FORMATTED_PRICES_FILE}).")
    except KeyError as e:
        print(f"Error: Column not found - {e}. Please verify the column names in the configuration section.")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")

if __name__ == "__main__":
    update_prices()