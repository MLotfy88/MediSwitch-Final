#!/bin/bash
# Upload REPLACE chunks to D1

export CLOUDFLARE_API_TOKEN="yy-vk8KC4yth3Cn2lpva1AgrP2kGMJrQQrGIUM1-"
CHUNKS_DIR="/home/adminlotfy/project/d1_chunks_replace"
cd /home/adminlotfy/project/cloudflare-worker

echo "🚀 D1 Upload - REPLACE Strategy"
echo "================================"
echo ""

TOTAL=$(ls -1 $CHUNKS_DIR/chunk_*.sql 2>/dev/null | wc -l)
echo "Total chunks: $TOTAL"
echo ""

# Schema is already uploaded, skip it
echo "⏭️  Skipping schema (already exists)"
echo ""

SUCCESS=0
FAILED=0
START_TIME=$(date +%s)

for chunk_file in $(ls -1 $CHUNKS_DIR/chunk_*.sql | sort); do
    CHUNK_NUM=$(basename "$chunk_file" .sql | sed 's/chunk_//')
    
    if wrangler d1 execute mediswitch-db --remote --yes --file="$chunk_file" 2>&1 | grep -qi "success"; then
        SUCCESS=$((SUCCESS + 1))
    else
        FAILED=$((FAILED + 1))
        echo "⚠️  Chunk $CHUNK_NUM failed"
    fi
    
    TOTAL_DONE=$((SUCCESS + FAILED))
    if [ $((TOTAL_DONE % 20)) -eq 0 ]; then
        PERCENT=$((TOTAL_DONE * 100 / TOTAL))
        ELAPSED=$(($(date +%s) - START_TIME))
        echo "[$TOTAL_DONE/$TOTAL] $PERCENT% | ✅ $SUCCESS | ❌ $FAILED | ${ELAPSED}s"
    fi
    
    sleep 0.2
done

DURATION=$(($(date +%s) - START_TIME))
echo ""
echo "================================"
echo "✅ Complete!"
echo "Success: $SUCCESS / $TOTAL"
echo "Failed:  $FAILED"
echo "Time:    ${DURATION}s"
