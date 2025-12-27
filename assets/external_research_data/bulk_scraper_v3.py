import requests
from bs4 import BeautifulSoup
import urllib3
import json
import csv
import time
import os
import re

# Disable SSL warnings
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

BASE_URL = "https://ddinter2.scbdd.com"
DRUG_DETAIL_URL = f"{BASE_URL}/server/drug-detail/{{id}}/"
INTERACT_API_URL = f"{BASE_URL}/server/interact-with/{{id}}/"
FOOD_API_URL = f"{BASE_URL}/server/interact-with-food/{{id}}/"
DISEASE_API_URL = f"{BASE_URL}/server/interact-with-disease/{{id}}/"
INTERACT_DETAIL_URL = f"{BASE_URL}/server/interact/{{id}}/"
METABOLISM_API_URL = f"{BASE_URL}/server/linkmarker/{{id}}/"

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
    "X-Requested-With": "XMLHttpRequest"
}

def clean_text(text):
    if not text: return ""
    return " ".join(text.replace("\n", " ").split()).strip()

class DDInterScraperV3:
    def __init__(self, drug_ids):
        self.drug_ids = drug_ids
        self.results = {}

    def fetch_api_data(self, url):
        try:
            res = requests.get(url, headers=HEADERS, verify=False, timeout=15) if "linkmarker" in url else requests.post(url, headers=HEADERS, verify=False, timeout=15)
            if res.status_code == 200:
                data = res.json()
                return data.get("data", data) # Handles both {"data": [...]} and [...]
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
            
            # 1. Main Table
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
                        elif "IUPAC" in key: meta["iupac_name"] = val
                        elif "InChI" in key: meta["inchi"] = val
                        elif "SMILES" in key: meta["smiles"] = val
                        elif "ATC" in key:
                            meta["atc_classification"] = [{"code": clean_text(b.get_text()), "hierarchy": b.get('data-tippy-content', "").replace("&lt;br&gt;", " | ")} 
                                           for b in val_td.find_all('span', class_='badge')]
                        elif "Links" in key:
                            meta["external_links"] = {clean_text(a.get_text()): a.get('href') for a in val_td.find_all('a')}
            
            # 2. Therapeutic Duplication (Hidden in ATC table/badges logic) - often represented as separate rows if combined.
            # But more importantly, checking for "Therapeutic Duplication" explicit mentions if any.
            # In DDInter, these are often just multiple ATC codes.
            
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
            
            # Severity and Mechanism Badges
            alert = soup.find('div', role='alert')
            if alert:
                badges = alert.find_all('span', class_='badge')
                for b in badges:
                    txt = clean_text(b.get_text())
                    bg = b.get('style', '')
                    if "Major" in txt or "#a8456b" in bg: detail["severity"] = "Major"
                    elif "Moderate" in txt or "#cf7543" in bg: detail["severity"] = "Moderate"
                    elif "Minor" in txt or "#33619b" in bg: detail["severity"] = "Minor"
                    else: detail.setdefault("mechanisms", []).append(txt)

            table = soup.find('table', class_='table-bordered')
            if table:
                for row in table.find_all('tr'):
                    k_td = row.find('td', class_='key')
                    v_td = row.find('td', class_='value')
                    if k_td and v_td:
                        k = clean_text(k_td.get_text())
                        if "Interaction" == k: detail["description"] = clean_text(v_td.get_text())
                        elif "Management" == k: detail["management"] = clean_text(v_td.get_text())
                        elif "References" == k:
                            detail["references"] = [clean_text(s.get_text()) for s in v_td.find_all('span')]
                        elif "Alternative for" in k:
                            target = k.replace("Alternative for", "").strip()
                            # Parse structured alternatives from JS-like block or raw anchors
                            # The 'More' button suggests more data is hidden in HTML
                            alts = [{"name": clean_text(a.get_text()), "id": a.get('href').split('/')[-2], "url": BASE_URL + a.get('href')} 
                                    for a in v_td.find_all('a', class_='col-md-2') if '/server/drug-detail/' in a.get('href', '')]
                            detail.setdefault("alternatives", {})[target] = alts
            return detail
        except Exception as e:
            print(f"  Interaction Error ({inter_idx}): {e}")
        return {}

    def run(self):
        for drug_id in self.drug_ids:
            print(f"Scraping Comprehensive Data for Drug: {drug_id}...")
            # 1. Base Metadata
            metadata = self.scrape_drug_metadata(drug_id)
            
            # 2. Food/Disease/Metabolism API Data
            print(f"  Fetching Food/Disease/Metabolism for {drug_id}...")
            food = self.fetch_api_data(FOOD_API_URL.format(id=drug_id))
            disease = self.fetch_api_data(DISEASE_API_URL.format(id=drug_id))
            metabolism = self.fetch_api_data(METABOLISM_API_URL.format(id=drug_id))
            
            drug_data = {
                "metadata": metadata,
                "food_interactions": food,
                "disease_interactions": disease,
                "metabolism_data": metabolism,
                "interactions": []
            }
            
            # 3. Drug-Drug Interactions Discovery & Deep Scrape
            print(f"  Discovering DDI for {drug_id}...")
            raw_inter_list = self.fetch_api_data(INTERACT_API_URL.format(id=drug_id))
            
            for item in raw_inter_list:
                idx = item.get("id")
                other_drug = item.get("drug_name")
                print(f"    Deep scraping interaction [{idx}] with {other_drug}...")
                details = self.scrape_interaction_details(idx)
                details.update(item) # Merge API info (id, drug_id, drug_name, level)
                drug_data["interactions"].append(details)
                time.sleep(0.3)
            
            self.results[drug_id] = drug_data
            time.sleep(1)

    def export(self):
        # JSON - Full Hierarchical
        with open("ddinter_exhaustive_data.json", "w", encoding='utf-8') as f:
            json.dump(self.results, f, indent=2, ensure_ascii=False)
        
        # CSV - Metadata
        with open("exhaustive_drugs_metadata.csv", "w", newline='', encoding='utf-8') as f:
            fields = ["id", "drug_type", "formula", "weight", "cas", "iupac_name", "inchi", "smiles", "url"]
            writer = csv.DictWriter(f, fieldnames=fields)
            writer.writeheader()
            for d_id, d_val in self.results.items():
                m = d_val["metadata"]
                writer.writerow({k: m.get(k, "") for k in fields})

        # CSV - Detailed DDI
        with open("exhaustive_drug_interactions.csv", "w", newline='', encoding='utf-8') as f:
            fields = ["drug_a", "drug_b", "drug_b_id", "severity", "mechanism", "management", "interaction_idx", "references", "url"]
            writer = csv.DictWriter(f, fieldnames=fields)
            writer.writeheader()
            for d_id, d_val in self.results.items():
                for inter in d_val["interactions"]:
                    writer.writerow({
                        "drug_a": d_id,
                        "drug_b": inter.get("drug_name", ""),
                        "drug_b_id": inter.get("drug_id", ""),
                        "severity": inter.get("severity", inter.get("level", "")),
                        "mechanism": ", ".join(inter.get("mechanisms", [])),
                        "management": inter.get("management", ""),
                        "interaction_idx": inter.get("interaction_idx", ""),
                        "references": " | ".join(inter.get("references", [])),
                        "url": inter.get("url", "")
                    })

if __name__ == "__main__":
    def get_test_ids():
        try:
            with open("unique_drugs.json", "r") as f:
                return json.load(f)["unique_drugs"][:5]
        except:
            return ["DDInter1", "DDInter2", "DDInter3", "DDInter4", "DDInter5"]

    test_ids = get_test_ids()
    print(f"EXHAUSTIVE SCRAPE START: {test_ids}")
    scraper = DDInterScraperV3(test_ids)
    scraper.run()
    scraper.export()
    print("DONE. Produced: ddinter_exhaustive_data.json, exhaustive_drugs_metadata.csv, exhaustive_drug_interactions.csv")
