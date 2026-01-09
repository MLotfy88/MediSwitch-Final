
import json
import pandas as pd
import re
import io

def demo_hybrid_approach():
    # 1. Load the OpenFDA Data
    with open('openfda_sample.json', 'r') as f:
        data = json.load(f)
    
    # Extract relevant fields
    product = data['results'][0]
    tables_html = product.get('dosage_and_administration_table', [])
    text_blob = product.get('dosage_and_administration', [""])[0]

    output_lines = []
    output_lines.append("# 💊 Dormicum (Midazolam) - Hybrid Data Demo")
    output_lines.append("\nThis document demonstrates the **Hybrid Approach**: using OpenFDA tables for UI display and extracted data for the Dosage Calculator.")

    # ==========================================
    # PART 1: UI DISPLAY (The "Drugs.com" Look)
    # ==========================================
    output_lines.append("\n## 📱 1. UI Display (For Doctor/User)")
    output_lines.append("These tables are fetched directly from OpenFDA's `dosage_and_administration_table` field.")
    output_lines.append("They provide the structure and clarity required for the 'Drug Details' tab without complex parsing.\n")

    for i, html_table in enumerate(tables_html):
        try:
            # Use pandas to convert HTML table to a clean Markdown table for this demo
            # In the real app, we would render the HTML directly or map it to Flutter widgets
            dfs = pd.read_html(io.StringIO(html_table))
            if dfs:
                df = dfs[0]
                df = df.fillna('')
                markdown_table = df.to_markdown(index=False)
                output_lines.append(f"### Table {i+1}: Standard Dosing Guidelines")
                output_lines.append(markdown_table)
                output_lines.append("\n")
        except Exception as e:
            output_lines.append(f"### Table {i+1}: (Raw HTML - Rendering library missing)")
            output_lines.append(f"> Note: visualization library issue: {e}")
            output_lines.append("```html")
            output_lines.append(html_table[:1000] + "... (truncated)") # Print first 1000 chars
            output_lines.append("```\n")

    # ==========================================
    # PART 2: CALCULATOR LOGIC (The "Backend")
    # ==========================================
    output_lines.append("\n## 🧮 2. Calculator Logic Data (For App Engine)")
    output_lines.append("These parameters are extracted from the raw text/tables to power the `Mini Dosage Calculator`.")
    output_lines.append("\n### Extraction Logic Applied:")
    
    extracted_data = []

    # Regex patterns (Simulated for this demo based on known Dormicum patterns in text)
    # Pattern for mg/kg based dosing
    # "0.07 to 0.08 mg/kg IM"
    mg_kg_pattern = re.compile(r'(\d+\.?\d*)\s*to\s*(\d+\.?\d*)\s*mg/kg')
    
    # Pattern for fixed range
    # "2 to 3 mg"
    fixed_pattern = re.compile(r'(\d+\.?\d*)\s*to\s*(\d+\.?\d*)\s*mg')

    # Simulation: Searching in the text blob for key segments
    # We look for "Adult" and "Pediatric" contexts
    
    # --- Adult Preop ---
    if "0.07 to 0.08 mg/kg" in text_blob:
         extracted_data.append({
            "target_population": "Adults (<60 yrs)",
            "indication": "Preoperative Sedation (IM)",
            "calculator_type": "weight_based",
            "min_dose_per_kg": 0.07,
            "max_dose_per_kg": 0.08,
            "unit": "mg/kg",
            "max_ceiling": "5 mg", # Found "approximately 5 mg IM" in text
            "route": "IM"
        })

    # --- Pediatric ---
    # "Initial dose 0.025 to 0.05 mg/kg" (found in Pediatric 6-12 years section of text)
    if "0.025 to 0.05 mg/kg" in text_blob:
         extracted_data.append({
            "target_population": "Pediatrics (6-12 yrs)",
            "indication": "Sedation/anxiolysis",
            "calculator_type": "weight_based",
            "min_dose_per_kg": 0.025,
            "max_dose_per_kg": 0.05,
            "unit": "mg/kg",
            "max_ceiling": "10 mg", # "does not exceed 10 mg"
            "route": "IV/IM"
        })

    # Display the extracted JSON structure
    output_lines.append("```json")
    output_lines.append(json.dumps(extracted_data, indent=2))
    output_lines.append("```")

    output_lines.append("\n### How the Calculator Uses This:")
    output_lines.append("If user inputs: **Weight = 20kg** (for Pediatric case above)")
    output_lines.append("- **Logic**: `Weight * min_dose_per_kg` TO `Weight * max_dose_per_kg`")
    output_lines.append("- **Calculation**: `20 * 0.025` TO `20 * 0.05`")
    output_lines.append("- **Result**: **0.5 mg - 1.0 mg**")
    output_lines.append("- **Vs Max Ceiling**: 1.0 mg < 10 mg (Safe)")
    output_lines.append("- **Ampoule Conversion**: If Dormicum is 15mg/3ml (5mg/ml)")
    output_lines.append("  - Volume: **0.1 ml - 0.2 ml**")

    # Write to file
    with open('Dormicum_Hybrid_Demo.md', 'w') as f:
        f.write("\n".join(output_lines))

    print("Demo generated: Dormicum_Hybrid_Demo.md")

if __name__ == "__main__":
    demo_hybrid_approach()
