# 🚀 GitHub Workflow Guide - Drug Data Extraction

## 📋 Steps to Execute

### 1. Prepare Repository
```bash
# Ensure .gitignore excludes large files
git add .
git commit -m "Add drug data extraction workflow and scripts"
git push
```

### 2. Trigger Workflow

**On GitHub:**
1. Go to **Actions** tab
2. Click **Extract Drug Data** workflow
3. Click **Run workflow** dropdown
4. Select:
   - **Branch**: main (or your branch)
   - **Data source**: `both` ✅
5. Click **Run workflow** button

### 3. Monitor Progress

The workflow will:
- ⏱️ Take ~1-2 hours (Full Release is ~12GB)
- Download all 5 DailyMed parts automatically
- Extract interactions from both sources
- Merge and deduplicate results

**Check progress:**
- Click on the running workflow
- Expand steps to see live logs
- Look for extraction statistics

### 4. Download Results

After completion:
1. Scroll to **Artifacts** section (bottom of workflow page)
2. Download:
   - `dailymed-interactions` (DailyMed only)
   - `openfda-interactions` (OpenFDA only)
   - `merged-interactions` ✅ (Final combined result)

### 5. Use the Data

```bash
# Unzip downloaded artifact
unzip merged-interactions.zip

# You'll get: production_data/interactions_merged.json
# Expected: 5,000-10,000 unique drug interactions
```

## 📊 Expected Results

```json
{
  "ingredient1": "warfarin",
  "ingredient2": "aspirin",
  "severity": "major",
  "severity_confidence": 0.9,
  "effect": "Concurrent use increases bleeding risk...",
  "recommendation": "Monitor INR closely if coadministered.",
  "source": "DailyMed",
  "confidence_score": 0.85
}
```

## ⚙️ Configuration

All configurable in `.github/workflows/extract_drug_data.yml`:
- Timeout: `180` minutes (3 hours)
- Artifact retention: `30-90` days
- Can run manually or schedule weekly

## 🔧 Troubleshooting

**Workflow fails with timeout:**
- Increase `timeout-minutes` in workflow file
- Or process fewer parts (comment out part4,part5)

**Out of disk space:**
- GitHub Actions runners have ~14GB free
- Full Release ~12GB fits, but tight
- Consider processing parts separately

**Download fails:**
- DailyMed servers may be slow
- Retry the workflow
- Or download locally and upload to release

## 📝 Next Steps After Extraction

1. Import to D1 database
2. Create API endpoints
3. Integrate with Flutter app
4. Test interaction checker feature

---

**Ready to run!** �
