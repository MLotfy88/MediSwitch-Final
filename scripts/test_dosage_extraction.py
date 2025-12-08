import json
import zipfile
import re
import os
import sys

def extract_dosage_info(zip_path, target_file_name_pattern=None):
    """
    Extracts dosage information from a specific JSON file within a ZIP archive.
    """
    if not os.path.exists(zip_path):
        print(f"Error: File not found at {zip_path}")
        return

    try:
        with zipfile.ZipFile(zip_path, 'r') as z:
            # List files to find the target json if name not fully known or just take first
            file_list = z.namelist()
            target_file = None
            
            if target_file_name_pattern:
                for f in file_list:
                    if target_file_name_pattern in f:
                        target_file = f
                        break
            
            if not target_file:
                # Default to the first json file found
                for f in file_list:
                    if f.endswith('.json'):
                        target_file = f
                        break
            
            if not target_file:
                 print("No JSON file found in the ZIP.")
                 return

            print(f"Processing file: {target_file}")
            
            with z.open(target_file) as f:
                data = json.load(f)
                
                # OpenFDA JSONs usually have a 'results' array
                results = data.get('results', [])
                if not results:
                    print("No 'results' found in JSON.")
                    return

                print(f"Found {len(results)} drug records. Analyzing the first 5 pertinent ones...\n")

                for i, drug in enumerate(results[:10]): # Analyze first 10 to find good examples
                    
                    openfda = drug.get('openfda', {})
                    brand_name = openfda.get('brand_name', ['Unknown Asset'])[0] if openfda.get('brand_name') else 'Unknown Brand'
                    generic_name = openfda.get('generic_name', ['Unknown Generic'])[0] if openfda.get('generic_name') else 'Unknown Generic'
                    
                    print(f"--- Drug {i+1}: {brand_name} ({generic_name}) ---")

                    # 1. Strength (spl_product_data_elements)
                    # Often contains "Active Ingredient Name strength Unit"
                    spl_data = drug.get('spl_product_data_elements', [])
                    strength_raw = spl_data[0] if spl_data else "N/A"
                    print(f"Raw Strength Data: {strength_raw}")

                    # 2. Dosage & Administration (dosage_and_administration)
                    dosage_admin = drug.get('dosage_and_administration', ['N/A'])[0]
                    # Clean up: remove newlines / extremely long text for preview
                    dosage_admin_preview = ' '.join(dosage_admin.split()[:50]) + "..."
                    print(f"Dosage (Preview): {dosage_admin_preview}")

                    # 3. Dosage Forms (dosage_forms_and_strengths)
                    forms_strengths = drug.get('dosage_forms_and_strengths', ['N/A'])[0]
                    forms_preview = ' '.join(forms_strengths.split()[:30]) + "..."
                    print(f"Forms & Strengths: {forms_preview}")

                    # 4. Instructions (instructions_for_use or dosage_and_administration)
                    instructions = drug.get('instructions_for_use', ['See Dosage & Administration'])[0]
                    print(f"Instructions (Preview): {' '.join(instructions.split()[:30])}...")
                    
                    # Logic Extraction Attempt
                    extract_logic(dosage_admin, forms_strengths)
                    print("\n")

    except Exception as e:
        print(f"An error occurred: {e}")

def extract_logic(dosage_text, forms_text):
    """
    Attempts to parse standard dose and max dose from text using Enhanced Regex.
    """
    if not dosage_text or dosage_text == 'N/A':
        return

    print("  -> Enhanced Logic Extraction:")

    # --- 1. Max Dose Patterns ---
    # Patterns: "max(imum) X mg", "not more than X mg", "exceed X mg"
    max_patterns = [
        r'max(?:imum)?\s*(?:daily)?\s*(?:dose)?\s*(?:is)?\s*(\d+(?:\.\d+)?)\s*mg',
        r'not\s*more\s*than\s*(\d+(?:\.\d+)?)\s*mg',
        r'do\s*not\s*exceed\s*(\d+(?:\.\d+)?)\s*mg',
        r'up\s*to\s*(\d+(?:\.\d+)?)\s*mg'
    ]
    
    max_dose_found = None
    for pattern in max_patterns:
        match = re.search(pattern, dosage_text, re.IGNORECASE)
        if match:
            max_dose_found = match.group(1)
            print(f"    * [Max Dose] Found: {max_dose_found} mg (Pattern: {pattern})")
            break
            
    if not max_dose_found:
        print("    * [Max Dose] Not found.")

    # --- 2. Standard Dose / Frequency Patterns ---
    # Patterns: "X mg every Y hours", "X mg X times daily", "X to Y tablets"
    
    # A. Specific mg amounts
    mg_dose_pattern = r'(\d+(?:\.\d+)?)\s*mg\s+(?:every|per|daily|once|twice|three)'
    mg_match = re.search(mg_dose_pattern, dosage_text, re.IGNORECASE)
    
    # B. Frequency-based inference (common in OTC) e.g., "apply 3 to 4 times daily"
    freq_pattern = r'(\d+\s*(?:to\s*\d+)?)\s*times\s*daily'
    freq_match = re.search(freq_pattern, dosage_text, re.IGNORECASE)

    if mg_match:
        print(f"    * [Standard Dose] Found Amount: {mg_match.group(1)} mg")
    elif freq_match:
         print(f"    * [Standard Dose] Found Frequency: {freq_match.group(0)}")
    else:
        print("    * [Standard Dose] No explicit dose pattern found.")

    # --- 3. Strength Extraction ---
    # Try to find independent strength in forms_text if available
    if forms_text and forms_text != "N/A":
        # Look for standalone strength like "500 mg" or "500 mg/5mL"
        strength_pattern = r'(\d+(?:\.\d+)?)\s*(mg|mcg|g|%)'
        s_match = re.search(strength_pattern, forms_text, re.IGNORECASE)
        if s_match:
             print(f"    * [Strength] Parsed from Forms: {s_match.group(0)}")


if __name__ == "__main__":
    # Path provided by user
    zip_file_path = "/home/adminlotfy/project/External_source/drug_interaction/drug-label/downloaded/drug-label-0013-of-0013.json.zip"
    extract_dosage_info(zip_file_path)
