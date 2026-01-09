# TTD-IDRBLab Dosage Data Migration Plan (UPDATED)

**Last Updated:** 2026-01-09  
**Status:** Analysis Phase Completed ✅

## 1. Objective
Replace the current unstructured/random dosage data with high-quality, structured dosage guidelines from the **TTD-IDRBLab** dataset. This ensures accurate dosage information for both the **Dosage Tab** (Drug Details) and the **Dosage Calculator**.

## 2. Data Source Analysis ✅

### TTD-IDRBLab Files Available:
1. **`P1-02-TTD_drug_download.txt`** (262,456 lines)
   - **Content:** 42,938 drugs with metadata
   - **Format:** Tab-delimited raw format (DRUG_ID + FIELD_NAME + VALUE)
   - **Key Fields:** TRADNAME, DRUGTYPE, THERCLAS, HIGHSTAT
   - **Status:** ✅ Successfully parsed

2. **`P1-04-Drug_synonyms.txt`** (330,283 lines)
   - **Content:** 299,548 synonyms for 30,715 drugs
   - **Format:** Tab-delimited
   - **Usage:** Improve matching rate
   - **Status:** ✅ Successfully parsed

3. **`P1-05-Drug_disease.txt`** (101,490 lines)
   - **Content:** Disease indications with ICD-11 codes
   - **Format:** Special multi-line format (TTDDRUAID → DRUGNAME → INDICATI)
   - **Status:** ⚠️ Parser needs fixing (currently returns 0 indications)

### Local Database Statistics:
- **Total Medicines:** 25,535 (from `meds.csv`)
- **Unique Active Ingredients:** 7,443
- **Medicines with `concentration` Data:** 18,519 (72.5%)
- **Database Location:** `/home/adminlotfy/project/assets/database/mediswitch.db`

## 3. Critical Finding: **Zero Matches** ❌

### Problem Analysis:
The initial matching attempt yielded **0 matches** between TTD and local database due to:

1. **Nomenclature Mismatch:**
   - TTD uses **international drug names** (e.g., "Ibrance", "Acetaminophen")
   - Local DB uses **Egyptian trade names** (e.g., "بنادول", "Panadol")
   
2. **Missing Ingredient Linkage:**
   - TTD files **don't explicitly list active ingredients as a separate field**
   - We need to **infer** ingredients from TRADNAME or use external mapping
   
3. **P1-05 Parsing Issue:**
   - Current parser cannot handle the multi-line INDICATI format
   - This file is **critical** as it contains dosage-related disease indications

## 4. Revised Implementation Strategy

### Phase 1: Fix Data Parsing (CURRENT) 🔄

#### A. Fix P1-05 Parser
**Issue:** The file format is:
```
TTDDRUAID        DZB84T          
DRUGNAME        Maralixibat             
INDICATI        Pruritus        ICD-11: EC90    Approved
INDICATI        Progressive familial...  ICD-11: 5C58.03 Phase 3
```

**Solution:** Parse INDICATI lines that contain dosage-relevant information

#### B. Create Enhanced Matching Strategy
Since direct name matching fails, use **multi-strategy matching**:

1. **Strategy 1: ATC Code Matching**
   - Both databases have `atc_codes` column
   - Match via ATC classification codes
   
2. **Strategy 2: Fuzzy Text Matching**
   - Use `fuzzywuzzy` or `rapidfuzz` to match drug names
   - Threshold: 85% similarity
   
3. **Strategy 3: Manual Mapping File**
   - Create `ttd_to_local_mapping.json` for common drugs
   - E.g., `{"D0U5QK": ["Panadol", "Abimol", "Paracetamol 500mg"]}`

### Phase 2: Build `med_ingredients` Table

**Current State:** Table doesn't exist in `/assets/database/mediswitch.db`

**Action:** Create it from `meds.csv` column `active`:
```sql
CREATE TABLE med_ingredients (
    med_id INTEGER,
    ingredient TEXT COLLATE NOCASE,
    PRIMARY KEY (med_id, ingredient)
);

-- Populate from drugs table
INSERT INTO med_ingredients (med_id, ingredient)
SELECT id, LOWER(TRIM(active))
FROM drugs
WHERE active IS NOT NULL AND active != '';
```

