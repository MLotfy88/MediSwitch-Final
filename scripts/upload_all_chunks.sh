#!/bin/bash
# Automated D1 Upload Script
# Uploads all drug chunks to Cloudflare D1

set -e

export CLOUDFLARE_API_TOKEN="yy-vk8KC4yth3Cn2lpva1AgrP2kGMJrQQrGIUM1-"

CHUNKS_DIR="/home/adminlotfy/project/d1_chunks"
TOTAL_CHUNKS=159

echo "🚀 Starting D1 Upload - All Chunks"
echo "=================================="
echo "Total chunks: $TOTAL_CHUNKS"
echo "Estimated time: 30-45 minutes"
echo ""

# Upload schema first
echo "📋 Step 1: Uploading schema..."
cd /home/adminlotfy/project/cloudflare-worker

wrangler d1 execute mediswitch-db --remote --yes --file="$CHUNKS_DIR/drugs_schema.sql"

if [ $? -eq 0 ]; then
    echo "✅ Schema uploaded successfully"
else
    echo "❌ Schema upload failed!"
    exit 1
fi

echo ""
echo "📤 Step 2: Uploading data chunks..."
echo "-----------------------------------"

SUCCESS_COUNT=0
FAILED_COUNT=0
START_TIME=$(date +%s)

for i in $(seq 1 $TOTAL_CHUNKS); do
    CHUNK_FILE="$CHUNKS_DIR/drugs_chunk_$i.sql"
    
    # Progress indicator
    PERCENT=$((i * 100 / TOTAL_CHUNKS))
    echo -ne "\r[$i/$TOTAL_CHUNKS] Progress: $PERCENT% | Success: $SUCCESS_COUNT | Failed: $FAILED_COUNT"
    
    # Upload chunk
    wrangler d1 execute mediswitch-db --remote --yes --file="$CHUNK_FILE" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        FAILED_COUNT=$((FAILED_COUNT + 1))
        echo ""
        echo "⚠️  Warning: Chunk $i failed, continuing..."
    fi
    
    # Small delay to avoid rate limiting
    sleep 0.5
done

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

echo ""
echo ""
echo "=================================="
echo "✅ Upload Complete!"
echo ""
echo "📊 Summary:"
echo "   Total chunks: $TOTAL_CHUNKS"
echo "   Successful: $SUCCESS_COUNT"
echo "   Failed: $FAILED_COUNT"
echo "   Duration: ${MINUTES}m ${SECONDS}s"
echo ""

if [ $FAILED_COUNT -gt 0 ]; then
    echo "⚠️  Some chunks failed. You may need to retry them manually."
else
    echo "🎉 All chunks uploaded successfully!"
fi
