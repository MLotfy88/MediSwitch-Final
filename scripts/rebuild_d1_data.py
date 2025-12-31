import csv
import json
import os
import glob

# Output dir - dynamic for CI/Local compatibility
OUTPUT_DIR = os.getcwd()

def escape_sql(val):
    """Escape SQL values properly"""
    if val is None or val == '':
        return "NULL"
    if isinstance(val, (int, float)):
        return str(val)
    if isinstance(val, bool):
        return "1" if val else "0"
    val = str(val).replace("'", "''")
    return f"'{val}'"

def write_chunked_sql(base_name, header, rows, chunk_size=1000):
    """Write SQL rows to chunked files"""
    chunk_index = 0
    for i in range(0, len(rows), chunk_size):
        chunk = rows[i:i + chunk_size]
        filename = f"{base_name}_part_{chunk_index:03d}.sql"
        filepath = os.path.join(OUTPUT_DIR, filename)
        with open(filepath, 'w', encoding='utf-8') as f:
            for row in chunk:
                f.write(f"{header} {row};\n")
        print(f"Created {filename} with {len(chunk)} rows")
        chunk_index += 1

def process_drugs():
    """
    Process drugs table with FULL 27-column schema matching schema.sql
    Uses DictReader for robust name-based mapping
    """
    print("Processing Drugs from meds.csv...")
    csv_path = "assets/meds.csv"
    if not os.path.exists(csv_path):
        print(f"File not found: {csv_path}")
        return
    
    sql_rows = []
    # Full 27-column schema from schema.sql
    header = """INSERT OR IGNORE INTO drugs (
        id, trade_name, arabic_name, price, old_price, category,
        active, company, dosage_form, dosage_form_ar, concentration, unit, usage,
        pharmacology, barcode, qr_code, visits, last_price_update,
        has_drug_interaction, has_food_interaction, has_disease_interaction
    ) VALUES"""
    
    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            try:
                # Extract and cast values using column names
                drug_id = int(row.get('id', 0))
                if drug_id == 0:
                    continue  # Skip invalid IDs
                
                # Build values list matching exact schema order
                vals = [
                    drug_id,                                    # id
                    row.get('trade_name', ''),                 # trade_name
                    row.get('arabic_name', ''),                # arabic_name
                    row.get('price', ''),                      # price
                    row.get('old_price', ''),                  # old_price
                    row.get('category', ''),                   # category
                    row.get('active', ''),                     # active
                    row.get('company', ''),                    # company
                    row.get('dosage_form', ''),                # dosage_form
                    row.get('dosage_form_ar', ''),             # dosage_form_ar
                    row.get('concentration', ''),              # concentration
                    row.get('units', ''),                      # unit (note: CSV has 'units')
                    row.get('usage', ''),                      # usage
                    row.get('pharmacology', ''),               # pharmacology
                    row.get('barcode', ''),                    # barcode
                    row.get('qr_code', ''),                    # qr_code
                    int(row.get('visits', 0)) if row.get('visits', '').isdigit() else 0,  # visits
                    row.get('last_price_update', ''),          # last_price_update
                    0,                                          # has_drug_interaction
                    0,                                          # has_food_interaction
                    0                                           # has_disease_interaction
                ]
                
                sql_rows.append(f"({', '.join(map(escape_sql, vals))})")
            except Exception as e:
                print(f"Skipping row {row.get('id', 'unknown')}: {e}")
                continue
    
    print(f"Processed {len(sql_rows)} drug records")
    write_chunked_sql("d1_import", header, sql_rows, 1000)

def process_drug_interactions():
    """
    Process drug interactions with FULL 15-column schema matching schema.sql
    """
    print("Processing Enriched (DDInter 2.0) Drug Interactions...")
    files = sorted(glob.glob("assets/data/interactions/enriched/enriched_rules_part_*.json"))
    sql_rows = []
    
    # Full 15-column schema (excluding id which is auto-increment)
    header = """INSERT OR IGNORE INTO drug_interactions (
        ingredient1, ingredient2, severity, effect, arabic_effect, recommendation, arabic_recommendation,
        management_text, mechanism_text, risk_level, ddinter_id, source, type, updated_at
    ) VALUES"""
    
    for fpath in files:
        with open(fpath, 'r', encoding='utf-8') as f:
            content = json.load(f)
            data = content.get('data', [])
            for item in data:
                vals = [
                    item.get('ingredient1', '').lower().strip(),      # ingredient1
                    item.get('ingredient2', '').lower().strip(),      # ingredient2
                    item.get('severity', 'unknown'),                   # severity
                    item.get('effect') or item.get('description', ''), # effect
                    '',                                                 # arabic_effect (not in data)
                    item.get('recommendation', ''),                    # recommendation
                    '',                                                 # arabic_recommendation (not in data)
                    item.get('management_text', ''),                   # management_text
                    item.get('mechanism_text', ''),                    # mechanism_text
                    item.get('risk_level', ''),                        # risk_level
                    item.get('ddinter_id', ''),                        # ddinter_id
                    item.get('source', 'DDInter'),                     # source
                    '',                                                 # type (not in data)
                    0                                                   # updated_at
                ]
                sql_rows.append(f"({', '.join(map(escape_sql, vals))})")
    
    print(f"Processed {len(sql_rows)} drug interaction records")
    write_chunked_sql("d1_rules", header, sql_rows, 800)

