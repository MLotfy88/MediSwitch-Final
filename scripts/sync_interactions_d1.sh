#!/bin/bash
# Sync Drug Interactions to D1 (Chunked)
# Usage: ./scripts/sync_interactions_d1.sh

echo "🚀 Starting D1 Interaction Sync..."

# Directory containing the generated SQL parts
SQL_DIR="."

# Find all chunk files (Rules and Ingredients)
FILES=$(ls $SQL_DIR/d1_rules_part_*.sql $SQL_DIR/d1_ingredients_part_*.sql 2>/dev/null | sort -V)

if [ -z "$FILES" ]; then
    echo "❌ No SQL chunks found. Run upload_interactions_d1.py first."
    exit 1
fi

COUNT=$(echo "$FILES" | wc -l)
echo "📦 Found $COUNT chunk files."

CURRENT=1
for FILE in $FILES; do
    echo "Processing $FILE ($CURRENT/$COUNT)..."
    
    # Execute with Wrangler
    # d1_interactions_part_1.sql usually contains DROP/CREATE logic
    npx wrangler d1 execute mediswitch-db --file="$FILE" --remote
    
    if [ $? -ne 0 ]; then
        echo "❌ Error executing $FILE. Aborting."
        exit 1
    fi
    
    CURRENT=$((CURRENT+1))
    # Optional sleep to be nice to API
    sleep 1
done

echo "✅ All chunks synced successfully!"
