#!/bin/bash
# Local Test Script - Quick Pipeline Validation
# Tests the entire workflow with 5 drugs locally before running on GitHub Actions

set -e  # Exit on error

echo "========================================"
echo "🧪 Local Pipeline Test (5 Drugs)"
echo "========================================"

# Configuration
LIMIT=5
TEST_DIR="test_output"

# Create test output directory
mkdir -p "$TEST_DIR"

echo ""
echo "📦 Step 1: Scraping $LIMIT drugs..."
python3 scripts/scrape_dwaprices_by_id.py --limit $LIMIT

echo ""
echo "📝 Step 2: Updating meds.csv..."
python3 scripts/update_meds.py

echo ""
echo "📊 Step 3: Checking DailyMed cache..."
if [ -f "production_data/dailymed_full_database.jsonl" ]; then
    size=$(stat -c%s "production_data/dailymed_full_database.jsonl" 2>/dev/null || stat -f%z "production_data/dailymed_full_database.jsonl")
    echo "   ✅ Found cached DailyMed: $(($size / 1024 / 1024)) MB"
    
    if [ $size -lt 100000000 ]; then
        echo "   ⚠️  Cache too small, downloading..."
        python3 scripts/download_dailymed.py
        python3 production_data/extract_full_dailymed.py
    fi
else
    echo "   ❌ No cache found, downloading..."
    python3 scripts/download_dailymed.py
    python3 production_data/extract_full_dailymed.py
fi

echo ""
echo "🔍 Step 4: Extracting dosages..."
python3 scripts/process_datalake.py

echo ""
echo "💊 Step 5: Extracting interactions..."
python3 production_data/extract_dailymed_interactions.py

echo ""
echo "🔄 Step 6: Merging hybrid data..."
python3 scripts/merge_hybrid_data.py

echo ""
echo "📦 Step 7: Generating app assets..."
python3 scripts/bootstrap_app_data.py

echo ""
echo "========================================"
echo "✅ Test Complete - Verification:"
echo "========================================"

echo ""
echo "Scraped Data:"
[ -f "assets/meds_scraped_new.jsonl" ] && wc -l "assets/meds_scraped_new.jsonl" || echo "❌ Missing"

echo ""
echo "Matched Dosages:"
[ -f "production_data/production_dosages.jsonl" ] && wc -l "production_data/production_dosages.jsonl" || echo "❌ Missing"

echo ""
echo "Generated Assets:"
[ -f "assets/data/dosage_guidelines.json" ] && echo "✅ dosage_guidelines.json" || echo "❌ Missing"
[ -f "assets/data/drug_interactions.json" ] && echo "✅ drug_interactions.json" || echo "❌ Missing"

echo ""
echo "CSV Records:"
[ -f "assets/meds.csv" ] && wc -l "assets/meds.csv" || echo "❌ Missing"

echo ""
echo "========================================"
echo "🎉 Test pipeline successful!"
echo "========================================"
echo ""
echo "Next steps:"
echo "1. Review output files to verify data quality"
echo "2. If satisfied, run full rebuild with: gh workflow run rebuild-full-database.yml"
