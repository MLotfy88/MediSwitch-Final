from scripts.purify_dosages import clean_text

dirty_text = "Standard Dose: 1000.0mg. DOSAGE AND ADMINISTRATION Levetiracetam is indicated as adjunctive treatment of partial onset seizures in adults and children 4 years of age and older with epilepsy. Partial Onset Seizures Adults 16 Years And Older In clinical trials, daily doses of 1000 mg, 2000 mg, and 3000 mg, given as twice daily dosing, were shown to be effective. Although in some studies there was a tendency toward greater response with higher dose (see CLINICAL STUDIES ), a consistent increase in response with increased dose was not observed."

print("--- ORIGINAL ---")
print(dirty_text)
print("\n--- CLEANED ---")
print(clean_text(dirty_text))
