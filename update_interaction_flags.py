
import subprocess
import json
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

INTERACTIONS_DB = "mediswitch-interactions"
MAIN_DB = "mediswitsh-db"

def run_d1_query(db_name, sql):
    cmd = [
        "wrangler", "d1", "execute", db_name,
        "--remote", "--command", sql, "--json"
    ]
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        logger.error(f"Error running query on {db_name}: {e.stderr}")
        return []
    except json.JSONDecodeError:
        logger.error(f"Error decoding JSON from {db_name}")
        return []

def get_ids_from_remote(db_name, sql):
    data = run_d1_query(db_name, sql)
    ids = set()
    if data and len(data) > 0 and 'results' in data[0]:
        for row in data[0]['results']:
            if 'med_id' in row:
                ids.add(row['med_id'])
    return list(ids)

def batch_update_flags(db_name, column_name, ids):
    if not ids:
        logger.info(f"No IDs to update for {column_name}")
        return

    logger.info(f"Updating {len(ids)} rows for {column_name}...")
    
    # Process in chunks of 100 to avoid command line length limits
    CHUNK_SIZE = 100
    for i in range(0, len(ids), CHUNK_SIZE):
        chunk = ids[i:i + CHUNK_SIZE]
        id_list = ",".join(str(id) for id in chunk)
        sql = f"UPDATE drugs SET {column_name} = 1 WHERE id IN ({id_list});"
        
        # Determine strictness: we don't want to crash on a single batch failure, but we want to know
        try:
            # logger.info(f"Executing batch {i // CHUNK_SIZE + 1}...")
            # We don't need --json for updates usually, but it keeps format consistent
            subprocess.run([
                "wrangler", "d1", "execute", db_name,
                "--remote", "--command", sql
            ], check=True, capture_output=True)
        except subprocess.CalledProcessError as e:
             logger.error(f"Failed to update batch starting at index {i}: {e.stderr}")

def main():
    logger.info("Starting Interaction Flags Update...")

    # 1. Reset all flags first (Optional, but good for consistency)
    logger.info("Resetting existing flags...")
    reset_sql = "UPDATE drugs SET has_drug_interaction = 0, has_food_interaction = 0, has_disease_interaction = 0;"
    try:
         subprocess.run([
                "wrangler", "d1", "execute", MAIN_DB,
                "--remote", "--command", reset_sql
            ], check=True, capture_output=True)
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to reset flags: {e.stderr}")

    # 2. Get Food Interaction IDs
    logger.info("Fetching Food Interaction IDs...")
    food_sql = "SELECT DISTINCT med_id FROM food_interactions;"
    food_ids = get_ids_from_remote(INTERACTIONS_DB, food_sql)
    logger.info(f"Found {len(food_ids)} drugs with food interactions.")

    # 3. Get Disease Interaction IDs
    logger.info("Fetching Disease Interaction IDs...")
    disease_sql = "SELECT DISTINCT med_id FROM disease_interactions;"
    disease_ids = get_ids_from_remote(INTERACTIONS_DB, disease_sql)
    logger.info(f"Found {len(disease_ids)} drugs with disease interactions.")

    # 4. Get Drug Interaction IDs
    # This requires joining med_ingredients and drug_interactions
    # Optimization: Use IN clause with subquery if possible, or JOIN
    logger.info("Fetching Drug Interaction IDs (This may take a moment)...")
    drug_sql = """
    SELECT DISTINCT m.med_id 
    FROM med_ingredients m 
    JOIN drug_interactions d ON m.ingredient = d.ingredient1 OR m.ingredient = d.ingredient2;
    """
    drug_ids = get_ids_from_remote(INTERACTIONS_DB, drug_sql)
    logger.info(f"Found {len(drug_ids)} drugs with drug-drug interactions.")

    # 5. Apply Updates to Main DB
    batch_update_flags(MAIN_DB, "has_food_interaction", food_ids)
    batch_update_flags(MAIN_DB, "has_disease_interaction", disease_ids)
    batch_update_flags(MAIN_DB, "has_drug_interaction", drug_ids)

    logger.info("Update Complete! 🚀")

if __name__ == "__main__":
    main()
