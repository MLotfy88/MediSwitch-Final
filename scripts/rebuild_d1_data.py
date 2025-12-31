import csv
import json
import os
import glob

# Output dir - dynamic for CI/Local compatibility
OUTPUT_DIR = os.getcwd()

def escape_sql(val):
    if val is None:
        return "NULL"
    if isinstance(val, (int, float)):
        return str(val)
    if isinstance(val, bool):
        return "1" if val else "0"
    val = str(val).replace("'", "''")
    return f"'{val}'"

def write_chunked_sql(base_name, header, rows, chunk_size=1000):
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
    print("Processing Drugs from meds.csv...")
    csv_path = "assets/meds.csv"
    if not os.path.exists(csv_path):
        print(f"File not found: {csv_path}")
        return
    sql_rows = []
    header = "INSERT OR IGNORE INTO drugs (id, trade_name, arabic_name, price, old_price, main_category, category, active, company, description, dosage_form, dosage_form_ar, concentration, unit, last_price_update, visits, updated_at) VALUES"
    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        try:
            next(reader) # Skip Header
        except StopIteration:
            return
        for row in reader:
            if not row or len(row) < 7: continue
            if row[0] == 'id': continue # Extra safety
            try:
                drug_id = int(row[0]); trade = row[1]; arabic = row[2]; active = row[3]; cat = row[4]; comp = row[5]; p = row[6]
                old_p = row[7] if len(row) > 7 else ""; update = row[8] if len(row) > 8 else ""; visits = int(row[9]) if len(row) > 9 and row[9].isdigit() else 0
                conc = row[12] if len(row) > 12 else ""; unit = row[13] if len(row) > 13 else ""; d_form = row[14] if len(row) > 14 else ""; d_form_ar = row[15] if len(row) > 15 else ""
                vals = [drug_id, trade, arabic, p, old_p, cat, cat, active, comp, "", d_form, d_form_ar, conc, unit, update, visits, 0]
                sql_rows.append(f"({', '.join(map(escape_sql, vals))})")
            except Exception as e: 
                print(f"Skipping row due to error: {e}")
                continue
    write_chunked_sql("d1_import", header, sql_rows, 1000)

def process_drug_interactions():
    print("Processing Enriched (DDInter 2.0) Drug Interactions...")
    files = sorted(glob.glob("assets/data/interactions/enriched/enriched_rules_part_*.json"))
    sql_rows = []
    header = "INSERT OR IGNORE INTO drug_interactions (ingredient1, ingredient2, severity, effect, recommendation, management_text, mechanism_text, risk_level, ddinter_id, source, updated_at) VALUES"
    for fpath in files:
        with open(fpath, 'r', encoding='utf-8') as f:
            content = json.load(f)
            data = content.get('data', [])
            for item in data:
                vals = [
                    item.get('ingredient1', '').lower().strip(), item.get('ingredient2', '').lower().strip(),
                    item.get('severity', 'unknown'), item.get('effect') or item.get('description', ''),
                    item.get('recommendation', ''), item.get('management_text', ''),
                    item.get('mechanism_text', ''), item.get('risk_level', ''),
                    item.get('ddinter_id', ''), item.get('source', 'DDInter'), 0
                ]
                sql_rows.append(f"({', '.join(map(escape_sql, vals))})")
    write_chunked_sql("d1_rules", header, sql_rows, 800)

def process_food_interactions():
    print("Processing Enriched Food Interactions...")
    path = "assets/data/interactions/enriched/enriched_food_interactions.json"
    if not os.path.exists(path): return
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    header = "INSERT OR IGNORE INTO food_interactions (med_id, trade_name, interaction, source) VALUES"
    sql_rows = [f"({', '.join(map(escape_sql, [item.get('med_id'), item.get('trade_name'), item.get('interaction'), item.get('source', 'DrugBank')]))})" for item in data]
    write_chunked_sql("d1_food", header, sql_rows, 1000)

def process_disease_interactions():
    print("Processing Enriched Disease Interactions...")
    path = "assets/data/interactions/enriched/enriched_disease_interactions.json"
    if not os.path.exists(path): return
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    header = "INSERT OR IGNORE INTO disease_interactions (med_id, trade_name, disease_name, interaction_text, source) VALUES"
    sql_rows = [f"({', '.join(map(escape_sql, [item.get('med_id'), item.get('trade_name'), item.get('disease_name'), item.get('interaction_text'), item.get('source', 'DDInter')]))})" for item in data]
    write_chunked_sql("d1_disease", header, sql_rows, 1000)

def process_dosages():
    print("Processing Dosage Guidelines...")
    path = "assets/data/dosage_guidelines.json"
    if not os.path.exists(path): return
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
        # Handle { "dosage_guidelines": [...] }
        if isinstance(data, dict) and "dosage_guidelines" in data:
            data = data["dosage_guidelines"]
    header = "INSERT OR IGNORE INTO dosage_guidelines (med_id, active_ingredient, instructions, condition, source, is_pediatric) VALUES"
    sql_rows = []
    for item in data:
        if not isinstance(item, dict): continue
        vals = [item.get('med_id'), item.get('active_ingredient'), item.get('instructions') or item.get('dosage_text', ''), item.get('condition', ''), item.get('source', 'DailyMed'), 1 if item.get('is_pediatric') else 0]
        sql_rows.append(f"({', '.join(map(escape_sql, vals))})")
    write_chunked_sql("d1_dosages", header, sql_rows, 1000)

if __name__ == "__main__":
    process_drugs()
    process_drug_interactions()
    process_food_interactions()
    process_disease_interactions()
    process_dosages()
    print("All tasks completed.")
