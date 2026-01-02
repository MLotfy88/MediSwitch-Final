import csv
import json
import os
import re

# --- Configuration ---
CHUNK_DIR = "d1_sql_chunks"
BATCH_SIZE = 1000

# File Paths
MEDS_CSV = "assets/meds.csv"
DOSAGES_JSON = "assets/data/dosage_guidelines.json"
FOOD_JSON = "assets/data/interactions/enriched/enriched_food_interactions.json"
RULES_DIR = "assets/data/interactions/enriched"

def clean_sql_val(val):
    if val is None or val == "": return "NULL"
    if isinstance(val, (int, float)): return str(val)
    # Escape single quotes
    safe_v = str(val).replace("'", "''")
    return f"'{safe_v}'"

def write_chunk(table_name, alias, data_list, cols):
    if not data_list: return
    
    os.makedirs(CHUNK_DIR, exist_ok=True)
    
    for i in range(0, len(data_list), BATCH_SIZE):
        chunk_idx = i // BATCH_SIZE
        batch = data_list[i:i + BATCH_SIZE]
        
        sql_lines = []
        for row in batch:
            vals = [clean_sql_val(row.get(col)) for col in cols]
            sql_lines.append(f"INSERT OR REPLACE INTO {table_name} ({', '.join(cols)}) VALUES ({', '.join(vals)});")
        
        fname = f"{alias}_part_{chunk_idx:03d}.sql"
        with open(os.path.join(CHUNK_DIR, fname), "w", encoding="utf-8") as f:
            f.write("\n".join(sql_lines))

def parse_ingredients(active):
    if not active: return []
    return [ing.strip().lower() for ing in re.split(r'[+;,/]', active) if ing.strip()]

def process_drugs():
    print("💊 Processing Drugs & Ingredients...")
    drugs = []
    ingredients = []
    
    if os.path.exists(MEDS_CSV):
        with open(MEDS_CSV, mode='r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                # Map CSV to D1 table columns
                drug_id = int(row['id'])
                drugs.append(row)
                
                # Mapping Ingredients
                active = row.get('active', '')
                ings = parse_ingredients(active)
                for ing in ings:
                    ingredients.append({"med_id": drug_id, "ingredient": ing})

    drug_cols = ['id', 'trade_name', 'arabic_name', 'price', 'old_price', 'category', 'active', 'company', 
                 'dosage_form', 'dosage_form_ar', 'concentration', 'unit', 'usage', 'pharmacology', 
                 'barcode', 'qr_code', 'visits', 'last_price_update', 'updated_at', 'indication', 
                 'mechanism_of_action', 'pharmacodynamics', 'data_source_pharmacology', 
                 'has_drug_interaction', 'has_food_interaction', 'has_disease_interaction', 
                 'description', 'atc_codes', 'external_links']
    
    # Filter only keys that exist in CSV
    drug_data = []
    for d in drugs:
        d_mapped = {k: d.get(k) for k in drug_cols if k in d}
        drug_data.append(d_mapped)
    
    write_chunk("drugs", "d1_import", drug_data, drug_cols)
    write_chunk("med_ingredients", "d1_ingredients", ingredients, ["med_id", "ingredient"])

def process_dosages():
    print("🧪 Processing Dosages...")
    if os.path.exists(DOSAGES_JSON):
        with open(DOSAGES_JSON, "r", encoding="utf-8") as f:
            data = json.load(f)
            # Handle both list and {"dosage_guidelines": [...]}
            dosages = data if isinstance(data, list) else data.get("dosage_guidelines", [])
            cols = ["med_id", "dailymed_setid", "min_dose", "max_dose", "frequency", "duration", "instructions", "condition", "source", "is_pediatric"]
            write_chunk("dosage_guidelines", "d1_dosages", dosages, cols)

def process_food():
    print("🍎 Processing Food Interactions...")
    if os.path.exists(FOOD_JSON):
        with open(FOOD_JSON, "r", encoding="utf-8") as f:
            data = json.load(f)
            cols = ["med_id", "trade_name", "interaction", "ingredient", "severity", "management_text", "mechanism_text", "reference_text", "source"]
            write_chunk("food_interactions", "d1_food", data, cols)

def process_rules():
    print("🧪 Processing Drug Rules...")
    all_rules = []
    for fname in sorted(os.listdir(RULES_DIR)):
        if fname.startswith("enriched_rules_part_") and fname.endswith(".json"):
            with open(os.path.join(RULES_DIR, fname), "r", encoding="utf-8") as f:
                content = json.load(f)
                rules = (content.get('data') if isinstance(content, dict) else []) or []
                all_rules.extend(rules)
    
    cols = ["ingredient1", "ingredient2", "severity", "effect", "arabic_effect", "recommendation", 
            "arabic_recommendation", "management_text", "mechanism_text", "alternatives_a", 
            "alternatives_b", "risk_level", "ddinter_id", "source", "type", "updated_at"]
    
    write_chunk("drug_interactions", "d1_rules", all_rules, cols)

def main():
    print("🚀 Starting SQL Data Generation...")
    process_drugs()
    process_dosages()
    process_food()
    process_rules()
    print("✅ All SQL Chunks Generated in d1_sql_chunks/")

if __name__ == "__main__":
    main()
