# TTD-IDRBLab Dosage Data Migration Plan

## 1. Objective
Replace the current unstructured/random dosage data with high-quality, structured dosage guidelines from the **TTD-IDRBLab** dataset. This ensures accurate dosage information for both the **Dosage Tab** (Drug Details) and the **Dosage Calculator**.

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
