import pandas as pd
import re
import numpy as np

# Define file path
csv_file_path = 'druglist-21-04-2025.csv'
output_csv_path = 'druglist-21-04-2025_updated_concentration.csv' # Save to a new file to avoid overwriting

# --- Configuration: Adjust these column names if they are different in your file ---
csv_drug_name_col = 'trade_name'      # Column containing the full drug name
csv_concentration_col = 'concentration' # Target column to store the extracted concentration
# --- End Configuration ---

# Regular expression to find concentration patterns
# This pattern looks for numbers (int/float) followed by common units (mg, g, ml, %, iu, mcg, etc.)
# It handles optional spaces and units like mg/ml.
# Adjust this regex if your concentration formats are different.
concentration_regex = re.compile(
    r"""
    (                          # Start capturing group 1
        \d+ (?:[.,]\d+)?       # Match number (integer or decimal with . or ,)
        \s*                    # Optional whitespace
        (?:mg|mcg|g|kg|ml|l|iu|%) # Match common units (case-insensitive)
        (?:                    # Optional second part for compound units (e.g., /ml)
            \s* / \s*          # Match '/' surrounded by optional spaces
            (?:ml|mg|g|kg|l)   # Match second unit (case-insensitive)
        )?
    )                          # End capturing group 1
    """,
    re.IGNORECASE | re.VERBOSE # Ignore case and allow verbose regex formatting
)

def extract_concentration(name):
    """
    Applies the regex to extract the first matching concentration string from a name.
    """
    if not isinstance(name, str):
        return None # Handle non-string inputs
    match = concentration_regex.search(name)
    if match:
        # Return the first captured group (the full concentration string)
        return match.group(1).strip()
    return None # Return None if no match is found

try:
    # Read the CSV file
    print(f"Reading CSV file: {csv_file_path}...")
    # Try reading with common encodings if default fails
    try:
        df = pd.read_csv(csv_file_path)
    except UnicodeDecodeError:
        try:
            print("Default encoding failed, trying 'latin1'...")
            df = pd.read_csv(csv_file_path, encoding='latin1')
        except UnicodeDecodeError:
            print("'latin1' encoding failed, trying 'iso-8859-1'...")
            df = pd.read_csv(csv_file_path, encoding='iso-8859-1')
        except Exception as e:
            print(f"Could not read CSV with multiple encodings. Error: {e}")
            raise
    print(f"Successfully read {len(df)} rows from CSV.")

    # Check if required columns exist
    if csv_drug_name_col not in df.columns:
        raise ValueError(f"Column '{csv_drug_name_col}' not found in {csv_file_path}. Please check the 'csv_drug_name_col' variable.")

    # Ensure the target concentration column exists, create if not
    if csv_concentration_col not in df.columns:
        print(f"Creating column '{csv_concentration_col}' as it does not exist.")
        df[csv_concentration_col] = np.nan
    # Ensure the target column is of object/string type
    df[csv_concentration_col] = df[csv_concentration_col].astype(object)


    # Apply the extraction function to the drug name column
    print(f"Extracting concentrations from '{csv_drug_name_col}' column...")
    # Use .fillna('') to handle potential NaN values in the name column before applying the function
    extracted_concentrations = df[csv_drug_name_col].fillna('').apply(extract_concentration)

    # Update the concentration column only where a concentration was successfully extracted
    # This avoids overwriting existing values if no concentration is found in the name
    update_mask = extracted_concentrations.notna()
    df.loc[update_mask, csv_concentration_col] = extracted_concentrations[update_mask]

    num_updated = update_mask.sum()
    num_not_found = len(df) - num_updated
    print(f"Finished processing. Extracted and updated concentration for {num_updated} rows.")
    if num_not_found > 0:
        print(f"Could not extract concentration from the name for {num_not_found} rows.")

    # Save the updated DataFrame to a NEW CSV file
    print(f"Saving updated data to {output_csv_path}...")
    try:
        df.to_csv(output_csv_path, index=False, encoding='utf-8')
        print(f"Successfully saved updated data to {output_csv_path}.")
    except PermissionError:
        print(f"\nError: Permission denied when trying to save '{output_csv_path}'.")
        print("Please ensure you have write permissions to the directory.")
    except Exception as e:
        print(f"An error occurred while saving the file: {e}")


except FileNotFoundError:
    print(f"Error: File not found. Please ensure '{csv_file_path}' exists.")
except ValueError as e:
    print(f"Error: Column name mismatch or data issue.\n{e}")
except Exception as e:
    print(f"An unexpected error occurred: {e}")