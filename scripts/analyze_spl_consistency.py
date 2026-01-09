
import sqlite3
import zlib
import re
import random

DB_PATH = '/home/adminlotfy/project/assets/database/mediswitch.db'

def decompress_text(data):
    if not data: return ""
    if isinstance(data, str): return data
    if isinstance(data, bytes):
        try:
            return zlib.decompress(data).decode('utf-8')
        except:
            return data.decode('utf-8', errors='ignore')
    return str(data)

def analyze_structure():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    print("--- Analyzing SPL Structure Consistency (Sample: 100 Drugs) ---")
    
    # Select 100 random DailyMed records
    cursor.execute("""
        SELECT id, instructions 
        FROM dosage_guidelines 
        WHERE source LIKE '%DailyMed%' 
        ORDER BY RANDOM() 
        LIMIT 100
    """)
    rows = cursor.fetchall()
    
    stats = {
        "total": 0,
        "has_dosage_header": 0,
        "has_pediatric_mention": 0,
        "has_adult_mention": 0,
        "structured_format": 0, # Contains newline-separated sections
        "visual_chaos": 0 # Long text block (>2000 chars) without clear breaks
    }
    
    # Common Headers in SPL (Case Insensitive Regex)
    headers = {
        "DOSAGE_ADMIN": r"(DOSAGE AND ADMINISTRATION|DOSAGE)",
        "PEDIATRIC": r"(PEDIATRIC|CHILDREN|INFANT)",
        "ADULT": r"(ADULT|ELDERLY|GERIATRIC)",
        "CONTRAIND": r"(CONTRAINDICATIONS)"
    }
    
    for row in rows:
        stats["total"] += 1
        text = decompress_text(row[1])
        
        # Check Headers
        if re.search(headers["DOSAGE_ADMIN"], text, re.IGNORECASE):
            stats["has_dosage_header"] += 1
            
        if re.search(headers["PEDIATRIC"], text, re.IGNORECASE):
            stats["has_pediatric_mention"] += 1
            
        if re.search(headers["ADULT"], text, re.IGNORECASE):
            stats["has_adult_mention"] += 1
            
        # Check Structure
        # If text has multiple newlines or clear section numbering (e.g. "2.1")
        if text.count('\n') > 5 or re.search(r'\b\d+\.\d+\s+[A-Z]', text):
            stats["structured_format"] += 1
        else:
             if len(text) > 2000:
                 stats["visual_chaos"] += 1

    conn.close()
    
    print(f"\n📊 Results for {stats['total']} records:")
    print(f"✅ Contain 'DOSAGE AND ADMINISTRATION' header: {stats['has_dosage_header']} ({stats['has_dosage_header']}%)")
    print(f"✅ Mention 'PEDIATRIC/CHILDREN': {stats['has_pediatric_mention']} ({stats['has_pediatric_mention']}%)")
    print(f"✅ Mention 'ADULT/ELDERLY': {stats['has_adult_mention']} ({stats['has_adult_mention']}%)")
    print(f"📋 Structured Format (Newlines/Numbering): {stats['structured_format']} ({stats['structured_format']}%)")
    print(f"⚠️ Visual Chaos (Huge blocks without breaks): {stats['visual_chaos']} ({stats['visual_chaos']}%)")
    
    print("\n💡 Interpretation:")
    if stats['has_dosage_header'] > 70:
        print("-> High Scalability: Most drugs follow SPL standards.")
    else:
        print("-> Low Scalability: Many drugs have unique/unstructured formats.")

if __name__ == "__main__":
    analyze_structure()
