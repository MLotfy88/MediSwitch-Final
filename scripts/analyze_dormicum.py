
import sqlite3
import zlib
import re

DB_PATH = '/home/adminlotfy/project/assets/database/mediswitch.db'

def decompress_text(data):
    if isinstance(data, str):
        return data
    if isinstance(data, bytes):
        try:
            return zlib.decompress(data).decode('utf-8')
        except:
            return data.decode('utf-8', errors='ignore')
    return ""

def parse_dosage_text(text):
    results = []
    text = decompress_text(text)
    if not text:
        return results
        
    text = text.replace('–', '-').replace('\n', ' ')
    
    # Patterns
    range_freq_pattern = r'(\d+(?:\.\d+)?)\s*(?:to|-)\s*(\d+(?:\.\d+)?)\s*(mg|g|mcg|ml|tablet|cap)\b.*?(every\s+\d+\s+(?:hour|hr|day)s?|daily|bid|tid|qid)'
    single_freq_pattern = r'(\d+(?:\.\d+)?)\s*(mg|g|mcg|ml|tablet|cap)\b.*?(every\s+\d+\s+(?:hour|hr|day)s?|daily|bid|tid|qid)'
    peds_pattern = r'(\d+(?:\.\d+)?)\s*(?:to|-)\s*(\d+(?:\.\d+)?)\s*(mg/kg/day|mg/kg)'

    # Extraction Logic
    for match in re.finditer(peds_pattern, text, re.IGNORECASE):
        results.append(f"Pediatric: {match.group(0)}")
        
    for match in re.finditer(range_freq_pattern, text, re.IGNORECASE):
        if "kg" in text[match.start():match.end()+10]: continue
        results.append(f"Adult Range: {match.group(0)}")

    if not results:
        for match in re.finditer(single_freq_pattern, text, re.IGNORECASE):
             if "kg" in text[match.start():match.end()+10]: continue
             results.append(f"Adult Single: {match.group(0)}")
            
    return results

conn = sqlite3.connect(DB_PATH)
cursor = conn.cursor()

print("--- Analysis for 'Dormicum' ---")
# 1. Look up drug ID
# Column name check: 'drugs' table has 'trade_name', not 'name'
cursor.execute("SELECT id, trade_name FROM drugs WHERE trade_name LIKE '%Dormicum%' LIMIT 1")
drug = cursor.fetchone()

if not drug:
    print("❌ Dormicum not found in drugs table.")
else:
    drug_id, drug_name = drug
    print(f"✅ Found Drug: {drug_name} (ID: {drug_id})")
    
    # 2. Get Dosage Guidelines
    cursor.execute("SELECT instructions, source FROM dosage_guidelines WHERE med_id = ?", (drug_id,))
    guidelines = cursor.fetchall()
    
    if not guidelines:
        print("❌ No dosage guidelines found for this drug.")
    else:
        for i, (instr, source) in enumerate(guidelines):
            print(f"\n--- Guideline #{i+1} (Source: {source}) ---")
            
            # Show Raw (Preview)
            raw_preview = str(instr)[:50] + "..." if len(str(instr)) > 50 else str(instr)
            print(f"Raw Data Type: {type(instr)}")
            # print(f"Raw Content: {raw_preview}") # Skip binary printing to avoid mess
            
            # Decompress
            full_text = decompress_text(instr)
            print(f"📄 Full Text Length: {len(full_text)} chars")
            print(f"📝 Text Preview: {full_text[:200]}...")
            
            # Apply Parser
            print("\n🔍 Parsing Results:")
            results = parse_dosage_text(full_text)
            if results:
                for res in results:
                    print(f"   ✅ {res}")
            else:
                print("   ❌ No structured dosage extracted.")

conn.close()
