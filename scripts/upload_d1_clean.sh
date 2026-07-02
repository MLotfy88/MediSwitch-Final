#!/bin/bash
# رفع النسخة النظيفة إلى D1

export CLOUDFLARE_API_TOKEN="yy-vk8KC4yth3Cn2lpva1AgrP2kGMJrQQrGIUM1-"
CHUNKS_DIR="/home/adminlotfy/project/d1_clean_chunks"

cd /home/adminlotfy/project/cloudflare-worker

echo "🚀 رفع البيانات النظيفة إلى D1"
echo "================================"
echo ""

# Count files
TOTAL=$(ls -1 $CHUNKS_DIR/*_data.sql 2>/dev/null | wc -l)

echo "📊 الملفات: schema + $TOTAL data files"
echo ""

SUCCESS=0
FAILED=0
START=$(date +%s)

# Schema
echo "[1/$((TOTAL + 1))] Schema..."
if wrangler d1 execute mediswitch-db --remote --yes --file="$CHUNKS_DIR/00_schema.sql" 2>&1 | grep -qi "success"; then
    echo "  ✅"
    SUCCESS=$((SUCCESS + 1))
else
    echo "  ⚠️  (exists)"
fi
echo ""

# Data files
for file in $(ls -1 $CHUNKS_DIR/*_data.sql | sort); do
    NAME=$(basename "$file")
    NUM=$(echo "$NAME" | grep -o '^[0-9]\+')
    
    echo "[$((NUM + 1))/$((TOTAL + 1))] $NAME..."
    
    if wrangler d1 execute mediswitch-db --remote --yes --file="$file" 2>&1 | grep -qi "success"; then
        SUCCESS=$((SUCCESS + 1))
        echo "  ✅"
    else
        FAILED=$((FAILED + 1))
        echo "  ❌"
    fi
    
    sleep 0.5
done

DURATION=$(($(date +%s) - START))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

echo ""
echo "================================"
echo "✅ مكتمل!"
echo ""
echo "📊 النتائج:"
echo "   ✅ Success: $SUCCESS / $((TOTAL + 1))"
echo "   ❌ Failed: $FAILED"
echo "   ⏱️  Time: ${MINUTES}m ${SECONDS}s"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "🎉 جميع الملفات رُفعت بنجاح!"
fi
