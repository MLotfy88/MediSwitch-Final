
import re

text = """Standard Dose: 1000.0mg. DOSAGE AND ADMINISTRATION Levetiracetam is indicated as adjunctive treatment of partial onset seizures in adults and children 4 years of age and older with epilepsy. Partial Onset Seizures Adults 16 Years And Older In clinical trials, daily doses of 1000 mg, 2000 mg, and 3000 mg, given as twice daily dosing, were shown to be effective. Although in some studies there was a tendency toward greater response with higher dose (see CLINICAL STUDIES ), a consistent increase in response with increased d..."""

print("ORIGINAL TEXT:")
print(text)
print("-" * 50)

cleaned = text

# 1. Remove Prefix
prefix_regex = re.compile(r'^Standard Dose:\s*[\d\.]+\s*mg\.?\s*', re.IGNORECASE)
cleaned = prefix_regex.sub('', cleaned)

# 2. Format Headers
def replacer(match):
    header = match.group(0)
    if len(header) > 5:
        return f'\n\n{header}\n'
    return header

header_regex = re.compile(r'([A-Z]{3,}(\s+[A-Z]{3,})*)')
cleaned = header_regex.sub(replacer, cleaned)

# 3. Trim
cleaned = cleaned.replace(' .', '.')
cleaned = cleaned.strip()

print("CLEANED TEXT:")
print(cleaned)
