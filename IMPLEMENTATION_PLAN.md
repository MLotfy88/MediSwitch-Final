# Implementation Plan - Full DailyMed Extraction & Integration

## Goal
Establish a foundational "Data Lake" by extracting the **entire** DailyMed Human Prescription Drug dataset (metadata, product details, clinical text, and NDCs) into a unified structure. This allows flexible downstream filtering (e.g., for Dosage Calculator) without re-parsing 12GB+ of XMLs every time.

## User Context
- **Existing App Data:** Uses `scraper.py` to extract concentrations from trade names via Regex.
- **Strategy:**
    1. Extract **Full DailyMed Data** first.
    2. Create a separate workflow to **Filter & Process** specific needs (Dosages, Safety) from this master dataset.
    3. Leverage DailyMed's **structured strength** (superior to regex) while maintaining compatibility.

## Proposed Changes

### 1. Data Extraction Script (New)
#### [NEW] [production_data/extract_full_dailymed.py](file:///home/adminlotfy/project/production_data/extract_full_dailymed.py)
- **Scope:** Extract ALL relevant data points per drug.
- **Data Points:**
    - **Metadata:** SetID, Version, Title.
    - **Product Specs:**
        - Proprietary Name
        - Non-Proprietary Name (Generic)
        - **Active Ingredients & Strengths** (Structured text + XML values)
        - Dosage Form
        - **NDC Codes** (Crucial for linking with external databases)
    - **Clinical Sections (LOINC):**
        - Boxed Warning
        - Indications & Usage
        - Dosage & Administration
        - Pediatric Use
        - Geriatric Use
        - Pregnancy & Lactation
        - Renal & Hepatic Impairment
        - Contraindications
        - Warnings & Precautions
        - Adverse Reactions
        - Drug Interactions

### 2. GitHub Workflow (New)
#### [NEW] [.github/workflows/extract_full_data.yml](file:///home/adminlotfy/project/.github/workflows/extract_full_data.yml)
- **Triggers:** Manual (`workflow_dispatch`), Weekly Schedule.
- **Steps:**
    1. Download DailyMed Full Release (5 Parts).
    2. Run `extract_full_dailymed.py`.
    3. Upload artifact: `dailymed_full_database.json.zip` (Compressed).

### 3. Integration Strategy (Data Enrichment)
- **Strength/Concentration:**
    - Primary: Use DailyMed structured XML (e.g., `numerator: 100 mg`, `denominator: 5 mL`).
    - Fallback: Apply the user's `CONCENTRATION_REGEX` on the product name.
- **Linking:**
    - Use **Active Ingredient** and **Dosage Form** to match with `dwaprices` data.

## Verification Plan
1. **Local Pilot:**
    - Run `extract_full_dailymed.py` on a single DailyMed ZIP part (or sample).
    - Inspect output JSON for completeness of all new fields.
2. **Workflow Test:**
    - Push to GitHub.
    - Run workflow.
    - Download `dailymed_full_database.json.zip`.
    - Check file size and JSON structure.
