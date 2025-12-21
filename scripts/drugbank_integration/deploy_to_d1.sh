#!/bin/bash
# Deploy DrugBank data to Cloudflare D1

set -e

echo "🚀 Deploying DrugBank data to Cloudflare D1"
echo "================================================"

# Configuration
DB_ID="77da23cd-a8cc-40bf-9c0f-f0effe7eeaa0"
LOCAL_DB="/home/adminlotfy/project/mediswitch.db"
OUTPUT_DIR="/home/adminlotfy/project/scripts/drugbank_integration/d1_export"

mkdir -p "$OUTPUT_DIR"

echo ""
echo "📋 Step 1: Update D1 Schema"
echo "----------------------------"
wrangler d1 execute mediswitch-db \
  --file=/home/adminlotfy/project/scripts/drugbank_integration/d1_schema_update.sql

echo ""
echo "📤 Step 2: Export Pharmacology Data"
echo "------------------------------------"

# Export drugs with pharmacology data
sqlite3 "$LOCAL_DB" <<EOF > "$OUTPUT_DIR/pharmacology_updates.sql"
.mode insert drugs
SELECT 'UPDATE drugs SET 
  indication = ' || quote(indication) || ',
  mechanism_of_action = ' || quote(mechanism_of_action) || ',
  pharmacodynamics = ' || quote(pharmacodynamics) || ',
  data_source_pharmacology = ' || quote(data_source_pharmacology) || '
WHERE id = ' || id || ';'
FROM drugs 
WHERE data_source_pharmacology = 'DrugBank'
LIMIT 1000;
EOF

echo "✅ Exported pharmacology updates for upload"

echo ""
echo "📤 Step 3: Export Food Interactions"
echo "------------------------------------"

# Export food interactions
sqlite3 "$LOCAL_DB" <<EOF > "$OUTPUT_DIR/food_interactions.sql"
.mode insert food_interactions
SELECT * FROM food_interactions LIMIT 1000;
EOF

echo "✅ Exported food interactions for upload"

echo ""
echo "⬆️  Step 4: Upload to D1 (in batches)"
echo "--------------------------------------"

# Upload pharmacology data
if [ -f "$OUTPUT_DIR/pharmacology_updates.sql" ]; then
  echo "Uploading pharmacology data..."
  wrangler d1 execute mediswitch-db \
    --file="$OUTPUT_DIR/pharmacology_updates.sql"
  echo "✅ Pharmacology data uploaded"
fi

# Upload food interactions
if [ -f "$OUTPUT_DIR/food_interactions.sql" ]; then
  echo "Uploading food interactions..."
  wrangler d1 execute mediswitch-db \
    --file="$OUTPUT_DIR/food_interactions.sql"
  echo "✅ Food interactions uploaded"
fi

echo ""
echo "================================================"
echo "✅ D1 deployment completed successfully!"
echo ""
echo "📊 Summary:"
echo "   - Schema updated with pharmacology columns"
echo "   - food_interactions table created"
echo "   - Pharmacology data uploaded (batch 1)"
echo "   - Food interactions uploaded (batch 1)"
echo ""
echo "⚠️  Note: For full data upload, run this script multiple"
echo "   times or use the Python batch upload script."
