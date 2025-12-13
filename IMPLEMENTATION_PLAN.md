# Implementation Plan - Workflow Separation

## Goal
Separate the unified `extract_drug_data.yml` into two distinct workflows:
1. `extract_interactions.yml`: Standardized, stable extraction for Drug Interactions (DailyMed + OpenFDA).
2. `extract_dosages.yml`: Development-focused extraction for Dosage Data (DailyMed), allowing rapid iteration without re-running heavy interaction logic.

## User Review Required
None. (Direct request from user).

## Proposed Changes

### GitHub Workflows
#### [MODIFY] [.github/workflows/extract_interactions.yml](file:///home/adminlotfy/project/.github/workflows/extract_interactions.yml)
- **Remove:**
    - `Extract DailyMed Dosages` step
    - `Merge results (Dosages)` step
    - `Upload Dosage results` step
    - `Upload merged dosages` step
- **Keep:** All Interaction-related steps (DailyMed + OpenFDA download/extract/merge).

#### [NEW] [.github/workflows/extract_dosages.yml](file:///home/adminlotfy/project/.github/workflows/extract_dosages.yml)
- **Features:**
    - Trigger: `workflow_dispatch` (manual run).
    - Download DailyMed Full Release (reuse script).
    - Run `python3 production_data/extract_dosages_production.py`.
    - Run `python3 scripts/merge_dosages.py`.
    - Upload `merged-dosages` artifact.

## Verification Plan
1. **Push to GitHub**:
    - `git push`
2. **Check Actions Tab**:
    - Verify `Extract Interactions` workflow exists and passes.
    - Verify `Extract Dosages` workflow exists and passes.
3. **Artifact Check**:
    - `merged-interactions.zip` from Interactions workflow.
    - `merged-dosages.zip` from Dosages workflow.
