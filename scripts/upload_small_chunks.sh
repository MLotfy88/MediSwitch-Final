#!/bin/bash
# Upload small chunks to D1 with progress tracking

export CLOUDFLARE_API_TOKEN="yy-vk8KC4yth3Cn2lpva1AgrP2kGMJrQQrGIUM1-"

CHUNKS_DIR="/home/adminlotfy/project/d1_chunks_small"
cd /home/adminlotfy/project/cloudflare-worker

echo "🚀 D1 Upload - Small Chunks Strategy"
echo "===================================="
echo ""

# Count chunks
TOTAL=$(ls -1 $CHUNKS_DIR/chunk_*.sql 2>/dev/null | wc -l)
echo "Total chunks to upload: $TOTAL"
echo ""

# Upload schema first (skip if already done)
echo "📋 Uploading schema (if needed)..."
wrangler d1 execute mediswitch-db --remote --yes --file="$CHUNKS_DIR/drugs_schema.sql" > /dev/null 2>&1
echo "✅ Schema ready"
echo ""

# Upload chunks with progress
SUCCESS=0
FAILED=0
START_TIME=$(date +%s)

for chunk_file in $(ls -1 $CHUNKS_DIR/chunk_*.sql | sort); do
    CHUNK_NUM=$(basename "$chunk_file" .sql | sed 's/chunk_//')
    
    # Upload
    if wrangler d1 execute mediswitch-db --remote --yes --file="$chunk_file" 2>&1 | grep -qi "success"; then
        SUCCESS=$((SUCCESS + 1))
    else
        FAILED=$((FAILED + 1))
        echo "⚠️  Chunk $CHUNK_NUM failed"
    fi
    
    # Progress every 10 chunks
    TOTAL_DONE=$((SUCCESS + FAILED))
    if [ $((TOTAL_DONE % 10)) -eq 0 ]; then
        PERCENT=$((TOTAL_DONE * 100 / TOTAL))
        ELAPSED=$(($(date +%s) - START_TIME))
        echo "[$TOTAL_DONE/$TOTAL] $PERCENT% | ✅ $SUCCESS | ❌ $FAILED | Time: ${ELAPSED}s"
    fi
    
    # Small delay
    sleep 0.2
done

# Final summary
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo "===================================="
echo "✅ Upload Complete!"
echo ""
echo "📊 Results:"
echo "   Success: $SUCCESS"
echo "   Failed:  $FAILED"
echo "   Total:   $TOTAL"
echo "   Duration: ${DURATION}s"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "🎉 All chunks uploaded successfully!"
else
    echo "⚠️  Some chunks failed. You may retry failed ones manually."
fi
