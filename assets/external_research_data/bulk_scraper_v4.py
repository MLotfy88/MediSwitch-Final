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

class DDInterScraperV4:
    def __init__(self, drug_ids, output_json="ddinter_exhaustive_v4.json"):
        self.drug_ids = drug_ids
        self.output_json = output_json
        self.results = {}
        # Load existing data if any (for resume)
        if os.path.exists(self.output_json):
            try:
                with open(self.output_json, "r", encoding='utf-8') as f:
                    self.results = json.load(f)
            except: pass

    def save(self):
        with open(self.output_json, "w", encoding='utf-8') as f:
            json.dump(self.results, f, indent=2, ensure_ascii=False)

    def fetch_api_data(self, url):
        try:
            # linkmarker uses GET, others use POST
            if "linkmarker" in url:
                res = requests.get(url, headers=HEADERS, verify=False, timeout=15)
            else:
                res = requests.post(url, headers=HEADERS, verify=False, timeout=15)
                
            if res.status_code == 200:
                data = res.json()
                return data.get("data", data)
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
            
            # --- EXTRACT DRUG NAME (CRITICAL FIX) ---
            # Usually found in <strong class="me-2">Drugs Information:</strong> then the text node
            target = soup.find('strong', string=re.compile("Drugs Information", re.I))
            if target and target.parent:
                meta["name"] = clean_text(target.parent.get_text().replace(target.get_text(), ""))
            else:
                # Fallback to <h1> or alert
                alert = soup.find('div', role='alert')
                if alert:
                    meta["name"] = clean_text(alert.get_text().split(":")[-1])

            # --- TABLE DATA ---
            table = soup.find('table', class_='table-bordered')
            if table:
                for row in table.find_all('tr'):
                    k_td = row.find('td', class_='key')
                    v_td = row.find('td', class_='value')
                    if k_td and v_td:
                        key = clean_text(k_td.get_text())
                        val = clean_text(v_td.get_text())
                        if "Drug Type" in key: meta["drug_type"] = val
                        elif "Formula" in key: meta["formula"] = val
                        elif "Weight" in key: meta["weight"] = val
                        elif "CAS" in key: meta["cas"] = val
                        elif "Description" in key: meta["description"] = val
                        elif "IUPAC" in key: meta["iupac_name"] = val
                        elif "InChI" in key: meta["inchi"] = val
                        elif "SMILES" in key: meta["smiles"] = val
                        elif "ATC" in key:
                            badges = v_td.find_all('span', class_='badge')
                            atc_list = []
                            for b in badges:
                                code = clean_text(b.get_text())
                                desc = b.get('data-tippy-content', "").replace("&lt;br&gt;", " | ")
                                atc_list.append({"code": code, "description": desc})
                            meta["atc_classification"] = atc_list
                        elif "Links" in key:
                            meta["external_links"] = {clean_text(a.get_text()): a.get('href') for a in v_td.find_all('a')}
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
            
            # Severity / Mechanisms
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

            # Table Clinical Details
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
                            alts = [{"name": clean_text(a.get_text()), "id": a.get('href').split('/')[-2], "url": BASE_URL + a.get('href')} 
                                    for a in v_td.find_all('a', class_='col-md-2') if '/server/drug-detail/' in a.get('href', '')]
                            detail.setdefault("alternatives", {})[target] = alts
            return detail
        except Exception as e:
            print(f"  Interaction Error ({inter_idx}): {e}")
        return {}

    def run(self):
        for drug_id in self.drug_ids:
            if drug_id in self.results: 
                print(f"Skipping {drug_id}, already in results.")
                continue

            print(f"Scraping {drug_id}...")
            meta = self.scrape_drug_metadata(drug_id)
            if not meta: continue

            drug_data = {
                "metadata": meta,
                "food_interactions": self.fetch_api_data(FOOD_API_URL.format(id=drug_id)),
                "disease_interactions": self.fetch_api_data(DISEASE_API_URL.format(id=drug_id)),
                "metabolism_data": self.fetch_api_data(METABOLISM_API_URL.format(id=drug_id)),
                "interactions": []
            }
            
            print(f"  Discovery for {drug_id}...")
            raw_inter_list = self.fetch_api_data(INTERACT_API_URL.format(id=drug_id))
            
            # Ensure we capture all even if one fails
            for item in raw_inter_list:
                idx = item.get("id")
                other_name = item.get("drug_name")
                print(f"    - [{idx}] vs {other_name}...")
                details = self.scrape_interaction_details(idx)
                # Merge logic
                full_inter = {**item, **details}
                drug_data["interactions"].append(full_inter)
                time.sleep(0.3)
            
            self.results[drug_id] = drug_data
            self.save() # Incremental save
            time.sleep(1)

    def export_csv(self):
        # 1. Metadata CSV (Granular)
        with open("ddinter_drugs_metadata_v4.csv", "w", newline='', encoding='utf-8') as f:
            fields = ["id", "name", "drug_type", "formula", "weight", "cas", "iupac_name", "inchi", "smiles", "atc_primary", "atc_all", "external_links", "url"]
            writer = csv.DictWriter(f, fieldnames=fields)
            writer.writeheader()
            for d_id, d_val in self.results.items():
                m = d_val["metadata"]
                atc_list = m.get("atc_classification", [])
                writer.writerow({
                    "id": d_id,
                    "name": m.get("name", ""),
                    "drug_type": m.get("drug_type", ""),
                    "formula": m.get("formula", ""),
                    "weight": m.get("weight", ""),
                    "cas": m.get("cas", ""),
                    "iupac_name": m.get("iupac_name", ""),
                    "inchi": m.get("inchi", ""),
                    "smiles": m.get("smiles", ""),
                    "atc_primary": atc_list[0]["code"] if atc_list else "",
                    "atc_all": "; ".join([f"{x['code']} ({x['description']})" for x in atc_list]),
                    "external_links": "; ".join([f"{k}: {v}" for k, v in m.get("external_links", {}).items()]),
                    "url": m.get("url", "")
                })

        # 2. Interactions CSV (Granular)
        with open("ddinter_interactions_v4.csv", "w", newline='', encoding='utf-8') as f:
            fields = ["drug_a_id", "drug_a_name", "drug_b_id", "drug_b_name", "severity", "mechanisms", "clinical_description", "management_advice", "interaction_idx", "references", "interaction_url"]
            writer = csv.DictWriter(f, fieldnames=fields)
            writer.writeheader()
            for d_id, d_val in self.results.items():
                name_a = d_val["metadata"].get("name", "")
                for inter in d_val["interactions"]:
                    writer.writerow({
                        "drug_a_id": d_id,
                        "drug_a_name": name_a,
                        "drug_b_id": inter.get("drug_id", ""),
                        "drug_b_name": inter.get("drug_name", ""),
                        "severity": inter.get("severity", inter.get("level", "")),
                        "mechanisms": "; ".join(inter.get("mechanisms", [])),
                        "clinical_description": inter.get("description", ""),
                        "management_advice": inter.get("management", ""),
                        "interaction_idx": inter.get("id", ""),
                        "references": " | ".join(inter.get("references", [])),
                        "interaction_url": INTERACT_DETAIL_URL.format(id=inter.get("id", ""))
                    })

if __name__ == "__main__":
    def get_test_ids():
        try:
            with open("unique_drugs.json", "r") as f:
                return json.load(f)["unique_drugs"][:5]
        except:
            return ["DDInter20", "DDInter1", "DDInter2", "DDInter3", "DDInter4"]

    scraper = DDInterScraperV4(get_test_ids())
    scraper.run()
    scraper.export_csv()
    print("V4 Scrape Completed Successfully.")
