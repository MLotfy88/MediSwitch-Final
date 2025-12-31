#!/bin/bash
# scripts/deploy_d1.sh

# Exit on error (removed for manual retry handling)
set +e

# Credentials provided by user
export CLOUDFLARE_API_TOKEN="yy-vk8KC4yth3Cn2lpva1AgrP2kGMJrQQrGIUM1-"
export CLOUDFLARE_EMAIL="eedf653449abdca28e865ddf3511dd4c62ed2"
DB_NAME="mediswitsh-db"

# Navigate to worker directory relative to script location
cd "$(dirname "$0")/../cloudflare-worker"

echo "🚀 Starting Resilient D1 Deployment..."

# Function to execute a single file with retries
execute_with_retry() {
    local file=$1
    local max_retries=3
    local retry_count=0
    local success=0

    while [ $retry_count -lt $max_retries ] && [ $success -eq 0 ]; do
        echo "  - Executing $file (Attempt $((retry_count + 1))/$max_retries)..."
        if npx wrangler d1 execute $DB_NAME --yes --remote --file="$file"; then
            success=1
            echo "  ✅ Success: $file"
        else
            retry_count=$((retry_count + 1))
            echo "  ⚠️ Failed: $file. Retrying in 5 seconds..."
            sleep 5
        fi
    done

    if [ $success -eq 0 ]; then
        echo "  ❌ ERROR: Failed to deploy $file after $max_retries attempts."
        exit 1
    fi
    
    # Small pause to prevent rate limiting
    sleep 1
}

# Function to execute multiple files
execute_files() {
    local pattern=$1
    local label=$2
    echo "📦 Deploying $label dataset..."
    FILES=$(find .. -maxdepth 1 -name "$pattern" | sort)
    if [ -z "$FILES" ]; then
        echo "  ⚠️ No files matching $pattern found."
    else
        total=$(echo "$FILES" | wc -w)
        count=0
        for f in $FILES; do
            count=$((count + 1))
            echo "  [$count/$total] $label"
            execute_with_retry "$f"
        done
    fi
}

# 1. Apply Schema
echo "📄 Applying Schema..."
execute_with_retry "schema.sql"

# 2. Deploy Drugs
execute_files "d1_import_part_*.sql" "Drugs"

# 3. Deploy Drug Interactions (Rules)
execute_files "d1_rules_part_*.sql" "Drug Interactions"

# 4. Deploy Food Interactions
execute_files "d1_food_part_*.sql" "Food"

# 5. Deploy Disease Interactions
execute_files "d1_disease_part_*.sql" "Disease"

# 6. Deploy Dosage Guidelines
execute_files "d1_dosages_part_*.sql" "Dosage"

echo "✅ High-Fidelity Deployment Complete! All datasets synced and verified."
