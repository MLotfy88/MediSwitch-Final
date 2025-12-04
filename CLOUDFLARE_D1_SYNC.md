# Cloudflare D1 Database Sync Guide

## Overview
This guide explains how to sync your complete local database to Cloudflare D1 to prevent data loss during synchronization.

## Problem
- App builds with complete local database (`assets/medications.db`)
- D1 on Cloudflare was cleared by previous faulty script
- Sync from empty D1 → clears local database = **data loss**

## Solution
Upload complete local database to D1 using the provided scripts.

---

## Steps to Sync

### 1. Export Database to SQL
```bash
python3 scripts/export_to_d1.py
```

**What it does:**
- Reads `assets/medications.db`
- Exports all records to `d1_import.sql`
- Creates batches of 1000 records for efficient import
- Escapes special characters properly

**Output:** `d1_import.sql` (typically 5-10 MB)

### 2. Upload to Cloudflare D1
```bash
./scripts/upload_to_d1.sh
```

**Prerequisites:**
- Install wrangler CLI: `npm install -g wrangler`
- Login to Cloudflare: `wrangler login`
- Database must exist: `mediswitch-db`

**What it does:**
- Uploads SQL file to D1 database
- Handles file splitting (D1 has 1MB query limit)
- Verifies upload by counting records

### 3. Verify Sync

Query D1 to confirm:
```bash
cd cloudflare-worker
wrangler d1 execute mediswitch-db --command="SELECT COUNT(*) FROM drugs;" --remote
```

Expected output: Same count as local database (~15,000+ records)

---

## Alternative: Manual via Wrangler

If scripts don't work, use wrangler directly:

```bash
# 1. Export database
python3 scripts/export_to_d1.py

# 2. Split large SQL file (if > 5MB)
split -l 10000 d1_import.sql d1_import_part_

# 3. Upload each part
cd cloudflare-worker
for file in ../d1_import_part_*; do
    wrangler d1 execute mediswitch-db --file="$file" --remote
done
```

---

## Troubleshooting

### Error: "Database not found"
Create D1 database first:
```bash
cd cloudflare-worker
wrangler d1 create mediswitch-db
```
Then update `database_id` in `wrangler.toml`

### Error: "Query too large"
The export script already batches records. If still failing:
- Reduce `batch_size` in `export_to_d1.py` (line 51)
- Try 500 or 250 instead of 1000

### Error: "Authentication failed"
Login to Cloudflare:
```bash
wrangler login
```

### Verify Database ID
Check your D1 database:
```bash
wrangler d1 list
```

---

## Maintenance

### Future Updates
After this initial sync, the workflow uses the merge script:
- New data fetched by scraper
- Merged with existing data (not overwritten)
- Uploaded to D1 incrementally

### Re-sync Needed If:
- D1 database is deleted
- Major data corruption
- Complete database rebuild

---

## Scripts Reference

### `scripts/export_to_d1.py`
**Purpose:** Export SQLite to SQL dump  
**Input:** `assets/medications.db`  
**Output:** `d1_import.sql`

### `scripts/upload_to_d1.sh`
**Purpose:** Upload SQL to D1  
**Input:** `d1_import.sql`  
**Target:** Cloudflare D1 `mediswitch-db`

---

## Next Steps

After successful sync:
1. Test app sync functionality
2. Verify no data loss occurs
3. Monitor D1 query usage in Cloudflare dashboard
4. Set up automated backups

---

## Important Notes

⚠️ **Always backup before major operations:**
```bash
cp assets/medications.db assets/medications.db.backup_$(date +%Y%m%d_%H%M%S)
```

✅ **After sync, the GitHub Actions workflow will:**
- Fetch new drug prices
- Merge with existing data (not overwrite)
- Update both local CSV and D1 database
