
import sys
import json
from pathlib import Path

# Add script dir to path to import scraper
sys.path.insert(0, str(Path(__file__).parent / 'wikem_scraper'))
from scraper import WikEMScraper

def verify_scraping():
    scraper = WikEMScraper()
    
    # Test cases covering different page structures
    test_drugs = [
        "Metronidazole",       # Standard drug page
        "2kg_(preemie)",      # Weight-based page (Tables at top)
        "ACLS_(Main)"         # Protocol page
    ]
    
    print("🚀 Starting Verification Scrape...\n")
    
    for drug in test_drugs:
        print(f"📄 Scraping: {drug}...")
        try:
            data = scraper.scrape_drug(drug)
            
            if not data:
                print(f"❌ Failed to scrape {drug}")
                continue
                
            sections = data.get("sections", {})
            print(f"✅ Found {len(sections)} sections: {list(sections.keys())}")
            
            # Check Intro (for weight based pages)
            if "Intro" in sections:
                intro = sections["Intro"]
                has_table = len(intro.get("tables", [])) > 0
                text_len = len(intro.get("text", ""))
                print(f"   🔹 [Intro] Found Table: {has_table} | Text Length: {text_len}")
                if has_table:
                   print(f"   📊 Intro Table Sample: {intro['tables'][0][0] if intro['tables'][0] else 'Empty Row'}")

            # Check Specific Sections
            if "Antibiotic_Sensitivities" in sections:
                 sens = sections["Antibiotic_Sensitivities"]
                 print(f"   🔹 [Antibiotic_Sensitivities] Tables: {len(sens.get('tables', []))}")
            
            if "Adult_Dosing" in sections:
                 dosing = sections["Adult_Dosing"]
                 print(f"   🔹 [Adult_Dosing] Subsections: {list(dosing.get('subsections', {}).keys())}")

            print("-" * 50)
            
        except Exception as e:
            print(f"❌ Error scraping {drug}: {e}")

if __name__ == "__main__":
    verify_scraping()
