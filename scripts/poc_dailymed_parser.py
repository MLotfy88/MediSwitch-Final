import re
import json

samples = [
    {
        "id": 25514,
        "text": "Adults: Serious infections—150 to 300 mg every 6 hours. More severe infections—300 to 450 mg every 6 hours. Pediatric Patients: Serious infections—8 to 16 mg/kg/day (4 to 8 mg/lb/day) divided into three or four equal doses."
    },
    {
        "id": 25503,
        "text": "Nosocomial Pneumonia (1.1) 750 mg 7–14 days. Community Acquired Pneumonia (1.2) 500 mg 7–14 days. Acute Bacterial Exacerbation of Chronic Bronchitis (1.5) 500 mg every 24 hours for 7 days."
    },
    {
        "id": 25497,
        "text": "Standard Dose: 0.1mg. Doses greater than 0.1 mg should not be used. Daily doses greater than 1 mg do not enhance efficacy."
    }
]

def parse_dosage(text):
    results = []
    
    # Regex for Range Dosage (e.g., 150 to 300 mg)
    range_pattern = r'(\d+(?:\.\d+)?)\s*(?:to|-)\s*(\d+(?:\.\d+)?)\s*(mg|g|mcg|ml)'
    
    # Regex for Single Dosage (e.g., 500 mg)
    single_pattern = r'(\d+(?:\.\d+)?)\s*(mg|g|mcg|ml)\b(?!/kg)'
    
    # Regex for Pediatric (e.g., 8 to 16 mg/kg/day)
    peds_pattern = r'(\d+(?:\.\d+)?)\s*(?:to|-)\s*(\d+(?:\.\d+)?)\s*(mg/kg/day)'
    
    # Regex for Frequency (e.g., every 6 hours, every 24 hours)
    freq_pattern = r'every\s+(\d+)\s+(hour|hr|day)'
    
    # Cleaning
    clean_text = text.replace('–', '-').replace('\n', ' ')
    
    # Match Logic (Simple Heuristic for PoC)
    
    # 1. Pediatic Ranges
    for match in re.finditer(peds_pattern, clean_text, re.IGNORECASE):
        results.append({
            "type": "Pediatric Range",
            "min_dose": float(match.group(1)),
            "max_dose": float(match.group(2)),
            "unit": match.group(3),
            "raw": match.group(0)
        })

    # 2. Adult Ranges
    for match in re.finditer(range_pattern, clean_text, re.IGNORECASE):
        # Avoid overlap with peds
        if "kg" in clean_text[match.end():match.end()+5]: continue
        
        # Look ahead for frequency
        snippet = clean_text[match.end():match.end()+20]
        freq_match = re.search(freq_pattern, snippet, re.IGNORECASE)
        frequency = freq_match.group(0) if freq_match else "Unspecified"
        
        results.append({
            "type": "Adult Range",
            "min_dose": float(match.group(1)),
            "max_dose": float(match.group(2)),
            "unit": match.group(3),
            "frequency": frequency,
            "raw": match.group(0)
        })

    # 3. Single Doses (if no ranges found in segment)
    if not results:
         for match in re.finditer(single_pattern, clean_text, re.IGNORECASE):
            results.append({
                "type": "Single Dose",
                "dose": float(match.group(1)),
                "unit": match.group(2),
                "raw": match.group(0)
            })
            
    return results

print("--- DailyMed Parsing Proof of Concept ---\n")
for sample in samples:
    print(f"ID: {sample['id']}")
    print(f"Original Text: {sample['text'][:100]}...")
    extracted = parse_dosage(sample['text'])
    print(json.dumps(extracted, indent=2))
    print("-" * 50)
