#!/bin/bash
# scripts/deploy_d1.sh

# Exit on error
set -e

# Credentials
export CLOUDFLARE_API_TOKEN="yy-vk8KC4yth3Cn2lpva1AgrP2kGMJrQQrGIUM1-"
export CLOUDFLARE_EMAIL="eedf653449abdca28e865ddf3511dd4c62ed2"
DB_NAME="mediswitsh-db"

cd cloudflare-worker

echo "🚀 Starting D1 Deployment..."

# 1. Apply Schema
echo "📄 Applying Schema..."
npx wrangler d1 execute $DB_NAME --file=schema.sql

# 2. Deploy Drugs
echo "💊 Deploying Drugs Data (d1_import.sql)..."
if [ -f "../d1_import.sql" ]; then
  npx wrangler d1 execute $DB_NAME --file=../d1_import.sql
else
  echo "⚠️ ../d1_import.sql not found!"
fi

# 3. Deploy Dosage Guidelines
echo "📏 Deploying Dosage Guidelines (d1_dosages.sql)..."
if [ -f "../d1_dosages.sql" ]; then
  npx wrangler d1 execute $DB_NAME --file=../d1_dosages.sql
fi

# 4. Deploy Food Interactions
echo "🍎 Deploying Food Interactions (d1_food_interactions.sql)..."
if [ -f "../d1_food_interactions.sql" ]; then
  npx wrangler d1 execute $DB_NAME --file=../d1_food_interactions.sql
fi

# 5. Deploy Disease Interactions
echo "🦠 Deploying Disease Interactions (d1_disease_interactions.sql)..."
if [ -f "../d1_disease_interactions.sql" ]; then
  npx wrangler d1 execute $DB_NAME --file=../d1_disease_interactions.sql
fi

# 6. Deploy Drug Interactions (Rules) - Loop
echo "⚠️ Deploying Drug Interactions (this may take a while)..."
# Find all d1_rules_part_*.sql files in parent dir and sort them
FILES=$(find .. -maxdepth 1 -name "d1_rules_part_*.sql" | sort)

count=0
total=$(echo "$FILES" | wc -w)

for f in $FILES; do
  count=$((count + 1))
  echo "  Model processing $count/$total: $f"
  npx wrangler d1 execute $DB_NAME --file="$f"
done

echo "✅ Deployment Complete!"