def process_food_interactions():
    """Process food interactions matching schema.sql"""
    print("Processing Enriched Food Interactions...")
    path = "assets/data/interactions/enriched/enriched_food_interactions.json"
    if not os.path.exists(path):
        print(f"File not found: {path}")
        return
    
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Schema: id (auto), med_id, trade_name, interaction, source
    header = "INSERT OR IGNORE INTO food_interactions (med_id, trade_name, interaction, source) VALUES"
    sql_rows = []
    
    for item in data:
        vals = [
            item.get('med_id'),
            item.get('trade_name'),
            item.get('interaction'),
            item.get('source', 'DrugBank')
        ]
        sql_rows.append(f"({', '.join(map(escape_sql, vals))})")
    
    print(f"Processed {len(sql_rows)} food interaction records")
    write_chunked_sql("d1_food", header, sql_rows, 1000)

def process_disease_interactions():
    """Process disease interactions matching schema.sql"""
    print("Processing Enriched Disease Interactions...")
    path = "assets/data/interactions/enriched/enriched_disease_interactions.json"
    if not os.path.exists(path):
        print(f"File not found: {path}")
        return
    
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Schema: id (auto), med_id, trade_name, disease_name, interaction_text, source
    header = "INSERT OR IGNORE INTO disease_interactions (med_id, trade_name, disease_name, interaction_text, source) VALUES"
    sql_rows = []
    
    for item in data:
        vals = [
            item.get('med_id'),
            item.get('trade_name'),
            item.get('disease_name'),
            item.get('interaction_text'),
            item.get('source', 'DDInter')
        ]
        sql_rows.append(f"({', '.join(map(escape_sql, vals))})")
    
    print(f"Processed {len(sql_rows)} disease interaction records")
    write_chunked_sql("d1_disease", header, sql_rows, 1000)

def process_dosages():
    """Process dosage guidelines matching schema.sql with full 11-column structure"""
    print("Processing Dosage Guidelines...")
    path = "assets/data/dosage_guidelines.json"
    if not os.path.exists(path):
        print(f"File not found: {path}")
        return
    
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
        # Handle { "dosage_guidelines": [...] }
        if isinstance(data, dict) and "dosage_guidelines" in data:
            data = data["dosage_guidelines"]
    
    # Full schema from schema.sql (excluding id and created_at which have defaults)
    header = """INSERT OR IGNORE INTO dosage_guidelines (
        med_id, dailymed_setid, min_dose, max_dose, frequency, duration,
        instructions, condition, source, is_pediatric, active_ingredient
    ) VALUES"""
    
    sql_rows = []
    for item in data:
        if not isinstance(item, dict):
            continue
        
        vals = [
            item.get('med_id'),                                    # med_id
            None,                                                   # dailymed_setid (not in data)
            None,                                                   # min_dose (not in data)
            None,                                                   # max_dose (not in data)
            None,                                                   # frequency (not in data)
            None,                                                   # duration (not in data)
            item.get('instructions') or item.get('dosage_text', ''), # instructions
            item.get('condition', ''),                             # condition
            item.get('source', 'DailyMed'),                        # source
            1 if item.get('is_pediatric') else 0,                  # is_pediatric
            item.get('active_ingredient', '')                      # active_ingredient
        ]
        sql_rows.append(f"({', '.join(map(escape_sql, vals))})")
    
    print(f"Processed {len(sql_rows)} dosage guideline records")
    write_chunked_sql("d1_dosages", header, sql_rows, 1000)

if __name__ == "__main__":
    print("=" * 60)
    print("D1 Data Export - Full Schema Alignment")
    print("=" * 60)
    process_drugs()
    process_drug_interactions()
    process_food_interactions()
    process_disease_interactions()
    process_dosages()
    print("=" * 60)
    print("All tasks completed successfully!")
    print("=" * 60)
