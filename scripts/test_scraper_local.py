
import sys
from pathlib import Path
import json

# Add script dir to path
sys.path.insert(0, str(Path(__file__).parent / 'wikem_scraper'))
from scraper import WikEMScraper

def run_local_test():
    # 1. Setup
    scraper = WikEMScraper()
    
    # Load full list but slice first 10
    drug_list_file = Path("scripts/wikem_scraper/drug_list.txt")
    with open(drug_list_file, 'r') as f:
        full_list = [line.strip() for line in f if line.strip()]
    
    test_list = full_list[:10]  # First 10 drugs
    
    print(f"🚀 Running Local Test on {len(test_list)} drugs: {test_list}")
    
    # 2. Run Scraper
    scraper.run(test_list)
    
    # 3. Verify Results
    print("\n📊 === RESULTS VERIFICATION ===")
    for drug in test_list:
        file_path = Path("scripts/wikem_scraper/scraped_data/drugs") / f"{drug.replace('/', '_')}.json"
        
        if file_path.exists():
            with open(file_path, 'r') as f:
                data = json.load(f)
                
            sections = list(data.get("sections", {}).keys())
            section_count = len(sections)
            
            status = "✅ OK" if section_count > 0 else "❌ EMPTY"
            print(f"- {drug}: {status} ({section_count} sections) -> {sections}")
        else:
            print(f"- {drug}: ⚠️ File Processing/Missing")

if __name__ == "__main__":
    run_local_test()