### Phase 3: Dosage Data Extraction

#### TTD Data Limitations Discovered:
- ⚠️ **TTD does NOT contain detailed dosage instructions** in P1-02
- The files focus on **drug-disease relationships** and **approval status**
- **Dosage information** (if any) is embedded in INDICATI field of P1-05

#### Alternative Approach:
Since TTD lacks detailed dosages, we need to:
1. Use **DailyMed** as primary dosage source (existing integration)
2. Use **TTD P1-05** for **disease-specific contraindications** only
3. Leverage **local concentration** data for calculator precision

### Phase 4: Schema Updates

**Current `dosage_guidelines` schema:**
```sql
id, med_id, dailymed_setid, min_dose, max_dose, frequency, duration, 
instructions, condition, source, is_pediatric, route, updated_at
```

**Proposed additions:**
1. `disease_icd_code` TEXT - For filtering by specific conditions
2. `ttd_drug_id` TEXT - Link to TTD reference
3. `contraindication_flag` INTEGER - Mark unsafe drug-disease combinations

### Phase 5: Calculator Integration

**Leverage `concentration` Column:**
- **Purpose:** Convert generic dosage (mg/day) to product-specific units (tablets)
- **Example:**
  - TTD/DailyMed: "Paracetamol 1000mg every 6 hours"
  - Local DB: "Panadol 500mg tablet"
  - **Calculator Output:** "2 tablets every 6 hours"

**Implementation:**
```python
# Pseudo-code
target_dose_mg = 1000  # from dosage_guidelines
product_strength_mg = parse_concentration("500mg")  # from drugs.concentration
tablets_needed = target_dose_mg / product_strength_mg  # = 2
```

## 5. Quality Assurance Plan

### Stage 1: Data Validation ✅
- [x] TTD files successfully parsed
- [x] Local CSV loaded (25,535 medicines)
- [x] Concentration column analyzed (72.5% coverage)
- [ ] Fix P1-05 parser
- [ ] Implement ATC code matching

### Stage 2: Matching Verification
- [ ] Run matching with multiple strategies
- [ ] Generate sample report of top 100 matches
- [ ] Manual review for accuracy

### Stage 3: Integration Testing
- [ ] Update dosage_guidelines table schema
- [ ] Populate with matched data
- [ ] Test Dosage Tab UI
- [ ] Test Mini Calculator with real concentration data

## 6. Next Steps (Prioritized)

1. ✅ **Complete initial analysis** (DONE)
2. 🔄 **Fix P1-05 parser** (IN PROGRESS)
3. ⏳ **Implement ATC-based matching**
4. ⏳ **Create `med_ingredients` table in database**
5. ⏳ **Build dosage extraction logic**
6. ⏳ **Update schema and populate data**
7. ⏳ **Test and verify**

## 7. Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Low matching rate | High | Use multiple matching strategies (ATC, fuzzy, manual) |
| TTD lacks detailed dosages | High | Continue using DailyMed as primary source |
| Concentration data missing (27.5%) | Medium | Extract from trade_name using regex |
| Schema changes break app | Medium | Test in development environment first |

## 8. Success Metrics

- **Target Matching Rate:** ≥30% of local medicines matched to TTD
- **Dosage Coverage:** ≥50% of medicines have structured dosage data
- **Calculator Accuracy:** 95% correct tablet calculations using concentration
- **Zero Breaking Changes:** All existing functionality preserved

---

**Notes:**
- TTD is more valuable for **drug-disease relationships** than raw dosages
- **DailyMed + Local Concentration** is the winning combination for calculator
- This migration is about **enrichment**, not replacement


## 2. Data Source Analysis
We will utilize the following files from `/home/adminlotfy/project/External_source/TTD-IDRBLab`:
1.  **`P1-02-TTD_drug_download.txt`**: Primary source for Dosage info, Route, Indication, and Dosage Form.
2.  **`P1-05-Drug_disease.txt`**: Connects drugs to specific ICD-coded diseases (for disease-specific dosage adjustments).
3.  **`P1-04-Drug_synonyms.txt`**: Used to improve the matching rate of active ingredients.

## 3. Implementation Strategy

