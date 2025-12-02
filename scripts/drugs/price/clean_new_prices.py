import pandas as pd
import re

def clean_drug_name(name):
    """
    Extracts the English drug name by removing content starting from the first parenthesis.
    Handles potential None or non-string values.
    """
    if not isinstance(name, str):
        return name # Return original value if not a string
    
    # Find the first opening parenthesis
    match = re.search(r'\(', name)
    if match:
        # Return the part before the first parenthesis, stripping whitespace
        return name[:match.start()].strip()
    else:
        # If no parenthesis found, return the original name stripped
        return name.strip()

def format_date(date_obj):
    """
    Formats the date object to dd/mm/yyyy string format.
    Handles potential NaT (Not a Time) values.
    """
    if pd.isna(date_obj):
        return None # Return None or an empty string for invalid dates
    try:
        # Ensure the input is treated as a datetime object before formatting
        return pd.to_datetime(date_obj).strftime('%d/%m/%Y')
    except Exception as e:
        print(f"Error formatting date {date_obj}: {e}")
        return None # Return None or original value if formatting fails

# --- Main Script ---
input_excel_file = 'newprices.xlsx'
output_excel_file = 'cleaned_newprices.xlsx'
output_csv_file = 'cleaned_newprices.csv' # Optional CSV output

# Define column names based on the example (adjust if they are different in the actual file)
drug_col_ar = 'الدواء'
new_price_col_ar = 'السعر الجديد'
old_price_col_ar = 'السعر القديم'
date_col_ar = 'تاريخ زيادة السعر'

try:
    # Read the Excel file
    # Explicitly set dtype to string for the drug column to avoid potential type inference issues
    df = pd.read_excel(input_excel_file, dtype={drug_col_ar: str})
    print(f"Successfully read {input_excel_file}")
    print("Original Columns:", df.columns.tolist())
    print("Original Data Sample:\n", df.head())


    # --- 1. Clean Drug Name ---
    if drug_col_ar in df.columns:
        print(f"\nCleaning '{drug_col_ar}' column...")
        # Create a new column for the cleaned name
        df['Cleaned Drug Name'] = df[drug_col_ar].apply(clean_drug_name)
        print("Sample Cleaned Drug Names:\n", df[['Cleaned Drug Name', drug_col_ar]].head())
    else:
        print(f"Warning: Column '{drug_col_ar}' not found in the Excel file.")


    # --- 2. Format Date ---
    if date_col_ar in df.columns:
        print(f"\nFormatting '{date_col_ar}' column...")
        # Convert the date column to datetime objects, coercing errors
        df[date_col_ar] = pd.to_datetime(df[date_col_ar], errors='coerce')
        # Apply the formatting function
        df['Formatted Date'] = df[date_col_ar].apply(format_date)
        print("Sample Formatted Dates:\n", df[['Formatted Date', date_col_ar]].head())
    else:
        print(f"Warning: Column '{date_col_ar}' not found in the Excel file.")

    # --- Select and Reorder Columns for Output ---
    # Define the columns you want in the final output
    output_columns = ['Cleaned Drug Name', new_price_col_ar, old_price_col_ar, 'Formatted Date']
    # Filter out columns that might not exist if warnings were printed
    output_columns = [col for col in output_columns if col in df.columns or col in ['Cleaned Drug Name', 'Formatted Date']]

    if 'Cleaned Drug Name' in df.columns: # Only include original if cleaning happened
         output_columns.append(drug_col_ar)
    if 'Formatted Date' in df.columns: # Only include original if formatting happened
         output_columns.append(date_col_ar)

    # Create the final DataFrame with selected columns
    df_output = df[output_columns]


    # --- Save Processed Data ---
    print(f"\nSaving cleaned data to {output_excel_file}...")
    df_output.to_excel(output_excel_file, index=False, engine='openpyxl')
    print("Cleaned data saved successfully to Excel.")

    # Optional: Save to CSV
    # print(f"Saving cleaned data to {output_csv_file}...")
    # df_output.to_csv(output_csv_file, index=False, encoding='utf-8-sig')
    # print("Cleaned data saved successfully to CSV.")

    print("\nScript finished successfully.")

except FileNotFoundError:
    print(f"Error: Input file '{input_excel_file}' not found. Please ensure it's in the correct directory.")
except Exception as e:
    print(f"An error occurred: {e}")