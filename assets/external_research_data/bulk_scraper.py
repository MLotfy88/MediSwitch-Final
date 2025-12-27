import requests
from bs4 import BeautifulSoup
import urllib3
import json
import time
import os

# Disable SSL warnings
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

DRUG_DETAIL_URL = "https://ddinter2.scbdd.com/server/drug-detail/{id}/"
INTERACT_API_URL = "https://ddinter2.scbdd.com/server/interact-with/{id}/"
INTERACT_DETAIL_URL = "https://ddinter2.scbdd.com/server/interact/{id}/"

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
    "X-Requested-With": "XMLHttpRequest"
}

def clean_text(text):
    if not text: return ""
    return " ".join(text.replace("\n", " ").split())

class DDInterScraper:
    def __init__(self, drug_list_path):
        with open(drug_list_path, 'r') as f:
            self.discovery_data = json.load(f)
        self.drug_ids = self.discovery_data["unique_drugs"]
        self.output_file = "ddinter_hierarchical_data.json"
        self.data = {}
        if os.path.exists(self.output_file):
            with open(self.output_file, 'r') as f:
                try: self.data = json.load(f)
                except: self.data = {}

    def save(self):
        with open(self.output_file, 'w') as f:
            json.dump(self.data, f, indent=2, ensure_ascii=False)

    def scrape_drug_metadata(self, drug_id):
        url = DRUG_DETAIL_URL.format(id=drug_id)
        try:
            res = requests.get(url, headers=HEADERS, verify=False, timeout=15)
            if res.status_code != 200: return None
            
            soup = BeautifulSoup(res.text, 'html.parser')
            drug_info = {"id": drug_id, "url": url}
            
            table = soup.find('table', class_='table-bordered')
            if table:
                rows = table.find_all('tr')
                for row in rows:
                    key_td = row.find('td', class_='key')
                    val_td = row.find('td', class_='value')
                    if key_td and val_td:
                        key = clean_text(key_td.get_text())
                        if "Drug Type" in key: drug_info["type"] = clean_text(val_td.get_text())
                        elif "Formula" in key: drug_info["formula"] = clean_text(val_td.get_text())
                        elif "Weight" in key: drug_info["weight"] = clean_text(val_td.get_text())
                        elif "CAS" in key: drug_info["cas"] = clean_text(val_td.get_text())
                        elif "Description" in key: drug_info["description"] = clean_text(val_td.get_text())
                        elif "ATC" in key:
                            atc = []
                            for b in val_td.find_all('span', class_='badge'):
                                atc.append({"code": clean_text(b.get_text()), "hierarchy": b.get('data-tippy-content', "")})
                            drug_info["atc"] = atc
            return drug_info
        except Exception as e:
            print(f"Error drug {drug_id}: {e}")
        return None

    def discover_interaction_ids(self, drug_id):
        # This calls the AJAX API to get interaction IDs (idx) for this drug
        try:
            res = requests.post(INTERACT_API_URL.format(id=drug_id), headers=HEADERS, verify=False, timeout=15)
            if res.status_code == 200:
                json_res = res.json()
                # Returns: {"data": [{"interaction_id": "...", "drug_id": "...", "drug_name": "...", "level": "..."}, ...]}
                return json_res.get("data", [])
        except Exception as e:
            print(f"Error discovery for {drug_id}: {e}")
        return []

    def run_metadata_phase(self, limit=None):
        count = 0
        for drug_id in self.drug_ids:
            if drug_id in self.data and "metadata" in self.data[drug_id]:
                continue
            
            print(f"[{count}] Scraping metadata for {drug_id}...", flush=True)
            metadata = self.scrape_drug_metadata(drug_id)
            if metadata:
                self.data.setdefault(drug_id, {})["metadata"] = metadata
                # Also discover interaction IDs
                print(f"    Discovering interactions for {drug_id}...", flush=True)
                interactions = self.discover_interaction_ids(drug_id)
                self.data[drug_id]["interaction_list"] = interactions
                
                count += 1
                if count % 10 == 0: self.save()
                if limit and count >= limit: break
                time.sleep(0.5)
        self.save()

if __name__ == "__main__":
    scraper = DDInterScraper("discovered_ids.json")
    # Test with 5 drugs
    scraper.run_metadata_phase(limit=5)
    print("Test Phase 1 Complete. Check ddinter_hierarchical_data.json")
