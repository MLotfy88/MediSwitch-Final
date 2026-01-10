#!/usr/bin/env python3
"""
NCBI StatPearls Scraper for MediSwitch
Fetches detailed drug information from NCBI StatPearls books
"""

import json
import time
import requests
from pathlib import Path
from bs4 import BeautifulSoup
from typing import Dict, List, Optional
import re

# Configuration
BASE_URL = "https://www.ncbi.nlm.nih.gov/books"
OUTPUT_DIR = Path(__file__).parent / "scraped_data"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# Rate limiting
DELAY_BETWEEN_REQUESTS = 1  # seconds


class StatPearlsScraper:
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (MediSwitch ETL Bot; Research/Educational)'
        })
    
    def scrape_drug_page(self, nbk_id: str, drug_name: str) -> Optional[Dict]:
        """
        Scrape a single StatPearls drug page
        
        Args:
            nbk_id: NBK identifier (e.g., "NBK482154")
            drug_name: Name of the drug
            
        Returns:
            Dictionary with structured drug information
        """
        url = f"{BASE_URL}/{nbk_id}/"
        
        try:
            print(f"📥 Fetching {drug_name} ({nbk_id})...")
            response = self.session.get(url, timeout=30)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Extract main content - StatPearls uses different structure
            content_div = soup.find('div', {'id': 'article-details'})
            if not content_div:
                # Try alternative selector
                content_div = soup.find('div', class_='content')
            if not content_div:
                # Last resort: find the main article tag
                content_div = soup.find('article')
            
            if not content_div:
                print(f"⚠️  No content div found for {drug_name}")
                return None
            
            # Initialize data structure
            drug_data = {
                "drug_name": drug_name,
                "nbk_id": nbk_id,
                "url": url,
                "scraped_at": time.strftime("%Y-%m-%dT%H:%M:%S"),
                "sections": {}
            }
            
            # Target sections we care about
            target_sections = {
                "Indications": "indications",
                "Administration": "administration",
                "Adverse Effects": "adverse_effects",
                "Contraindications": "contraindications",
                "Monitoring": "monitoring",
                "Mechanism of Action": "mechanism",
                "Toxicity": "toxicity"
            }
            
            # Find all H2 sections
            for h2 in content_div.find_all('h2'):
                section_title = h2.get_text(strip=True)
                
                # Check if this is a section we want
                matched_key = None
                for target, key in target_sections.items():
                    if target.lower() in section_title.lower():
                        matched_key = key
                        break
                
                if not matched_key:
                    continue
                
                # Extract content until next H2
                section_content = []
                for sibling in h2.find_next_siblings():
                    if sibling.name == 'h2':
                        break
                    if sibling.name in ['p', 'ul', 'ol', 'div']:
                        text = sibling.get_text(separator='\n', strip=True)
                        if text:
                            section_content.append(text)
                
                if section_content:
                    drug_data["sections"][matched_key] = '\n\n'.join(section_content)
            
            # Check if we got useful data
            if not drug_data["sections"]:
                print(f"⚠️  No sections extracted for {drug_name}")
                return None
            
            print(f"✅ Scraped {drug_name}: {len(drug_data['sections'])} sections")
            return drug_data
            
        except requests.RequestException as e:
            print(f"❌ Error fetching {drug_name}: {e}")
            return None
        except Exception as e:
            print(f"❌ Unexpected error for {drug_name}: {e}")
            return None
    
    def save_data(self, drug_data: Dict):
        """Save scraped data to JSON file"""
        filename = OUTPUT_DIR / f"{drug_data['drug_name'].replace(' ', '_')}.json"
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(drug_data, f, indent=2, ensure_ascii=False)
        print(f"💾 Saved to {filename}")
    
    def scrape_from_list(self, drug_list_file: str):
        """
        Scrape multiple drugs from a CSV/TSV file
        
        Format: drug_name,nbk_id
        Example: Amiodarone,NBK482154
        """
        drugs_file = Path(drug_list_file)
        if not drugs_file.exists():
            print(f"❌ File not found: {drug_list_file}")
            return
        
        with open(drugs_file, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        print(f"🚀 Starting scraper for {len(lines)} drugs...")
        
        success_count = 0
        fail_count = 0
        
        for line in lines:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            
            parts = line.split(',')
            if len(parts) != 2:
                print(f"⚠️  Invalid format: {line}")
                continue
            
            drug_name, nbk_id = parts[0].strip(), parts[1].strip()
            
            # Scrape the drug
            drug_data = self.scrape_drug_page(nbk_id, drug_name)
            
            if drug_data:
                self.save_data(drug_data)
                success_count += 1
            else:
                fail_count += 1
            
            # Rate limiting
            time.sleep(DELAY_BETWEEN_REQUESTS)
        
        print(f"\n{'='*50}")
        print(f"✅ Scraping Complete!")
        print(f"✅ Success: {success_count}")
        print(f"❌ Failed: {fail_count}")
        print(f"{'='*50}")


def main():
    scraper = StatPearlsScraper()
    
    # Example: scrape Amiodarone
    drug_data = scraper.scrape_drug_page("NBK482154", "Amiodarone")
    if drug_data:
        scraper.save_data(drug_data)
    
    # To scrape from a list, uncomment:
    # scraper.scrape_from_list("drug_list.csv")


if __name__ == "__main__":
    main()
