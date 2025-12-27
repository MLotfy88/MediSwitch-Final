import requests
from bs4 import BeautifulSoup
import urllib3
import json
import csv
import time
import os

# Disable SSL warnings
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

BASE_URL = "https://ddinter2.scbdd.com"
DRUG_DETAIL_URL = f"{BASE_URL}/server/drug-detail/{{id}}/"
INTERACT_API_URL = f"{BASE_URL}/server/interact-with/{{id}}/"
FOOD_API_URL = f"{BASE_URL}/server/interact-with-food/{{id}}/"
DISEASE_API_URL = f"{BASE_URL}/server/interact-with-disease/{{id}}/"
INTERACT_DETAIL_URL = f"{BASE_URL}/server/interact/{{id}}/"

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
    "X-Requested-With": "XMLHttpRequest"
}

def clean_text(text):
    if not text: return ""
    return " ".join(text.replace("\n", " ").split())

class DDInterScraperV2:
    def __init__(self, drug_ids):
        self.drug_ids = drug_ids
        self.results = {}

    def fetch_api_data(self, url):
        try:
            res = requests.post(url, headers=HEADERS, verify=False, timeout=15)
            if res.status_code == 200:
                return res.json().get("data", [])
        except Exception as e:
            print(f"  API Error ({url}): {e}")
        return []

    def scrape_drug_metadata(self, drug_id):
        url = DRUG_DETAIL_URL.format(id=drug_id)
        try:
            res = requests.get(url, headers=HEADERS, verify=False, timeout=15)
            if res.status_code != 200: return {}
            
            soup = BeautifulSoup(res.text, 'html.parser')
            meta = {"id": drug_id, "url": url}
            
            table = soup.find('table', class_='table-bordered')
            if table:
                rows = table.find_all('tr')
                for row in rows:
                    key_td = row.find('td', class_='key')
                    val_td = row.find('td', class_='value')
                    if key_td and val_td:
                        key = clean_text(key_td.get_text())
                        val = clean_text(val_td.get_text())
                        if "Drug Type" in key: meta["drug_type"] = val
                        elif "Formula" in key: meta["formula"] = val
                        elif "Weight" in key: meta["weight"] = val
                        elif "CAS" in key: meta["cas"] = val
                        elif "Description" in key: meta["description"] = val
                        elif "ATC" in key:
                            meta["atc"] = [{"code": clean_text(b.get_text()), "hierarchy": b.get('data-tippy-content', "")} 
                                           for b in val_td.find_all('span', class_='badge')]
                        elif "Links" in key:
                            meta["external_links"] = {clean_text(a.get_text()): a.get('href') for a in val_td.find_all('a')}
            return meta
        except Exception as e:
            print(f"  Scrape Error ({drug_id}): {e}")
        return {}

    def scrape_interaction_details(self, inter_idx):
        url = INTERACT_DETAIL_URL.format(id=inter_idx)
        try:
            res = requests.get(url, headers=HEADERS, verify=False, timeout=15)
            if res.status_code != 200: return {}
            
            soup = BeautifulSoup(res.text, 'html.parser')
            detail = {"interaction_idx": inter_idx, "url": url}
            
            alert = soup.find('div', role='alert')
            if alert:
                badges = alert.find_all('span', class_='badge')
                for b in badges:
                    txt = clean_text(b.get_text())
                    if txt in ["Major", "Moderate", "Minor"]: detail["severity"] = txt
                    else: detail.setdefault("mechanisms", []).append(txt)

            table = soup.find('table', class_='table-bordered')
            if table:
                for row in table.find_all('tr'):
                    k = clean_text(row.find('td', class_='key').get_text()) if row.find('td', class_='key') else ""
                    v_td = row.find('td', class_='value')
                    if k and v_td:
                        if "Interaction" == k: detail["description"] = clean_text(v_td.get_text())
                        elif "Management" == k: detail["management"] = clean_text(v_td.get_text())
                        elif "References" == k: detail["references"] = [clean_text(s.get_text()) for s in v_td.find_all('span')]
                        elif "Alternative for" in k:
                            target = k.replace("Alternative for", "").strip()
                            alts = [{"name": clean_text(a.get_text()), "url": BASE_URL + a.get('href')} 
                                    for a in v_td.find_all('a', class_='col-md-2')]
                            detail.setdefault("alternatives", {})[target] = alts
            return detail
        except Exception as e:
            print(f"  Interaction Error ({inter_idx}): {e}")
        return {}

    def run(self):
        for drug_id in self.drug_ids:
            print(f"Scraping Drug: {drug_id}...")
            drug_data = {
                "metadata": self.scrape_drug_metadata(drug_id),
                "food_interactions": self.fetch_api_data(FOOD_API_URL.format(id=drug_id)),
                "disease_interactions": self.fetch_api_data(DISEASE_API_URL.format(id=drug_id)),
                "interactions": []
            }
            
            # Discovery stage
            print(f"  Discovering interactions for {drug_id}...")
            raw_inter_list = self.fetch_api_data(INTERACT_API_URL.format(id=drug_id))
            
            for item in raw_inter_list:
                idx = item.get("id")
                other_drug = item.get("drug_name")
                print(f"    Scraping interaction details [{idx}] with {other_drug}...")
                details = self.scrape_interaction_details(idx)
                details.update(item) # Merge basic info from API
                drug_data["interactions"].append(details)
                time.sleep(0.5) # Gentle
            
            self.results[drug_id] = drug_data
            time.sleep(1)

    def export(self):
        # JSON Export
        with open("ddinter_test_data.json", "w", encoding='utf-8') as f:
            json.dump(self.results, f, indent=2, ensure_ascii=False)
        
        # CSV Export (Flattened)
        # 1. Drugs Metadata
        with open("drugs_metadata.csv", "w", newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=["id", "drug_type", "formula", "weight", "cas", "url"])
            writer.writeheader()
            for d_id, d_val in self.results.items():
                m = d_val["metadata"]
                writer.writerow({k: m.get(k, "") for k in ["id", "drug_type", "formula", "weight", "cas", "url"]})

        # 2. Drug-Drug Interactions
        with open("drug_interactions_detailed.csv", "w", newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=["drug_a", "drug_b", "severity", "mechanism", "management", "url"])
            writer.writeheader()
            for d_id, d_val in self.results.items():
                for inter in d_val["interactions"]:
                    writer.writerow({
                        "drug_a": d_id,
                        "drug_b": inter.get("drug_name", ""),
                        "severity": inter.get("severity", inter.get("level", "")),
                        "mechanism": inter.get("description", ""),
                        "management": inter.get("management", ""),
                        "url": inter.get("url", "")
                    })

if __name__ == "__main__":
    def get_test_ids():
        try:
            with open("unique_drugs.json", "r") as f:
                return json.load(f)["unique_drugs"][:5]
        except:
            import glob, csv
            csv_files = glob.glob("ddinter_downloads_code_*.csv")
            ids = set()
            for cf in csv_files:
                with open(cf, 'r', encoding='utf-8') as f:
                    reader = csv.DictReader(f)
                    for row in reader:
                        ids.add(row['DDInterID_A'])
                        if len(ids) >= 5: return list(ids)
            return list(ids) if ids else ["DDInter1", "DDInter2", "DDInter3", "DDInter4", "DDInter5"]

    test_run_ids = get_test_ids()
    print(f"Starting test run for ingredients: {test_run_ids}")
    scraper = DDInterScraperV2(test_run_ids)
    scraper.run()
    scraper.export()
    print("Scraping completed. Files generated: ddinter_test_data.json, drugs_metadata.csv, drug_interactions_detailed.csv")
