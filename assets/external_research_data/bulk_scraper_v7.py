import sys
import os
import random
import time

# Immediate unbuffered output
print(">>> DDInter Scraper V7: BOOTING UP...", flush=True)
print(">>> MODE: FULL DATA EXTRACTION (NO LIMITS)", flush=True)
print(">>> BEHAVIOR: HUMAN-LIKE DELAYS (20-35s) ENABLED", flush=True)

import requests
from bs4 import BeautifulSoup
import urllib3
import json
import csv
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
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "X-Requested-With": "XMLHttpRequest",
    "Accept": "application/json, text/javascript, */*; q=0.01",
    "Accept-Language": "en-US,en;q=0.9",
    "Connection": "keep-alive"
}

def clean_text(text):
    if not text: return ""
    return " ".join(text.replace("\n", " ").split()).strip()

def human_delay():
    delay = random.uniform(20, 35)
    print(f"  [Stealth] Waiting {delay:.2f} seconds to mimic human behavior...", flush=True)
    time.sleep(delay)

class DDInterScraperV7:
    def __init__(self, drug_ids, output_json="ddinter_exhaustive_v7.json"):
        self.drug_ids = drug_ids
        self.output_json = output_json
        self.results = {}
        if os.path.exists(self.output_json):
            try:
                with open(self.output_json, "r", encoding='utf-8') as f:
                    self.results = json.load(f)
                print(f">>> Resumed from existing {self.output_json} ({len(self.results)} drugs loaded)", flush=True)
            except: pass

    def save(self):
        with open(self.output_json, "w", encoding='utf-8') as f:
            json.dump(self.results, f, indent=2, ensure_ascii=False)

    def fetch_api_data(self, url, referer):
        print(f"  [AJAX Log] Initializing Request: {url}", flush=True)
        payload = {"draw": "1", "start": "0", "length": "5000", "search[value]": "", "search[regex]": "false"}
        h = {**HEADERS, "Referer": referer}
        try:
            if "linkmarker" in url:
                res = requests.get(url, headers=h, verify=False, timeout=60)
            else:
                res = requests.post(url, headers=h, data=payload, verify=False, timeout=60)
            
            if res.status_code == 200:
                data = res.json()
                results = data.get("data", data)
                print(f"  [AJAX Success] Captured {len(results)} items from API.", flush=True)
                return results
            else:
                print(f"  [AJAX Warning] HTTP {res.status_code} received for {url}", flush=True)
        except Exception as e:
            print(f"  [AJAX Critical Error] {e}", flush=True)
        return []

    def scrape_drug_metadata(self, drug_id):
        url = DRUG_DETAIL_URL.format(id=drug_id)
        print(f"  [Metadata Log] Accessing Detail Page: {url}", flush=True)
        try:
            res = requests.get(url, headers=HEADERS, verify=False, timeout=60)
            if res.status_code != 200: 
                print(f"  [Metadata Warning] Failed to load page. Status: {res.status_code}", flush=True)
                return {}
            
            soup = BeautifulSoup(res.text, 'html.parser')
            meta = {"id": drug_id, "url": url, "name": "Unknown"}
            
            # Name Extraction
            alert = soup.find('div', role='alert')
            if alert:
                text = alert.get_text()
                if "Drugs Information:" in text:
                    meta["name"] = clean_text(text.split("Drugs Information:")[-1])
                    print(f"  [Metadata Success] Identified Drug Name: {meta['name']}", flush=True)
            
            # Table Data
            table = soup.find('table', class_='table-bordered')
            if table:
                found_keys = 0
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
                        found_keys += 1
                print(f"  [Metadata Success] Extracted {found_keys} properties from table.", flush=True)
            return meta
        except Exception as e:
            print(f"  [Metadata Error] {e}", flush=True)
        return {}

    def scrape_interaction_details(self, inter_idx):
        url = INTERACT_DETAIL_URL.format(id=inter_idx)
        try:
            res = requests.get(url, headers=HEADERS, verify=False, timeout=60)
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
            print(f"    [Interaction Detail Error] Index {inter_idx}: {e}", flush=True)
        return {}

    def run(self):
        total_drugs = len(self.drug_ids)
        start_time = time.time()
        drugs_processed_this_session = 0
        
        import datetime

        for i, drug_id in enumerate(self.drug_ids):
            # ETA Calculation
            if drugs_processed_this_session > 0:
                elapsed = time.time() - start_time
                avg_time = elapsed / drugs_processed_this_session
                remaining = total_drugs - i
                eta_seconds = avg_time * remaining
                eta_str = str(datetime.timedelta(seconds=int(eta_seconds)))
                print(f"\n[{i+1}/{total_drugs}] >>> TARGET ACQUISITION: {drug_id} | ETA: {eta_str}", flush=True)
            else:
                print(f"\n[{i+1}/{total_drugs}] >>> TARGET ACQUISITION: {drug_id}", flush=True)
            
            # Robust Resume check - check for 'completed' flag
            if drug_id in self.results and self.results[drug_id].get("status") == "completed":
                print(f"  [Resume] {drug_id} already fully processed. Skipping.", flush=True)
                continue

            # STEP 1: Metadata
            meta = self.scrape_drug_metadata(drug_id)
            if not meta: 
                print(f"  [Critical] Failed to acquire target metadata. Moving to next.", flush=True)
                continue
            
            ref = meta.get("url")
            drug_data = {
                "metadata": meta,
                "food": [], "disease": [], "metabolism": [], "interactions": [],
                "status": "partial" # Mark as partial during scraping
            }
            # Initial save of partial record
            self.results[drug_id] = drug_data
            self.save()

            # HUMAN DELAY BEFORE NEXT REQUEST
            human_delay()

            # STEP 2: Secondary APIs (Food, Disease, Metabolism)
            print(f"  [Discovery Log] Scanning secondary data (Food/Disease/Metabolism)...", flush=True)
            drug_data["food"] = self.fetch_api_data(FOOD_API_URL.format(id=drug_id), ref)
            self.save() # Auto-save
            human_delay()
            
            drug_data["disease"] = self.fetch_api_data(DISEASE_API_URL.format(id=drug_id), ref)
            self.save() # Auto-save
            human_delay()
            
            drug_data["metabolism"] = self.fetch_api_data(METABOLISM_API_URL.format(id=drug_id), ref)
            self.save() # Auto-save
            human_delay()

            # STEP 3: Interactions Discovery
            raw_list = self.fetch_api_data(INTERACT_API_URL.format(id=drug_id), ref)
            total_inter = len(raw_list)
            print(f"  [Interaction Log] Found {total_inter} primary drug-drug interactions.", flush=True)
            
            # STEP 4: Deep Interaction Scraping
            for j, item in enumerate(raw_list):
                idx = item.get("interaction_id")
                if not idx: continue
                
                print(f"    ({j+1}/{total_inter}) -> Deep Scraping Interaction ID: {idx}", flush=True)
                details = self.scrape_interaction_details(idx)
                drug_data["interactions"].append({**item, **details})
                
                # Auto-save every 10 interactions for safety if it's a long list
                if j % 10 == 0:
                    self.save()

                # HUMAN DELAY BETWEEN INTERACTIONS (TO BE SAFE IF LIST IS LONG)
                if j < total_inter - 1:
                    human_delay()
            
            # Finalize drug
            drug_data["status"] = "completed"
            self.results[drug_id] = drug_data
            self.save()
            drugs_processed_this_session += 1
            print(f"  [Persistence Success] Core data for {drug_id} committed to {self.output_json}.", flush=True)
            
            # ADDITIONAL COOLDOWN BETWEEN DRUGS
            print(f"  [Phase Transition] Moving to next drug target...", flush=True)
            human_delay()

    def export_csv(self):
        print("\n>>> FINALIZING DATA STRUCTURES FOR CSV EXPORT...", flush=True)
        # Metadata
        with open("ddinter_drugs_metadata_v7.csv", "w", newline='', encoding='utf-8') as f:
            w = csv.DictWriter(f, fieldnames=["id", "name", "type", "formula", "weight", "cas", "iupac", "inchi", "smiles", "atc_primary", "atc_others", "links", "url"])
            w.writeheader()
            for d_id, d_val in self.results.items():
                if d_val.get("status") != "completed": continue
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
        with open("ddinter_interactions_v7.csv", "w", newline='', encoding='utf-8') as f:
            w = csv.DictWriter(f, fieldnames=["drug_a_id", "drug_a_name", "drug_b_id", "drug_b_name", "severity", "mechanisms", "description", "management", "idx", "references", "url"])
            w.writeheader()
            for d_id, d_val in self.results.items():
                if d_val.get("status") != "completed": continue
                name_a = d_val["metadata"].get("name", "")
                for inter in d_val["interactions"]:
                    w.writerow({
                        "drug_a_id": d_id, "drug_a_name": name_a, "drug_b_id": inter.get("drug_id", ""), "drug_b_name": inter.get("drug_name", ""),
                        "severity": inter.get("severity", inter.get("level", "")), "mechanisms": "; ".join(inter.get("mechanisms", []) if isinstance(inter.get("mechanisms"), list) else []),
                        "description": inter.get("description", ""), "management": inter.get("management", ""),
                        "idx": inter.get("interaction_id", ""), "references": " | ".join(inter.get("references", [])),
                        "url": INTERACT_DETAIL_URL.format(id=inter.get("interaction_id", ""))
                    })
        print(">>> SUCCESS: CSV OUTPUTS GENERATED AT /V7 PATHS.", flush=True)

if __name__ == "__main__":
    def get_full_ids():
        try:
            with open("unique_drugs.json", "r") as f:
                return json.load(f)["unique_drugs"]
        except:
            # Fallback to test set if file missing
            return ["DDInter20", "DDInter1", "DDInter2", "DDInter3", "DDInter4"]

    print(">>> INITIALIZING DDINTER SCRAPER V7...", flush=True)
    # Full run on all IDs found in the registry
    target_ids = get_full_ids()
    
    print(f">>> SCOPE: {len(target_ids)} DRUGS DETECTED FOR EXTRACTION.", flush=True)
    scraper = DDInterScraperV7(target_ids)
    scraper.run()
    scraper.export_csv()
    print(">>> PROCESS CONCLUDED. ALL DATA CAPTURED.", flush=True)
