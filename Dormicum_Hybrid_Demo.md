# 💊 Dormicum (Midazolam) - Hybrid Data Demo

This document demonstrates the **Hybrid Approach**: using OpenFDA tables for UI display and extracted data for the Dosage Calculator.

## 📱 1. UI Display (For Doctor/User)
These tables are fetched directly from OpenFDA's `dosage_and_administration_table` field.
They provide the structure and clarity required for the 'Drug Details' tab without complex parsing.

### Table 1: (Raw HTML - Rendering library missing)
> Note: visualization library issue: Missing optional dependency 'lxml'.  Use pip or conda to install lxml.
```html
<table width="100%"><col width="34.750%" align="left"/><col width="65.250%" align="left"/><tbody><tr><td colspan="2" align="left" styleCode="Toprule" valign="top"><content styleCode="bold">USUAL ADULT DOSE</content></td></tr><tr><td align="left" valign="top">INTRAMUSCULARLY    For preoperative sedation/anxiolysis/ amnesia (induction of sleepiness or drowsiness and relief of apprehension and to impair memory of perioperative events).    For intramuscular use, midazolam hydrochloride should be injected deep in a large muscle mass. </td><td align="left" valign="top">   The recommended premedication dose of midazolam for good risk (ASA Physical Status I &amp; II) adult patients below the age of 60 years is 0.07 to 0.08 mg/kg IM (approximately 5 mg IM) administered up to 1 hour before surgery.    The dose must be individualized and reduced when IM midazolam is administered to patients with chronic obstructive pulmonary disease, other higher risk surgical patients, patients 60 or more years ... (truncated)
```

### Table 2: (Raw HTML - Rendering library missing)
> Note: visualization library issue: Missing optional dependency 'lxml'.  Use pip or conda to install lxml.
```html
<table width="100%"><col width="27.906%" align="left"/><col width="19.504%" align="left"/><col width="17.544%" align="left"/><col width="21.264%" align="left"/><col width="13.783%" align="left"/><tbody><tr><td colspan="5" align="center" styleCode="Botrule Lrule Rrule" valign="top">OBSERVER&apos;S ASSESSMENT OF ALERTNESS/SEDATION (OAA/S)</td></tr><tr><td colspan="5" align="center" styleCode="Botrule Lrule Rrule" valign="top">Assessment Categories</td></tr><tr><td align="center" styleCode="Botrule Lrule Rrule" valign="top"><content styleCode="bold"><content styleCode="underline">Responsiveness</content></content></td><td align="center" styleCode="Botrule Rrule" valign="top"><content styleCode="bold"><content styleCode="underline">Speech</content></content></td><td align="center" styleCode="Botrule Rrule" valign="top"><content styleCode="bold"><content styleCode="underline">Facial Expression</content></content></td><td align="center" styleCode="Botrule Rrule" valign="top"><content styleCo... (truncated)
```

### Table 3: (Raw HTML - Rendering library missing)
> Note: visualization library issue: Missing optional dependency 'lxml'.  Use pip or conda to install lxml.
```html
<table width="100%"><col width="14.688%" align="left"/><col width="13.673%" align="left"/><col width="17.345%" align="left"/><col width="12.859%" align="left"/><col width="13.573%" align="left"/><col width="14.288%" align="left"/><col width="13.573%" align="left"/><tbody><tr><td colspan="7" align="center" styleCode="Botrule Lrule Rrule Toprule" valign="top">FREQUENCY OF OBSERVER&apos;S ASSESSMENT OF   ALERTNESS/SEDATION COMPOSITE SCORES IN ONE STUDY OF   CHILDREN UNDERGOING PROCEDURES WITH INTRAVENOUS   MIDAZOLAM FOR SEDATION </td></tr><tr><td align="center" styleCode="Botrule Lrule Rrule" valign="top">Age Range   (years) </td><td align="center" styleCode="Botrule Rrule" valign="top">n</td><td colspan="4" align="center" styleCode="Botrule Rrule" valign="top">OAA/S Score</td><td align="left" styleCode="Botrule Rrule" valign="top"/></tr><tr><td align="center" styleCode="Botrule Lrule Rrule" valign="top"/><td align="center" styleCode="Botrule Rrule" valign="top"/><td align="center" styleC... (truncated)
```

### Table 4: (Raw HTML - Rendering library missing)
> Note: visualization library issue: Missing optional dependency 'lxml'.  Use pip or conda to install lxml.
```html
<table width="100%"><col width="34.750%" align="left"/><col width="65.250%" align="left"/><tfoot><tr styleCode="First Last"><td colspan="2" align="left" valign="top"><paragraph styleCode="First Footnote"><content styleCode="italics">Note:</content>Parenteral drug products should be inspected visually for particulate matter and discoloration prior to administration, whenever solution and container permit. </paragraph></td></tr></tfoot><tbody><tr><td align="left" styleCode="Toprule" valign="top">INTRAMUSCULARLY    For sedation/anxiolysis/amnesia prior to anesthesia or for procedures, intramuscular midazolam can be used to sedate pediatric patients to facilitate less traumatic insertion of an intravenous catheter for titration of additional medication. </td><td align="left" styleCode="Toprule" valign="top">  USUAL PEDIATRIC DOSE (NON-NEONATAL)    Sedation after intramuscular midazolam is age and dose dependent: higher doses may result in deeper and more prolonged sedation. Doses of 0.1 to... (truncated)
```


## 🧮 2. Calculator Logic Data (For App Engine)
These parameters are extracted from the raw text/tables to power the `Mini Dosage Calculator`.

### Extraction Logic Applied:
```json
[
  {
    "target_population": "Adults (<60 yrs)",
    "indication": "Preoperative Sedation (IM)",
    "calculator_type": "weight_based",
    "min_dose_per_kg": 0.07,
    "max_dose_per_kg": 0.08,
    "unit": "mg/kg",
    "max_ceiling": "5 mg",
    "route": "IM"
  },
  {
    "target_population": "Pediatrics (6-12 yrs)",
    "indication": "Sedation/anxiolysis",
    "calculator_type": "weight_based",
    "min_dose_per_kg": 0.025,
    "max_dose_per_kg": 0.05,
    "unit": "mg/kg",
    "max_ceiling": "10 mg",
    "route": "IV/IM"
  }
]
```

### How the Calculator Uses This:
If user inputs: **Weight = 20kg** (for Pediatric case above)
- **Logic**: `Weight * min_dose_per_kg` TO `Weight * max_dose_per_kg`
- **Calculation**: `20 * 0.025` TO `20 * 0.05`
- **Result**: **0.5 mg - 1.0 mg**
- **Vs Max Ceiling**: 1.0 mg < 10 mg (Safe)
- **Ampoule Conversion**: If Dormicum is 15mg/3ml (5mg/ml)
  - Volume: **0.1 ml - 0.2 ml**