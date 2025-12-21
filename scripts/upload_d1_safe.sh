#!/bin/bash
# رفع آمن لجميع chunks مع retry logic

export CLOUDFLARE_API_TOKEN="yy-vk8KC4yth3Cn2lpva1AgrP2kGMJrQQrGIUM1-"
CHUNKS_DIR="/home/adminlotfy/project/d1_safe_chunks"
LOG_FILE="/home/adminlotfy/project/d1_upload_final.log"

cd /home/adminlotfy/project/cloudflare-worker

echo "🚀 رفع البيانات الكاملة إلى D1" | tee $LOG_FILE
echo "================================" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Count files
TOTAL=$(ls -1 $CHUNKS_DIR/*_data.sql 2>/dev/null | wc -l)
echo "📊 Schema + $TOTAL data files" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

SUCCESS=0
FAILED=0
SKIPPED=0
START=$(date +%s)

# Schema
echo "[1/$((TOTAL + 1))] Schema..." | tee -a $LOG_FILE
if wrangler d1 execute mediswitch-db --remote --yes --file="$CHUNKS_DIR/00_schema.sql" 2>&1 | tee -a $LOG_FILE | grep -qi "success\|executed"; then
    echo " ✅" | tee -a $LOG_FILE
    SUCCESS=$((SUCCESS + 1))
else
    echo " ⚠️  (may exist)" | tee -a $LOG_FILE
    SKIPPED=$((SKIPPED + 1))
fi
echo "" | tee -a $LOG_FILE

# Data files with progress
CURRENT=1
for file in $(ls -1 $CHUNKS_DIR/*_data.sql | sort); do
    NAME=$(basename "$file")
    
    # Progress indicator
    PERCENT=$((CURRENT * 100 / TOTAL))
    echo "[$((CURRENT + 1))/$((TOTAL + 1))] $NAME ($PERCENT%)..." | tee -a $LOG_FILE
    
    # Upload with retry
    RETRY=0
    MAX_RETRIES=2
    UPLOADED=false
    
    while [ $RETRY -le $MAX_RETRIES ] && [ "$UPLOADED" = false ]; do
        if [ $RETRY -gt 0 ]; then
            echo "  ↻ Retry $RETRY..." | tee -a $LOG_FILE
            sleep 2
        fi
        
        if wrangler d1 execute mediswitch-db --remote --yes --file="$file" 2>&1 | tee -a $LOG_FILE | grep -qi "success\|executed"; then
            echo "  ✅" | tee -a $LOG_FILE
            SUCCESS=$((SUCCESS + 1))
            UPLOADED=true
        else
            RETRY=$((RETRY + 1))
        fi
    done
    
    if [ "$UPLOADED" = false ]; then
        echo "  ❌ Failed after $MAX_RETRIES retries" | tee -a $LOG_FILE
        FAILED=$((FAILED + 1))
    fi
    
    CURRENT=$((CURRENT + 1))
    sleep 0.3  # Rate limiting
done

DURATION=$(($(date +%s) - START))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

echo "" | tee -a $LOG_FILE
echo "================================" | tee -a $LOG_FILE
echo "✅ رفع مكتمل!" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
echo "📊 النتائج:" | tee -a $LOG_FILE
echo "   ✅ Success: $SUCCESS" | tee -a $LOG_FILE
echo "   ❌ Failed: $FAILED" | tee -a $LOG_FILE
echo "   ⚠️  Skipped: $SKIPPED" | tee -a $LOG_FILE
echo "   📦 Total: $((TOTAL + 1))" | tee -a $LOG_FILE
echo "   ⏱️  Time: ${MINUTES}m ${SECONDS}s" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

if [ $FAILED -eq 0 ]; then
    echo "🎉 جميع الملفات رُفعت بنجاح!" |tee -a $LOG_FILE
    
    # Verify
    echo "" | tee -a $LOG_FILE
    echo "🔍 التحقق النهائي..." | tee -a $LOG_FILE
    wrangler d1 execute mediswitch-db --remote --yes --command="SELECT COUNT(*) as total FROM drugs;" | tee -a $LOG_FILE
else
    echo "⚠️  بعض الملفات فشلت - راجع اللوج" | tee -a $LOG_FILE
fi

echo "" | tee -a $LOG_FILE
echo "📁 Log: $LOG_FILE" | tee -a $LOG_FILE
