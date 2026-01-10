---
description: Run WikEM scraper with safety measures and resume support
---

# WikEM Dosage Data Scraper - Complete Workflow

This workflow scrapes ALL dosage data from WikEM.org with anti-ban protection, auto-save, auto-commit, and resume capability.

## Features
✅ Anti-ban protection (User-Agent rotation, random delays)  
✅ Auto-save after each drug  
✅ Git auto-commit every 50 drugs  
✅ Resume from last checkpoint  
✅ Complete structured data extraction (tables, subsections, links)

---

## Prerequisites

```bash
cd /home/adminlotfy/project
pip3 install requests beautifulsoup4
```

---

## Step 1: Get Complete Drug List

Fetch all drug names from WikEM Pharmacology category:

// turbo
```bash
python3 scripts/wikem_scraper/get_drug_list.py > scripts/wikem_scraper/drug_list.txt
```

**What it does:**
- Scrapes Category:Pharmacology page
- Handles pagination
- Saves ~2000+ drug names to `drug_list.txt`

**Verify:**
```bash
wc -l scripts/wikem_scraper/drug_list.txt
head -10 scripts/wikem_scraper/drug_list.txt
```

---

## Step 2: Update Scraper to Use Full List

Modify `scripts/wikem_scraper/scraper.py` (line ~340):

```python
# Replace SAMPLE_DRUGS with:
if __name__ == "__main__":
    with open('scripts/wikem_scraper/drug_list.txt', 'r') as f:
        DRUG_LIST = [line.strip() for line in f if line.strip()]
    
    scraper = WikEMScraper()
    scraper.run(DRUG_LIST)
```

---

## Step 3: Run Full Scraper (Background Mode)

**Option A: Foreground (for testing)**
```bash
python3 scripts/wikem_scraper/scraper.py
```

**Option B: Background (recommended for full run)**
```bash
nohup python3 scripts/wikem_scraper/scraper.py > /tmp/wikem_scraper.log 2>&1 &
echo $! > /tmp/wikem_scraper.pid
```

**Estimated Time:** ~2000 drugs × 5s avg = ~3 hours

---

## Step 4: Monitor Progress

### Real-time Log Monitoring
```bash
tail -f scripts/wikem_scraper/logs/scraper.log
```

### Check Progress
```bash
# Count scraped drugs
ls scripts/wikem_scraper/scraped_data/drugs/ | wc -l

# View checkpoint
cat scripts/wikem_scraper/checkpoints/progress.json | python3 -m json.tool

# Check failed drugs
python3 -c "import json; d=json.load(open('scripts/wikem_scraper/checkpoints/progress.json')); print(f'Scraped: {d[\"total_scraped\"]}, Failed: {d[\"total_failed\"]}')"
```

### Watch Git Commits
```bash
git log --oneline | head -20
```

---

## Step 5: Handle Interruptions

### If Scraper Stops (Ban / Network / Crash)

**Simply re-run:**
```bash
python3 scripts/wikem_scraper/scraper.py
```

**What happens:**
1. Reads checkpoint file
2. Skips all processed drugs
3. Continues from where it stopped
4. **Zero data loss!**

### If You Got Banned (403 Errors)

Wait 30 minutes, then:

1. Increase delays in `scraper.py`:
```python
MIN_DELAY = 5  # Increase from 3
MAX_DELAY = 12  # Increase from 8
```

2. Resume:
```bash
python3 scripts/wikem_scraper/scraper.py
```

---

## Step 6: Verify Complete Data

After scraping completes:

```bash
# Total drugs scraped
ls scripts/wikem_scraper/scraped_data/drugs/ | wc -l

# Check for tables (antibiotic sensitivities)
grep -r '"tables"' scripts/wikem_scraper/scraped_data/drugs/ | grep -v ': \[\]' | wc -l

# Check for contextual dosing (subsections)
grep -r '"subsections"' scripts/wikem_scraper/scraped_data/drugs/ | grep -v ': {}' | wc -l

# Sample drug with full structure
cat scripts/wikem_scraper/scraped_data/drugs/Vancomycin.json | python3 -m json.tool | less
```

---

## Troubleshooting

### Scraper Hangs
```bash
# Check if process is running
ps aux | grep scraper.py

# If frozen, kill and restart
kill $(cat /tmp/wikem_scraper.pid)
python3 scripts/wikem_scraper/scraper.py
```

### Git Commit Failures
```bash
# Check git status
git status

# Manual commit if needed
git add scripts/wikem_scraper/scraped_data/
git commit -m "WikEM scraping progress"
```

### Empty Sections
This is normal - not all drugs have all sections (e.g., antibiotics-only sections)

---

## Final Output Structure

```
scripts/wikem_scraper/
├── scraped_data/
│   └── drugs/
│       ├── Metronidazole.json (3.4KB)
│       ├── Vancomycin.json (4.5KB)
│       ├── ... (2000+ files)
│       └── Warfarin.json (2.0KB)
├── checkpoints/
│   └── progress.json
├── logs/
│   └── scraper.log
├── drug_list.txt
├── scraper.py
└── get_drug_list.py
```

---

## Safety Measures Active

✅ **User-Agent Rotation** (8 different browsers)  
✅ **Random Delays** (3-8 seconds between requests)  
✅ **Exponential Backoff** (on 403/429 errors)  
✅ **Checkpoint System** (resume capability)  
✅ **Auto-Save** (every drug)  
✅ **Auto-Commit** (every 50 drugs)  
✅ **Comprehensive Logging**

---

## Next Steps After Scraping

1. **Transform to SQLite:**
   - Parse JSON files
   - Insert into `mediswitch.db` structured_dosage column
   - Compress with ZLIB

2. **Split Database:**
   ```bash
   python3 scripts/split_db.py
   ```

3. **Deploy to App**
