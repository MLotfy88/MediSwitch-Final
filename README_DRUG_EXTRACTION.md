# Drug Data Extraction from Free Sources

This repository contains scripts to extract high-quality drug interaction and dosage data from free FDA sources.

## 🎯 Purpose

Extract production-grade pharmaceutical data for the MediSwitch app:
- ✅ Drug-drug interactions with real drug names
- ✅ Severity classifications
- ✅ Clinical recommendations
- ✅ Proper formatting and validation

## 📦 Data Sources

1. **DailyMed** (FDA SPL files) - Primary for interactions
2. **OpenFDA** (preprocessed FDA data) - Supplementary

## 🚀 GitHub Actions Workflow

### Manual Trigger

Go to **Actions** → **Extract Drug Data** → **Run workflow**

Choose:
- `dailymed_interactions` - Extract from DailyMed only
- `openfda_interactions` - Extract from OpenFDA only  
- `both` - Extract and merge from both sources (recommended)

### Outputs

Download artifacts after workflow completes:
- `dailymed-interactions` - DailyMed results
- `openfda-interactions` - OpenFDA results
- `merged-interactions` - Combined and deduplicated results

## 📁 File Structure

```
├── .github/workflows/
│   └── extract_drug_data.yml          # Main workflow
├── scripts/
│   ├── download_dailymed.py           # Download DailyMed data
│   └── merge_interactions.py           # Merge multiple sources
├── production_data/
│   ├── extract_dailymed_interactions.py    # DailyMed extractor
│   ├── extract_interactions_production.py  # OpenFDA extractor
│   └── known_ingredients.json              # Pharmaceutical database
└── requirements.txt                    # Python dependencies
```

## ⚙️ Local Testing (Optional)

```bash
# Install dependencies
pip install -r requirements.txt

# Download data
python3 scripts/download_dailymed.py

# Extract DailyMed interactions
python3 production_data/extract_dailymed_interactions.py

# Results in: production_data/dailymed_interactions_clean.json
```

## 📊 Expected Results

From both sources combined:
- **~5,000-10,000** unique drug-drug interactions
- **Real drug names** (not "other medicine")
- **Severity levels**: Contraindicated, Severe, Major, Moderate, Minor
- **Quality validated**: Confidence scores 0.7-1.0
- **Properly formatted**: Clean text, proper capitalization

## ⚠️ Important Notes

- Large data files (~12GB) are in `.gitignore`
- GitHub Actions downloads data automatically
- Workflow timeout: 3 hours max
- Results are cached for 30-90 days

## 📝 Next Steps After Extraction

1. Download merged results from GitHub Actions artifacts
2. Import into D1 database
3. Integrate with Flutter app
4. Test with real queries

---

**Status**: ✅ Ready for production use

**Last Updated**: December 2025
