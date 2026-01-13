# Medical Content Validation Guide

## Overview
This guide explains how to verify the medical accuracy of dosage and interaction data in the MediSwitch database.

## Validation Tools

### 1. `validate_medical_content.py`
**Purpose:** Cross-validates dosage data and identifies clinical inconsistencies

**Usage:**
```bash
# Validate top 10 most common ingredients
python3 scripts/validate_medical_content.py

# Validate specific ingredient
python3 scripts/validate_medical_content.py "Paracetamol"
python3 scripts/validate_medical_content.py "Amoxicillin"
```

**What It Checks:**
- ✅ Cross-source agreement (WikEM vs NCBI)
- ✅ Logical consistency (min_dose < max_dose)
- ✅ Dose range reasonability (flags extremely wide ranges)
- ✅ Route compatibility (e.g., IV doses should be smaller than oral)
- ✅ Missing critical data (no dose AND no instructions)
- ✅ Related interactions (drug-drug, drug-food, drug-disease)

## Validation Results Interpretation

### Good Example (Valid Data):
```
💊 Drug: Acetaprofen 100ml susp.
   Concentration: 100ml
   
   📋 Dosage Record #1:
      Source: Hybrid + WikEM
      Route: PO
      WikEM Dose: 800.0 mg
      
   ✅ Has numeric dose
   ✅ Has route specified
   ✅ Reasonable dose for oral administration
```

### Issues to Review:
```
🚨 POTENTIAL ISSUES:
   ❌ No numeric dose AND no text instructions
   ⚠️ Extremely wide dose range (100x+): 5 - 500 mg
   ⚠️ Very high oral dose: 6000 mg
   ❌ Max dose (100) < Min dose (200)
```

## Manual Verification Process

### Step 1: Identify Ingredient to Validate
```bash
# List most common ingredients
sqlite3 assets/database/mediswitch.db "
SELECT ingredient, COUNT(*) as count 
FROM med_ingredients 
GROUP BY ingredient 
ORDER BY count DESC 
LIMIT 20;"
```

### Step 2: Run Validation
```bash
python3 scripts/validate_medical_content.py "ingredient_name"
```

### Step 3: Review Output
Check for:
1. **Source Agreement:** WikEM and NCBI should have similar doses
2. **Dose Ranges:** Should be reasonable for the drug class
3. **Routes:** Should match the drug formulation
4. **Interactions:** Should be clinically relevant

### Step 4: Cross-Reference External Sources
For suspicious findings, verify against:
- **UpToDate** (https://www.uptodate.com)
- **Medscape** (https://reference.medscape.com)
- **FDA Label** (https://dailymed.nlm.nih.gov)
- **BNF** (British National Formulary)
- **WHO Essential Medicines** (https://list.essentialmeds.org)

## Common Data Quality Patterns

### Pattern 1: NCBI-Only Records Without Doses
**Status:** Expected (not an error)
- NCBI provides rich text descriptions but often lacks numeric doses
- The `wikem_instructions` field contains the full protocol text
- These are still clinically useful

### Pattern 2: Multiple Dosage Records for Same Drug
**Status:** Can be valid
- Different routes (IV, PO, IM)
- Different patient populations (pediatric, adult)
- Different indications
- Check that they don't contradict each other

### Pattern 3: Missing Route Information
**Status:** Review needed
- WikEM data usually has routes
- NCBI data may lack standardized routes
- Critical for IV/IM medications

## Red Flags Requiring Manual Review

🚩 **Critical Issues:**
1. Max dose < Min dose (mathematical impossibility)
2. IV dose > 1000mg (unusually large for parenteral)
3. Pediatric dose > Adult dose (for same drug)
4. Dose range spanning >100x (e.g., 1-200mg)

⚠️ **Warning Issues:**
5. No dose data AND no instructions
6. Conflicting routes between sources
7. Very high oral doses (>5000mg)
8. Interaction severity not specified

## Sample Validation Workflow

```bash
# 1. Validate common drugs
for drug in "Paracetamol" "Amoxicillin" "Metformin" "Aspirin"; do
    echo "Validating $drug..."
    python3 scripts/validate_medical_content.py "$drug" >> validation_log.txt
done

# 2. Review generated report
cat medical_validation_report.json | jq '.logical_issues'

# 3. Check cross-source discrepancies
cat medical_validation_report.json | jq '.cross_source_checks'
```

## Automated Checks vs Manual Review

### Automated ✅
- Data completeness
- Mathematical logic
- Format consistency
- Source comparison

### Requires Medical Expertise 👨‍⚕️
- Clinical appropriateness
- Indication-specific dosing
- Special population considerations
- Drug-drug interaction severity
- Contraindication validity

## Recommended Review Schedule

1. **High Priority (Weekly):**
   - Top 50 most prescribed drugs
   - High-risk medications (anticoagulants, antiarrhythmics)
   - Pediatric-specific medications

2. **Medium Priority (Monthly):**
   - Antibiotics, analgesics, antihypertensives
   - Recently added data

3. **Low Priority (Quarterly):**
   - Topical medications, supplements
   - Rarely prescribed drugs

## Contact for Medical Questions
For clinical validation queries, consult:
- Hospital pharmacy team
- Clinical pharmacologists
- Drug information centers
- Manufacturer package inserts

---
**Last Updated:** 2026-01-13
**Version:** 1.0
