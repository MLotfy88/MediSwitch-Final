import sqlite3
import os

# Locate DB
db_path = "mediswitch.db"
if not os.path.exists(db_path):
    print("DB not found in current dir, searching...")
    for root, dirs, files in os.walk("."):
        for file in files:
            if file.endswith(".db"):
                db_path = os.path.join(root, file)
                print(f"Found: {db_path}")
                break

if not os.path.exists(db_path):
    print("❌ Could not find database file!")
    exit(1)

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# The query mimics the one in the app EXACTLY
sql = """
WITH AffectedIngredients AS (
  SELECT ingredient1 as original_name, TRIM(REPLACE(REPLACE(LOWER(ingredient1), '(', ''), ')', '')) as ingredient_key, severity 
  FROM drug_interactions 
  WHERE LOWER(severity) IN ('contraindicated', 'severe', 'major', 'high', 'moderate', 'critical', 'serious')
  UNION ALL
  SELECT ingredient2 as original_name, TRIM(REPLACE(REPLACE(LOWER(ingredient2), '(', ''), ')', '')) as ingredient_key, severity 
  FROM drug_interactions 
  WHERE LOWER(severity) IN ('contraindicated', 'severe', 'major', 'high', 'moderate', 'critical', 'serious')
)
SELECT original_name, ingredient_key, COUNT(*) as count
FROM AffectedIngredients
WHERE ingredient_key = 'pro' OR ingredient_key = 'met' OR ingredient_key = 'ors'
GROUP BY original_name
ORDER BY count DESC
LIMIT 20;
"""

print(f"Running investigation query on {db_path}...")
try:
    cursor.execute(sql)
    results = cursor.fetchall()
    print(f"Found {len(results)} matches:")
    for row in results:
        print(f"Original: '{row[0]}' -> Key: '{row[1]}' (Count: {row[2]})")
except Exception as e:
    print(f"Error: {e}")

conn.close()
