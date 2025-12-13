# Implementation Plan - Phase 2 (Cloud Processing Strategy)

## Problem
The "Data Lake" file (290MB) is too large to easily transfer between GitHub and the user's local machine given current bandwidth/tool constraints.

## Solution: Cloud Processing
Instead of bringing the data to the code, we will **send the code to the data**.
We will update the GitHub Workflow to run the "Filtering & Enrichment" script (`process_datalake.py`) directly on the GitHub Runner immediately after extraction.

## Changes Required

### 1. Version Control
- **Add File:** `meds_updated.csv` (App Database) to git repository.
  - *Constraint:*  Must be < 100MB. (Verified: It is likely small text).

### 2. GitHub Workflow
#### [MODIFY] [.github/workflows/extract_full_data.yml](file:///home/adminlotfy/project/.github/workflows/extract_full_data.yml)
- **Add Step:** Run `python3 scripts/process_datalake.py` after extraction.
- **Update Artifacts:**
    - Upload `production_data/dosages_final.json` (The "Gold" file).
    - Keep `dailymed_full_database.json.zip` as a backup (optional, or remove to save space).

### 3. Script Adjustments
- Ensure `process_datalake.py` points to the correct paths in the CI environment (it already uses relative paths `production_data/...`, so it should work).

## Execution Steps
1. Commit `meds_updated.csv`, `scripts/process_datalake.py`.
2. Update `extract_full_data.yml`.
3. Push to GitHub.
4. User triggers workflow.
5. User downloads `dosages-final.zip` (Estimated size: ~10-20MB).
