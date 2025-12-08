# Monthly Dosage Guidelines Sync - GitHub Actions Setup

## 📋 Overview

Automated GitHub Actions workflow that runs monthly to:
1. Download fresh OpenFDA drug label data (13 ZIP files)
2. Extract dosage guidelines using optimized extraction algorithm
3. Upload to Cloudflare D1 database
4. Commit changes to repository

## 📁 Files Created

### 1. GitHub Actions Workflow
**File:** `.github/workflows/monthly-dosage-sync.yml`
- **Schedule:** 15th of every month at midnight UTC
- **Timeout:** 3 hours (dosage extraction is comprehensive)
- **Manual trigger:** Available via workflow_dispatch

### 2. OpenFDA Download Script
**File:** `scripts/dosage/download_openfda_labels.py`
- Downloads all 13 drug label ZIP files from OpenFDA
- Retry logic with 3 attempts per file
- Progress tracking and size verification
- Skips existing valid files

### 3. D1 Upload Script  
**File:** `scripts/upload_dosage_d1.py`
- Creates `dosage_guidelines` table in Cloudflare D1
- Batch upload (100 records per batch)
- Rate limiting (500ms between batches)
- Automatic indexing on `active_ingredient` and `strength`

### 4. Commit Automation
**File:** `scripts/commit_dosage.sh`
- Auto-commits dosage_guidelines.json with statistics
- Creates descriptive commit messages
- Handles backups automatically

## 🔄 Workflow Steps

```
1. Checkout → 2. Setup Python → 3. Install Dependencies
    ↓
4. Download 13 ZIP files from OpenFDA
    ↓
5. Extract dosage guidelines (using optimized script)
    ↓
6. Validate extracted data (>15k records expected)
    ↓
7. Create backup of previous data
    ↓
8. Upload to Cloudflare D1 database
    ↓
9. Commit changes to repository
    ↓
10. Create summary report
```

## 📊 Expected Results

- **Total Guidelines:** ~40,000
- **With Standard Dose:** ~12,000 (30%)
- **With Max Dose:** ~3,000 (8%)
- **With Package Label:** 100%

## 🗄️ Database Schema

```sql
CREATE TABLE dosage_guidelines (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    active_ingredient TEXT NOT NULL,
    strength TEXT NOT NULL,
    standard_dose TEXT,
    max_dose TEXT,
    package_label TEXT,
    source TEXT DEFAULT 'OpenFDA',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(active_ingredient, strength)
);

-- Indexes
CREATE INDEX idx_active_ingredient ON dosage_guidelines(active_ingredient);
CREATE INDEX idx_strength ON dosage_guidelines(strength);
```

## 🔐 Required Secrets

GitHub repository must have these secrets configured:

| Secret Name | Description |
|------------|-------------|
| `CLOUDFLARE_API_TOKEN` | Cloudflare API token with D1:Edit permission |
| `CLOUDFLARE_ACCOUNT_ID` | Your Cloudflare account ID |
| `D1_DATABASE_ID` | Your D1 database ID |

## 🚀 Running Manually

### Via GitHub Actions UI
1. Go to Actions → Monthly Dosage Guidelines Sync
2. Click "Run workflow"
3. Optionally specify number of files to process (1-13)

### Locally
```bash
# 1. Download data
python3 scripts/dosage/download_openfda_labels.py

# 2. Extract dosages
python3 scripts/interactions/extract_dosages_optimized.py

# 3. Upload to D1
python3 scripts/upload_dosage_d1.py \
  --json-file assets/data/dosage_guidelines.json \
  --database-id YOUR_D1_DB_ID \
  --account-id YOUR_ACCOUNT_ID \
  --api-token YOUR_API_TOKEN
```

## ⚠️ Error Handling

- **Download failures:** Retries 3 times per file, workflow continues with available files
- **Extraction validation:** Fails if <15,000 guidelines extracted
- **D1 upload failures:** Creates GitHub issue automatically
- **Commit failures:** Reported in workflow summary

## 📝 Monitoring

### Workflow Summary
Each run creates a summary with:
- Files downloaded count
- Guidelines extracted count
- Upload success rate
- Commit status

### Notifications
- ❌ Failure: Creates GitHub issue labeled `automated`, `sync-failure`
- ✅ Success: Commit message includes detailed statistics

## 🔄 Comparison with Interactions Sync

| Feature | Interactions | Dosages |
|---------|-------------|---------|
| **Schedule** | 10th monthly | 15th monthly |
| **Data Size** | ~20k records | ~40k records |
| **Timeout** | 2 hours | 3 hours |
| **Validation** | >10k records | >15k records |
| **Table** | `drug_interactions` | `dosage_guidelines` |

## 🎯 Next Steps

1. ✅ Workflow created and ready
2. ⏳ First run scheduled for next 15th
3. 📊 Monitor first automated run
4. 🔧 Adjust batch sizes if needed based on D1 rate limits
5. 📈 Consider adding data quality metrics reporting

---

**Created:** 2025-12-08  
**Author:** Automated Setup  
**Status:** ✅ Ready for Production
