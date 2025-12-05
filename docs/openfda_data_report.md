# OpenFDA Data Extraction Capabilities Report

Based on the analysis of raw OpenFDA JSON files and the improved extraction logic, here is the exact breakdown of data available for extraction and display in the application.

## 1. Drug Identification (Available & Reliable)
The source drug is clearly identified in the `openfda` section of the record.
- **Brand Name:** Available (e.g., "Advil").
- **Generic Name:** Available (e.g., "Ibuprofen").
- **Substance Name:** Available.
*Reliability: High (Direct field)*

## 2. Interacting Drug (`Ingredient 2`) (Extracted Logic)
OpenFDA **does NOT** provide a specific field for the interacting drug. It is buried within free-text fields.
- **Before Fix:** The script set this to `"multiple"`, making data vague.
- **After Fix:** We now use **Entity Extraction** (matching against 6,400+ known ingredients) to pull specific drug names from the text.
*Reliability: Medium-High (Depends on the completeness of our ingredients list and text clarity).*

## 3. Interaction Description (`Effect`) (Available)
The core data usually comes from these fields:
- `drug_interactions`: Dedicated interaction section.
- `warnings`: General warnings often containing interactions.
- `precautions`: Precautionary measures.
*Changes:* We now merge these, split them into sentences, and select the most descriptive one for display.
*Content:* Typically describes *what* happens (e.g., "May increase risk of bleeding", "Reduces efficacy").

## 4. Severity (`Severity`) (Inferred)
There is **NO** explicit "Severity Level" (Low/Medium/High) field in OpenFDA.
- **Logic:** We estimate it by scanning the description for keywords:
  - **Contraindicated/Avoid:** 🔴 High Risk (Contraindicated)
  - **Severe/Life-threatening:** 🟠 Severe
  - **Major/Significant:** 🟡 Major
  - **Caution/Monitor:** 🔵 Moderate
  - Else: ⚪ Minor
*Note:* This is an estimation, not a clinical classification.

## 5. Management/Recommendation (Embedded)
Clinical recommendations (e.g., "Dose adjustment required", "Monitor INR") are embedded in the `Effect` text. We do not extract them into a separate field currently, but they are displayed as part of the interaction description.

## 6. Unavailable Data
The following fields are generally **NOT** available in a structured format:
- **Interaction Mechanism:** (e.g., CYP3A4 inhibition) - rarely explicit.
- **Onset:** (How fast it happens).
- **Evidence Level:** (Theoretical vs. Established).

## Improved Data Strategy
With the new script, your database will transform from:
- `Aspirin` + `Multiple` (Unknown Severity)
To:
- `Aspirin` + `Warfarin` (Major Severity) - "Increases bleeding risk..."
- `Aspirin` + `Methotrexate` (Severe Severity) - "May increase toxicity..."

This aligns perfectly with professional drug interaction checkers.