### A. Drug Linking (Ingredient Matching)
*   **Method**: We will match TTD drugs to our local database via **Active Ingredients**.
*   **Reference Table**: `med_ingredients` (Local DB).
*   **Process**:
    1.  Extract unique ingredients from TTD (`Drug Name` & `Synonyms`).
    2.  Normalize strings (lowercase, trim, remove salts like "hydrochloride").
    3.  Match against `med_ingredients.ingredient` column.
    4.  Store `med_id` mappings for all matches.
    *   *Note: This mirrors the successful strategy used for DDInter interactions.*

### B. Schema Updates (`dosage_guidelines` Table)
To fully utilize the rich TTD data (especially disease-specific safety), we need to expand the `dosage_guidelines` table.

**Current Columns:**
`id`, `med_id`, `min_dose`, `max_dose`, `frequency`, `duration`, `instructions`, `condition`, `is_pediatric`, `route`, `source`

**Proposed New Columns (if not already present):**
1.  `disease_id` (TEXT): To store the ICD code (e.g., from `P1-05`), allowing precise filtering in the calculator.
2.  `contraindication_flag` (INTEGER): If the guideline is actually a "Do Not Use" warning for a specific disease.
3.  `required_monitoring` (TEXT): If TTD mentions monitoring parameters (e.g., "Monitor BP").

### C. Data Extraction & Parsing (Python Script)
A robust Python script will be developed to parse the semi-structured text fields.

**Target Fields & Logic:**
1.  **Dosage/Strength**:
    *   **Input**: "50-100 mg orally every 6 hours"
    *   **Regex**: Extract numerical range (`50-100`), unit (`mg`), frequency (`every 6 hours` -> converted to numeric `4` times/day if possible).
    *   **Output**: `min_dose=50`, `max_dose=100`, `unit='mg'`, `frequency=4`, `route='Oral'`.
2.  **Indication/Condition**:
    *   Input comes from `Indication` column in TTD or `Disease Name` in `P1-05`.
    *   Stored in `condition` column.
3.  **Pediatric Detection**:
    *   Keyword search in indication/dosage text: `['child', 'infant', 'pediatric', 'kg', 'lb', 'years']`.
    *   If found -> `is_pediatric = 1`.

### D. Leveraging Local `concentration` Data
*   **Context**: The local database (and `assets/meds.csv`) already contains a `concentration` column, extracted from the trade name (e.g., "Panadol 500mg" -> Concentration: "500mg").
*   **Crucial Role**:
    *   **TTD Data** provides the *Target Dosage* (e.g., "Adults: 1000 mg per day").
    *   **Local Data** provides the *Product Strength* (e.g., "500 mg per tablet").
    *   **Calculator Logic**: `Tablets Needed = Target Dosage / Product Strength`.
*   **Action Plan**:
    1.  Ensure the `concentration` column in the local DB is clean and standardized (parsed into numeric value + unit during the migration or runtime).
    2.  The Dosage Calculator must read this local `concentration` field to display results in user-friendly units (e.g., "2 Tablets" instead of just "1000 mg").
    3.  This ensures the **Mini Dosage Calculator** in the drug details tab is accurate for the specific *product* being viewed, not just the generic drug.

### E. Integration with App Logic
1.  **Dosage Detail Tab**:
    *   Display the clean textual instructions (`instructions`).
    *   Show `condition` clearly (e.g., "For Hypertension: ...").
    *   Highlight specific disease adjustments.
2.  **Dosage Calculator**:
    *   Logic will primarily use `min_dose`, `max_dose`, and `unit` columns.
    *   Ideally, the calculator will allow users to select a "Condition" from a dropdown (populated from the `condition` column) to get the specific dose for that disease.

## 4. Quality Assurance Steps
1.  **Pre-Process Check**: Run the script in "dry-run" mode to generate a CSV sample of 100 drugs.
2.  **Manual Verification**: Review the sample to ensure regex didn't misinterpret "50 mg" as "50 tablets".
3.  **Database Integrity**: Ensure no orphan records (dosages with no matching `med_id`).
4.  **App Testing**: Verify correct display in RTL (Arabic) and LTR modes.

## 5. Next Steps
1.  Confirm schema changes (Add `disease_id` column?).
2.  Write the Python parser script.
3.  Run the migration and verify.
