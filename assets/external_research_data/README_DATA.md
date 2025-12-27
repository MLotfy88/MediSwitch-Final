# DDInter Data Reassembly Guide

This directory contains automated extracts from DDInter 2.0. Large datasets are split into smaller compressed parts to comply with GitHub's file size limits.

## How to Reassemble the Data

If you see files named `ddinter_v7_part_aa`, `ddinter_v7_part_ab`, etc., you can reassemble the original ZIP bundle using the following command:

### Linux / macOS
```bash
cat ddinter_v7_part_* > ddinter_v7_bundle.zip
unzip ddinter_v7_bundle.zip
```

### Windows (PowerShell)
```powershell
Get-Content ddinter_v7_part_* -Raw | Set-Content ddinter_v7_bundle.zip
# Then extract the zip using your preferred tool
```

## Contents
- `ddinter_exhaustive_v7.json`: Full hierarchical data (includes food, metabolism, and detailed interaction text).
- `ddinter_drugs_metadata_v7.csv`: Granular metadata for the drugs.
- `ddinter_interactions_v7.csv`: Flattened interaction records.
