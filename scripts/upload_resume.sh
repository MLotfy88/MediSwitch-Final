#!/bin/bash
# Simplified D1 Upload - Continue from where we left off

export CLOUDFLARE_API_TOKEN="yy-vk8KC4yth3Cn2lpva1AgrP2kGMJrQQrGIUM1-"
CHUNKS_DIR="/home/adminlotfy/project/d1_chunks"

cd /home/adminlotfy/project/cloudflare-worker

echo "🚀 Resuming D1 Upload from chunk 3..."
echo ""

SUCCESS=0
FAILED=0

for i in $(seq 3 159); do
    echo "[$i/159] Uploading chunk $i..."
    
    if wrangler d1 execute mediswitch-db --remote --yes --file="$CHUNKS_DIR/drugs_chunk_$i.sql" 2>&1 | grep -q "success.*true"; then
        SUCCESS=$((SUCCESS + 1))
        echo "  ✅ Success"
    else
        FAILED=$((FAILED + 1))
        echo "  ❌ Failed"
    fi
    
    sleep 0.3
    
    # Progress update every 10 chunks
    if [ $((i % 10)) -eq 0 ]; then
        PERCENT=$((i * 100 / 159))
        echo ""
        echo "📊 Progress: $PERCENT% | Success: $SUCCESS | Failed: $FAILED"
        echo ""
    fi
done

echo ""
echo "=================================="
echo "✅ Upload complete!"
echo "Success: $SUCCESS"
echo "Failed: $FAILED"
