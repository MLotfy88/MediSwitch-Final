#!/bin/bash
# رفع جميع chunks إلى D1 تلقائياً

export CLOUDFLARE_API_TOKEN="yy-vk8KC4yth3Cn2lpva1AgrP2kGMJrQQrGIUM1-"
CHUNKS_DIR="/home/adminlotfy/project/d1_final_chunks"

cd /home/adminlotfy/project/cloudflare-worker

echo "🚀 بدء رفع ال chunks إلى D1"
echo "==============================="
echo ""

SUCCESS=0
FAILED=0
START=$(date +%s)

# Upload schema first
echo "📋 [1/11] رفع Schema..."
if wrangler d1 execute mediswitch-db --remote --yes --file="$CHUNKS_DIR/00_schema.sql" 2>&1 | grep -qi "success"; then
    echo "   ✅ Schema uploaded"
    SUCCESS=$((SUCCESS + 1))
else
    echo "   ⚠️  Schema skipped (probably exists)"
fi
echo ""

# Upload data chunks
for chunk_file in $(ls -1 $CHUNKS_DIR/*_data.sql | sort); do
    CHUNK_NAME=$(basename "$chunk_file")
    CHUNK_NUM=$(echo "$CHUNK_NAME" | grep -o '^[0-9]\+')
    
    echo "📦 [$((CHUNK_NUM + 1))/11] رفع $CHUNK_NAME..."
    
    if wrangler d1 execute mediswitch-db --remote --yes --file="$chunk_file" 2>&1 | grep -qi "success"; then
        SUCCESS=$((SUCCESS + 1))
        echo "   ✅ نجح"
    else
        FAILED=$((FAILED + 1))
        echo "   ❌ فشل"
    fi
    
    sleep 1  # Small delay
    echo ""
done

DURATION=$(($(date +%s) - START))

echo "==============================="
echo "✅ الرفع مكتمل!"
echo ""
echo "📊 النتائج:"
echo "   ✅ Successful: $SUCCESS"
echo "   ❌ Failed: $FAILED"
echo "   ⏱️  Time: ${DURATION}s"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "🎉 جميع الـ chunks تم رفعها بنجاح!"
else
    echo "⚠️  بعض الـ chunks فشلت، يمكن إعادة المحاولة يدوياً"
fi
