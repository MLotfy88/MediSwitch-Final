# Data Update Workflow - Documentation

## Overview
This document explains how the automated data update system works and how it preserves existing data while applying updates.

## Problem Solved
Previously, the update workflow would **overwrite** the entire `assets/meds.csv` file, resulting in data loss. Now it **merges** updates intelligently based on drug IDs.

## Components

### 1. Merge Script (`scripts/merge_meds.py`)
**Purpose**: Safely merge medication updates without losing existing data.

**How it works**:
- Loads the main database (`assets/meds.csv`)
- Loads the update file (e.g., `meds_enriched.csv`)
- For each drug in the update:
  - If the drug ID exists: **UPDATE** the record
  - If the drug ID is new: **INSERT** the record
- Creates a timestamped backup before writing
- Writes the merged data back to the main file

**Usage**:
```bash
python scripts/merge_meds.py <main_database> <updates_file> [output_file]
```

**Example**:
```bash
python scripts/merge_meds.py assets/meds.csv meds_enriched.csv
```

### 2. GitHub Actions Workflow (`.github/workflows/daily-update.yml`)
**Updated Step**: "Update app database (MERGE, not overwrite)"

**Logic**:
```bash
if [ ! -f assets/meds.csv ]; then
  # First run - create database
  cp meds_enriched.csv assets/meds.csv
else
  # Merge updates into existing database
  python3 scripts/merge_meds.py assets/meds.csv meds_enriched.csv
fi
```

### 3. Local Database Update (`update_local_database.py`)
**Updated**: Now uses `INSERT OR REPLACE` instead of `DELETE` + `INSERT`

**Before**:
```python
cursor.execute('DELETE FROM medications')  # ❌ Data loss!
cursor.execute('INSERT INTO medications VALUES (...)')
```

**After**:
```python
cursor.execute('INSERT OR REPLACE INTO medications VALUES (...)')  # ✅ Safe upsert
```

## Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Scraper runs and fetches latest drug prices              │
│    Output: meds_updated.csv                                 │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Enrichment adds categories, translations, etc.           │
│    Output: meds_enriched.csv                                │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Merge Script (NEW!)                                      │
│    - Reads existing assets/meds.csv                         │
│    - Merges with meds_enriched.csv based on ID              │
│    - Creates backup                                         │
│    - Writes merged data                                     │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. Database update (SQLite)                                 │
│    - Uses INSERT OR REPLACE for safe upsert                 │
└─────────────────────────────────────────────────────────────┘
```

## Key Features

✅ **Data Preservation**: Existing records are never lost
✅ **Automatic Backups**: Each merge creates a timestamped backup
✅ **ID-Based Updates**: Uses the `id` column as the primary key
✅ **New Record Detection**: Automatically adds new drugs
✅ **Price History**: Preserves `old_price` and `last_price_update` fields

## Backup Policy

Every merge creates a backup with the format:
```
assets/meds.csv.backup_YYYYMMDD_HHMMSS
```

Example: `assets/meds.csv.backup_20251204_180500`

## Manual Usage

If you need to manually merge data:

```bash
# Merge updates from a new file
python scripts/merge_meds.py assets/meds.csv new_data.csv

# Restore from backup
cp assets/meds.csv.backup_20251204_180500 assets/meds.csv
```

## Testing

To test the merge script locally:

```bash
# Create test files
head -n 100 assets/meds.csv > test_main.csv
head -n 50 meds_enriched.csv > test_updates.csv

# Run merge
python scripts/merge_meds.py test_main.csv test_updates.csv test_output.csv

# Verify
wc -l test_*.csv
```

## Monitoring

The GitHub Actions workflow now reports:
- Total records after merge
- Upload status to Cloudflare Worker
- Recent drug updates with price changes
