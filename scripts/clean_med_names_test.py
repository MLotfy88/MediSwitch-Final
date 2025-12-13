import pandas as pd
import re
import os

MEDS_CSV = '/home/adminlotfy/project/assets/meds.csv'

def clean_drug_name(raw_name):
    if not isinstance(raw_name, str):
        return ""
    
    name = raw_name.lower().strip()
    
    # 1. Remove Concentration Patterns (e.g., 500mg, 1%, 20 mcg/ml)
    # This regex looks for number + optional space + unit, ensuring we don't catch part of a word.
    # We replace with a space to avoid merging words.
    name = re.sub(r'\b\d+(\.\d+)?\s*(mg|ml|gm|g|mcg|iu|%)\b', ' ', name)
    name = re.sub(r'\b\d+(\.\d+)?\s*(?:mg|ml|gm|g|mcg|iu|%)\s*/\s*(?:mg|ml|gm|g|mcg|iu|%)\b', ' ', name) # Compounds like mg/ml

    # 2. Remove Common Dosage Forms & Container Types
    forms = [
        'tablet', 'tabs', 'tab', 'capsule', 'caps', 'cap', 'syrup', 'suspension', 'susp', 
        'cream', 'ointment', 'oint', 'gel', 'lotion', 'spray', 'drops', 'solution', 'sol', 
        'injection', 'inj', 'vial', 'ampoule', 'amp', 'suppository', 'supp', 'sachet', 
        'effervescent', 'chewable', 'scored', 'coated', 'f.c.', 's.r.', 'x.r.', 'e.c.',
        'topical', 'top.', 'oral', 'nasal', 'vaginal', 'rectal', 'eye', 'ear', 'mouth', 'wash'
    ]
    
    # Create a regex to match these words as whole words
    form_pattern = r'\b(' + '|'.join([re.escape(f) for f in forms]) + r')\b'
    name = re.sub(form_pattern, ' ', name)
    
    # 3. Remove Numbers that stand alone (often pack sizes like 20, 30, 100)
    # Be careful not to remove numbers that are part of the brand name (e.g. "Omega 3")
    # Heuristic: Remove numbers if they are at the end of the string or > 10 (likely count)
    # For now, let's remove isolated numbers > 5 
    # (assuming brand names relying on small numbers like "Omega 3" or "Baby 1" exist)
    
    # name = re.sub(r'\b\d+\b', ' ', name) # Too aggressive?
    
    # 4. Cleanup Whitespace and Symbols
    name = re.sub(r'[^\w\s]', ' ', name) # Remove punctuation like -, +, .
    name = re.sub(r'\s+', ' ', name).strip()
    
    return name

def main():
    if not os.path.exists(MEDS_CSV):
        print("CSV file not found.")
        return

    df = pd.read_csv(MEDS_CSV)
    
    print(f"{'Original Name':<50} | {'Cleaned Name':<30}")
    print("-" * 85)
    
    sample_df = df.sample(50) # Check 50 random names
    
    for _, row in sample_df.iterrows():
        original = str(row['trade_name'])
        cleaned = clean_drug_name(original)
        print(f"{original[:48]:<50} | {cleaned:<30}")

if __name__ == "__main__":
    main()
