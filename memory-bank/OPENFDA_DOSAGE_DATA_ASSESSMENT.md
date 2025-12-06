# OpenFDA Dosage Data Availability Assessment

**Date:** 2025-12-06  
**Purpose:** Evaluate OpenFDA data for Dose Calculator feature implementation

---

## ✅ Data Available in OpenFDA Drug Labels

### Confirmed Fields with Dosage Information

Based on OpenFDA's `drug/label` endpoint documentation, the following fields contain dosage-related data:

1. **`dosage_and_administration`** (Array of strings)
   - Primary source for dosing instructions
   - Contains free-form text with:
     - Recommended doses for different patient populations
     - Route of administration
     - Frequency and timing
     - Special instructions (with/without food, etc.)
   - **Example use cases:**
     - Adult standard dose
     - Pediatric dose calculations
     - Renal/hepatic dose adjustments

2. **`pediatric_use`** (Array of strings)
   - Age-specific pediatric dosing
   - Weight-based calculations
   - Safety information for children

3. **`geriatric_use`** (Array of strings)
   - Elderly-specific dosing considerations
   - Dose adjustments for older adults

4. **`indications_and_usage`** (Array of strings)
   - Context for when specific doses apply
   - Condition-specific dosing

5. **`dosage_forms_and_strengths`** (Array of strings)
   - Available strengths (e.g., "250mg", "500mg")
   - Form types (tablet, suspension, injection)
   - Critical for calculating actual doses

6. **`active_ingredient`** (Array of objects)
   - `name`: Active ingredient name
   - `strength`: Concentration/amount per unit

---

## 🎯 Potential Use Cases for Dose Calculator

### 1. Basic Dose Lookup
- Extract standard adult doses from `dosage_and_administration`
- Display available strengths from `dosage_forms_and_strengths`
- Show route-specific instructions

### 2. Pediatric Dose Calculator (Weight-Based)
- Parse pediatric dosing formulas from `pediatric_use`
- Example patterns to extract:
  - "10-15 mg/kg/day divided into 2 doses"
  - "Maximum: 2000 mg/day"
  - "Infants: 20 mg/kg every 8 hours"

### 3. Renal/Hepatic Adjustment Calculator
- Extract dose modification rules
- Example: "CrCl \u003c 30 mL/min: Reduce dose by 50%"

---

## ⚠️ Challenges & Limitations

### 1. **Unstructured Text Format**
- Data is in free-form text arrays, not structured fields
- Requires Natural Language Processing (NLP) or regex parsing
- High variation in formatting across different manufacturers

### 2. **Extraction Complexity**
Patterns to handle:
```
"Adults: 500 mg twice daily"
"Children 6-12 years: 250 mg every 12 hours"
"10-15 mg/kg/day in 2-3 divided doses"
"Weight \u003c 40 kg: 20 mg/kg; Weight ≥ 40 kg: 750 mg"
```

### 3. **Completeness Issues**
- Not all drugs have complete dosage information
- Some entries may be missing critical fields
- Data quality depends on manufacturer submission

### 4. **Update Frequency**
- OpenFDA data is updated regularly but not real-time
- Egyptian drug database may have different formulations

---

## 📋 Implementation Plan for Dose Calculator

### Phase 1: Data Extraction (New Script)
Create: `scripts/dosage/extract_dosage_from_openfda.py`

**Goals:**
1. Download drug label files (same as interaction script)
2. Extract dosage-related fields:
   - `dosage_and_administration`
   - `pediatric_use`
   - `geriatric_use`
   - `dosage_forms_and_strengths`
   - `active_ingredient`
3. Store in structured format:
```json
{
  "drug_name": "Amoxicillin",
  "active_ingredient": "Amoxicillin",
  "strengths": ["250mg", "500mg"],
  "adult_dose": {
    "text": "500 mg every 8 hours or 875 mg every 12 hours",
    "parsed": {
      "amount": [500, 875],
      "unit": "mg",
      "frequency": ["every 8 hours", "every 12 hours"]
    }
  },
  "pediatric_dose": {
    "text": "20-40 mg/kg/day in divided doses every 8 hours",
    "parsed": {
      "mg_per_kg": [20, 40],
      "frequency": "every 8 hours",
      "max_daily": null
    }
  }
}
```

### Phase 2: Parsing Rules
Implement regex patterns for common dose formats:
- Fixed doses: "500 mg", "1-2 tablets"
- Weight-based: "10-15 mg/kg/day", "20 mg/kg"
- Frequency: "twice daily", "every 8 hours", "q12h"
- Max doses: "Maximum: 2000 mg/day"
- Conditionals: "If weight \u003c 40kg: X, else: Y"

### Phase 3: Matching with Egyptian Database
**Challenge:** OpenFDA uses US trade names, our database has Egyptian names

**Solution:**
1. Match by **active ingredient** (generic name)
2. Use ingredient normalization:
   - "Amoxicillin + Clavulanic Acid" → components
   - Handle different salt forms
3. Store dosage info as supplementary data

### Phase 4: Flutter Implementation
Update Dose Calculator UI to:
1. Search drug by name
2. Select patient type:
   - Adult
   - Pediatric (with weight input)
   - Elderly
   - Renal impairment
3. Display:
   - Recommended dose
   - Available strengths
   - Instructions
   - Warnings

---

## 🔄 Integration with Existing System

### Data Flow:
1. **OpenFDA Script** extracts dosage data → JSON file
2. **Backend Script** matches with Egyptian drugs → D1 database
3. **Flutter App** fetches dosage info via API or local SQLite
4. **Dose Calculator UI** displays interactive calculator

### Database Schema Addition:
```sql
CREATE TABLE drug_dosage (
  id INTEGER PRIMARY KEY,
  drug_id INTEGER REFERENCES drug(id),
  active_ingredient TEXT,
  adult_dose_text TEXT,
  adult_dose_parsed JSON,
  pediatric_dose_text TEXT,
  pediatric_dose_parsed JSON,
  geriatric_considerations TEXT,
  special_populations JSON,
  source TEXT DEFAULT 'openFDA',
  last_updated TIMESTAMP
);
```

---

## ✅ Recommendation

**YES, OpenFDA data CAN be used for Dose Calculator**, but with important caveats:

### Feasibility: ⭐⭐⭐⭐☆ (4/5)
- ✅ Data exists and is comprehensive
- ✅ Covers adult, pediatric, geriatric dosing
- ⚠️ Requires significant parsing effort
- ⚠️ Match rate with Egyptian database uncertain

### Priority Level: 🟡 MEDIUM-HIGH
- Adds significant value to app
- Differentiates from basic drug lookup apps
- Aligns with "medical professional tool" positioning

### Suggested Approach:
1. **MVP:** Extract and display raw text from OpenFDA
2. **V2:** Implement smart parsing for common patterns
3. **V3:** Add interactive calculator with patient parameters

---

## 📝 Next Steps

1. **Update Task List** in `progress.md`:
   - Add "OpenFDA Dosage Extraction" task
   - Add "Dose Calculator Data Integration" subtask

2. **Create Extraction Script**:
   - Based on existing `download_and_extract_openfda.py`
   - Focus on dosage fields instead of interactions

3. **Prototype Matching Algorithm**:
   - Test matching OpenFDA → Egyptian drugs
   - Calculate expected coverage percentage

4. **Design UI Mock**:
   - Dose calculator interface
   - Weight-based calculator for pediatrics

---

**Status:** ✅ Confirmed - Data available and viable  
**Effort Estimate:** ~3-5 days for basic extraction + matching  
**Impact:** High - Professional-grade feature
