import sys
import os

# Immediate unbuffered output
print(">>> DDInter Scraper V6: BOOTING UP...", flush=True)

import requests
from bs4 import BeautifulSoup
import urllib3
import json
import csv
import time
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
    "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "X-Requested-With": "XMLHttpRequest",
    "Accept": "application/json, text/javascript, */*; q=0.01",
}

def clean_text(text):
    if not text: return ""
    return " ".join(text.replace("\n", " ").split()).strip()

class DDInterScraperV6:
    def __init__(self, drug_ids, output_json="ddinter_exhaustive_v6.json"):
        self.drug_ids = drug_ids
        self.output_json = output_json
        self.results = {}
        if os.path.exists(self.output_json):
            try:
                with open(self.output_json, "r", encoding='utf-8') as f:
                    self.results = json.load(f)
                print(f">>> Resumed from existing {self.output_json}", flush=True)
            except: pass

    def save(self):
        with open(self.output_json, "w", encoding='utf-8') as f:
            json.dump(self.results, f, indent=2, ensure_ascii=False)

    def fetch_api_data(self, url, referer):
        print(f"  [AJAX] Requesting: {url}", flush=True)
        payload = {"draw": "1", "start": "0", "length": "1000", "search[value]": "", "search[regex]": "false"}
        h = {**HEADERS, "Referer": referer}
        try:
            if "linkmarker" in url:
                res = requests.get(url, headers=h, verify=False, timeout=30)
            else:
                res = requests.post(url, headers=h, data=payload, verify=False, timeout=30)
            if res.status_code == 200:
                data = res.json()
                results = data.get("data", data)
                print(f"  [AJAX] Received {len(results)} items.", flush=True)
                return results
            else:
                print(f"  [AJAX Warning] Status {res.status_code} for {url}", flush=True)
        except Exception as e:
            print(f"  [AJAX Error] {e}", flush=True)
        return []

    def scrape_drug_metadata(self, drug_id):
        url = DRUG_DETAIL_URL.format(id=drug_id)
        print(f"  [Page] Scraping Metadata: {url}", flush=True)
        try:
            res = requests.get(url, headers=HEADERS, verify=False, timeout=30)
            if res.status_code != 200: return {}
            soup = BeautifulSoup(res.text, 'html.parser')
            meta = {"id": drug_id, "url": url, "name": "Unknown"}
            
            # Name Extraction
            alert = soup.find('div', role='alert')
            if alert:
                text = alert.get_text()
                if "Drugs Information:" in text:
                    meta["name"] = clean_text(text.split("Drugs Information:")[-1])
            
            # Table Data
            table = soup.find('table', class_='table-bordered')
            if table:
                for row in table.find_all('tr'):
                    k_td = row.find('td', class_='key')
                    v_td = row.find('td', class_='value')
                    if k_td and v_td:
                        k = clean_text(k_td.get_text())
                        v = clean_text(v_td.get_text())
                        if "Drug Type" in k: meta["type"] = v
                        elif "Formula" in k: meta["formula"] = v
                        elif "Weight" in k: meta["weight"] = v
                        elif "CAS" in k: meta["cas"] = v
                        elif "Description" in k: meta["description"] = v
                        elif "IUPAC" in k: meta["iupac"] = v
                        elif "InChI" in k: meta["inchi"] = v
                        elif "SMILES" in k: meta["smiles"] = v
                        elif "ATC" in k:
                            meta["atc"] = [{"code": clean_text(b.get_text()), "info": b.get('data-tippy-content', "")} 
                                           for b in v_td.find_all('span', class_='badge')]
                        elif "Links" in k:
                            meta["links"] = {clean_text(a.get_text()): a.get('href') for a in v_td.find_all('a')}
            return meta
        except Exception as e:
            print(f"  [Page Error] {e}", flush=True)
        return {}

    def scrape_interaction_details(self, inter_idx):
        url = INTERACT_DETAIL_URL.format(id=inter_idx)
        try:
            res = requests.get(url, headers=HEADERS, verify=False, timeout=30)
            if res.status_code != 200: return {}
            soup = BeautifulSoup(res.text, 'html.parser')
            detail = {"interaction_idx": inter_idx, "url": url}
            
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
                            alts = [{"name": clean_text(a.get_text()), "id": a.get('href').split('/')[-2], "url": BASE_URL + a.get('href')} 
                                    for a in v_td.find_all('a', class_='col-md-2') if '/server/drug-detail/' in a.get('href', '')]
                            detail.setdefault("alternatives", {})[target] = alts
            return detail
        except Exception as e:
            print(f"    [Inter Error] {e}", flush=True)
        return {}

    def run(self, limit_interactions=None):
        total_drugs = len(self.drug_ids)
        for i, drug_id in enumerate(self.drug_ids):
            print(f"\n>>> [{i+1}/{total_drugs}] PROCESSING DRUG: {drug_id}", flush=True)
            if drug_id in self.results and self.results[drug_id].get("interactions"):
                print(f"      Skipping, already in local results.", flush=True)
                continue

            meta = self.scrape_drug_metadata(drug_id)
            if not meta: 
                print(f"      CRITICAL: FAILED to scrape metadata.", flush=True)
                continue
            
            ref = meta.get("url")
            drug_data = {
                "metadata": meta,
                "food": self.fetch_api_data(FOOD_API_URL.format(id=drug_id), ref),
                "disease": self.fetch_api_data(DISEASE_API_URL.format(id=drug_id), ref),
                "metabolism": self.fetch_api_data(METABOLISM_API_URL.format(id=drug_id), ref),
                "interactions": []
            }
            
            raw_list = self.fetch_api_data(INTERACT_API_URL.format(id=drug_id), ref)
            if limit_interactions:
                print(f"      [Test Mode] Limiting interactions to {limit_interactions}.", flush=True)
                raw_list = raw_list[:limit_interactions]
            
            print(f"      Scraping {len(raw_list)} interaction details...", flush=True)
            for j, item in enumerate(raw_list):
                idx = item.get("interaction_id")
                if not idx: continue
                if j % 10 == 0: print(f"        ... Progress: {j}/{len(raw_list)}", flush=True)
                details = self.scrape_interaction_details(idx)
                drug_data["interactions"].append({**item, **details})
                time.sleep(0.1)
            
            self.results[drug_id] = drug_data
            self.save()
            print(f"      Finished {drug_id}. (JSON Updated)", flush=True)

    def export_csv(self):
        print("\n>>> GENERATING FINAL CSV EXPORTS...", flush=True)
        # Metadata
        with open("ddinter_drugs_metadata_v6.csv", "w", newline='', encoding='utf-8') as f:
            w = csv.DictWriter(f, fieldnames=["id", "name", "type", "formula", "weight", "cas", "iupac", "inchi", "smiles", "atc_primary", "atc_others", "links", "url"])
            w.writeheader()
            for d_id, d_val in self.results.items():
                m = d_val["metadata"]
                atcs = m.get("atc", [])
                w.writerow({
                    "id": d_id, "name": m.get("name", ""), "type": m.get("type", ""), "formula": m.get("formula", ""),
                    "weight": m.get("weight", ""), "cas": m.get("cas", ""), "iupac": m.get("iupac", ""), "inchi": m.get("inchi", ""),
                    "smiles": m.get("smiles", ""), "atc_primary": atcs[0]["code"] if atcs else "",
                    "atc_others": "; ".join([x["code"] for x in atcs[1:]]),
                    "links": "; ".join([f"{k}: {v}" for k,v in m.get("links", {}).items()]),
                    "url": m.get("url", "")
                })

        # Interactions
        with open("ddinter_interactions_v6.csv", "w", newline='', encoding='utf-8') as f:
            w = csv.DictWriter(f, fieldnames=["drug_a_id", "drug_a_name", "drug_b_id", "drug_b_name", "severity", "mechanisms", "description", "management", "idx", "references", "url"])
            w.writeheader()
            for d_id, d_val in self.results.items():
                name_a = d_val["metadata"].get("name", "")
                for inter in d_val["interactions"]:
                    w.writerow({
                        "drug_a_id": d_id, "drug_a_name": name_a, "drug_b_id": inter.get("drug_id", ""), "drug_b_name": inter.get("drug_name", ""),
                        "severity": inter.get("severity", inter.get("level", "")), "mechanisms": "; ".join(inter.get("mechanisms", [])),
                        "description": inter.get("description", ""), "management": inter.get("management", ""),
                        "idx": inter.get("interaction_id", ""), "references": " | ".join(inter.get("references", [])),
                        "url": INTERACT_DETAIL_URL.format(id=inter.get("interaction_id", ""))
                    })
        print(">>> ALL FILES EXPORTED SUCCESSFULLY.", flush=True)

if __name__ == "__main__":
    def get_test_ids():
        try:
            with open("unique_drugs.json", "r") as f:
                return json.load(f)["unique_drugs"][:5]
        except:
            return ["DDInter20", "DDInter1", "DDInter2", "DDInter3", "DDInter4"]

    print(">>> DDInter Scraper V6 Starting...", flush=True)
    scraper = DDInterScraperV6(get_test_ids())
    # MANDATORY LIMIT FOR TEST PHASE TO PREVENT HANGS
    scraper.run(limit_interactions=10)
    scraper.export_csv()
    print(">>> SCRIPT COMPLETED.", flush=True)
