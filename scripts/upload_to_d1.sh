#!/bin/bash
# Upload database to Cloudflare D1
# Usage: ./upload_to_d1.sh [sql_file]

set -e  # Exit on error

SQL_FILE="${1:-d1_import.sql}"
DB_NAME="mediswitch-db"

echo "🚀 Uploading database to Cloudflare D1..."
echo "   SQL File: $SQL_FILE"
echo "   Database: $DB_NAME"
echo ""

# Check if file exists
if [ ! -f "$SQL_FILE" ]; then
    echo "❌ Error: SQL file not found: $SQL_FILE"
    echo "   Run: python3 scripts/export_to_d1.py"
    exit 1
fi

# Check if wrangler is installed
if ! command -v wrangler &> /dev/null; then
    echo "❌ Error: wrangler CLI not found"
    echo "   Install with: npm install -g wrangler"
    exit 1
fi

# Get file size
FILE_SIZE=$(du -h "$SQL_FILE" | cut -f1)
echo "📦 File size: $FILE_SIZE"
echo ""

# Execute SQL in D1
echo "📤 Uploading to D1..."
cd cloudflare-worker

# Note: D1 has a 1MB limit per query, so large files need to be split
# wrangler d1 execute can handle the splitting

wrangler d1 execute "$DB_NAME" --file="../$SQL_FILE" --remote

echo ""
echo "✅ Upload complete!"
echo ""
echo "🔍 Verifying..."
wrangler d1 execute "$DB_NAME" --command="SELECT COUNT(*) as total FROM drugs;" --remote

echo ""
echo "✅ Database sync to D1 complete!"
