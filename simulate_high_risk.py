import sqlite3
import os

# 1. Locate Database
db_path = "/home/adminlotfy/project/assets/data/mediswitch_data.db"
# Fallback search if not found
if not os.path.exists(db_path):
    print(f"Database not found at {db_path}, searching...")
    found = False
    for root, dirs, files in os.walk("/home/adminlotfy/project"):
        for file in files:
            if file.endswith(".db"):
                db_path = os.path.join(root, file)
                print(f"Found database at: {db_path}")
                found = True
                break
        if found: break
    if not found:
        print("❌ CRITICAL: Could not find any .db file!")
        exit(1)

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# 2. Simulate User Flow
print("🚀 Starting High Risk Ingredients Simulation...")
report_file = "high_risk_report.txt"

with open(report_file, "w") as f:
    f.write("=== MEDICAL APP SIMULATION REPORT ===\n")
    f.write(f"Database: {db_path}\n")
    f.write("======================================\n\n")

    # A. Get High Risk Ingredients list (Simulating getHighRiskIngredientsWithMetrics)
    print("Step 1: Fetching High Risk Ingredients List...")
    f.write("--- STEP 1: High Risk Ingredients List (Top 10) ---\n")
    
    # This matches the SQL used in sqlite_local_data_source.dart
    high_risk_sql = """
    WITH AffectedIngredients AS (
      SELECT ingredient1 as original_name, TRIM(REPLACE(REPLACE(LOWER(ingredient1), '(', ''), ')', '')) as ingredient_key, severity FROM drug_interactions 
      WHERE LOWER(severity) IN ('contraindicated', 'severe', 'major', 'high', 'moderate', 'critical', 'serious')
      UNION ALL
      SELECT ingredient2 as original_name, TRIM(REPLACE(REPLACE(LOWER(ingredient2), '(', ''), ')', '')) as ingredient_key, severity FROM drug_interactions 
      WHERE LOWER(severity) IN ('contraindicated', 'severe', 'major', 'high', 'moderate', 'critical', 'serious')
    ),
    IngredientStats AS (
      SELECT 
        ingredient_key,
        COUNT(*) as totalInteractions,
        SUM(CASE WHEN LOWER(severity) IN ('contraindicated', 'severe', 'critical', 'high') THEN 1 ELSE 0 END) as severeCount,
        SUM(CASE WHEN LOWER(severity) IN ('major', 'moderate', 'serious') THEN 1 ELSE 0 END) as moderateCount,
        SUM(CASE WHEN LOWER(severity) = 'minor' THEN 1 ELSE 0 END) as minorCount,
        SUM(CASE 
          WHEN LOWER(severity) = 'contraindicated' THEN 10 
          WHEN LOWER(severity) IN ('severe', 'critical') THEN 8
          WHEN LOWER(severity) IN ('high', 'serious') THEN 7
          WHEN LOWER(severity) = 'major' THEN 5
          WHEN LOWER(severity) = 'moderate' THEN 3
          ELSE 1 
        END) as dangerScore
      FROM AffectedIngredients
      WHERE ingredient_key NOT IN (
          'pro', 'met', 'ors', 'interactions', 'bee', 'sage', 
          'bet', 'vit', 'but', 'epa', 'thy', 'ros', 'eru', 'prop',
          'drugs', 'food', 'alcohol', 'water'
        )
      AND LENGTH(ingredient_key) > 2
      GROUP BY ingredient_key
    )
    SELECT 
        ingredient_key as normalized_name, -- Using key as name simplifies for this script
        totalInteractions,
        severeCount
    FROM IngredientStats
    ORDER BY dangerScore DESC
    LIMIT 20
    """
    
    try:
        cursor.execute(high_risk_sql)
        high_risk_items = cursor.fetchall()
        
        for item in high_risk_items:
            name = item[0]
            count = item[1]
            severe = item[2]
            f.write(f"• {name} (Total: {count}, Severe: {severe})\n")
    except Exception as e:
        f.write(f"❌ Error fetching high risk: {e}\n")
        print(f"Error: {e}")

    f.write("\n\n")

    # B. Simulate clicking on specific cards (Olive Oil, Warfarin, etc.)
    test_ingredients = ["olive oil", "warfarin", "aspirin", "testosterone"]
    
    # Also test items from the DB result if not in our test list
    for item in high_risk_items[:2]:
        if item[0] not in test_ingredients:
            test_ingredients.append(item[0])

    print("Step 2: Simulating Card Clicks & Interaction Retrieval...")
    
    for ingredient in test_ingredients:
        f.write(f"--- STEP 2: Detail View for '{ingredient}' ---\n")
        f.write(f"User clicks on card: {ingredient}\n")
        
        # Simulating getInteractionsWith(normalizedName)
        # 1. Normalize query
        query = ingredient.lower().strip().replace('(', '').replace(')', '')
        # 2. Search terms logic (simulation)
        search_terms = [query]
        if "+" in query:
            search_terms.extend([p.strip() for p in query.split('+')])
            
        f.write(f"Search Query: '{query}', Search Terms: {search_terms}\n")
        
        interaction_sql = f"""
        SELECT 
            id, ingredient1, ingredient2, severity, effect 
        FROM drug_interactions 
        WHERE 
            TRIM(LOWER(ingredient1)) LIKE ? OR 
            TRIM(LOWER(ingredient2)) LIKE ? OR
            TRIM(LOWER(ingredient1)) LIKE ? OR 
            TRIM(LOWER(ingredient2)) LIKE ?
        """
        # Note: The app uses parameters for each search term. Here we simplify for the simulation of 'contains'
        # We'll just mimic the LIKE '%query%' behavior for simplicity as it matches the app's fallback mostly
        
        try:
            # We'll fetch ALL and then filter in python like the app does for primary/secondary logic
            # This ensures we see exactly what the logical filter would do
            # cursor.execute("SELECT ingredient1, ingredient2, severity, description FROM drug_interactions") 
            # Doing a full fetch and filter is inefficient here but accurate to logic testing
            # Actually, let's use SQL for the first pass to be faster
            
            cursor.execute(f"""
                SELECT ingredient1, ingredient2, severity 
                FROM drug_interactions 
                WHERE 
                   LOWER(ingredient1) LIKE '%{query}%' OR 
                   LOWER(ingredient2) LIKE '%{query}%'
            """)
            
            interactions = cursor.fetchall()
            
            primary_list = []
            secondary_list = []
            
            for row in interactions:
                ing1 = row[0]
                ing2 = row[1]
                severity = row[2]
                
                # Logic from app:
                ing1_lower = ing1.lower() if ing1 else ""
                
                is_primary = False
                # If ingredient1 contains the search term
                if query in ing1_lower:
                    is_primary = True
                
                # Formatted string
                entry = f"{ing1} + {ing2} ({severity})"
                
                if is_primary:
                    primary_list.append(entry)
                else:
                    secondary_list.append(entry)
            
            f.write(f"Total Results: {len(interactions)}\n")
            
            f.write(f"\n[SECTION 1: DIRECT INTERACTIONS] (Count: {len(primary_list)})\n")
            if not primary_list:
                f.write("  (No direct interactions found)\n")
            else:
                for p in primary_list[:10]: # Show top 10
                    f.write(f"  ✅ {p}\n")
                if len(primary_list) > 10: f.write(f"  ... and {len(primary_list)-10} more\n")

            f.write(f"\n[SECTION 2: SECONDARY INTERACTIONS] (Count: {len(secondary_list)})\n")
            if not secondary_list:
                f.write("  (No secondary interactions found)\n")
            else:
                for s in secondary_list[:10]: # Show top 10
                    f.write(f"  ℹ️ {s}\n")
                if len(secondary_list) > 10: f.write(f"  ... and {len(secondary_list)-10} more\n")
                
        except Exception as e:
            f.write(f"❌ Error fetching interactions: {e}\n")
            
        f.write("\n" + "="*40 + "\n\n")

conn.close()
print(f"✅ Simulation complete. Report saved to {report_file}")
