import sys
import os
import random
import time
import datetime
import concurrent.futures
import threading
import subprocess
import requests
from bs4 import BeautifulSoup
import urllib3
import json
import csv
import re

print(">>> DDInter Scraper V7-GitHub: CHECKPOINT MODE ACTIVATED", flush=True)
print(">>> MODE: Auto-Commit every 100 drugs to survive 6-hour limit", flush=True)
print(">>> MAXIMUM SPEED + GLOBAL CACHING + THREADING", flush=True)

# Disable SSL warnings
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Session with Auto-Retry
session = requests.Session()
retries = urllib3.util.Retry(total=2, backoff_factor=0.5, status_forcelist=[429, 500, 502, 503, 504])
session.mount('https://', requests.adapters.HTTPAdapter(max_retries=retries, pool_maxsize=50))
session.verify = False

BASE_URL = "https://ddinter2.scbdd.com"
DRUG_DETAIL_URL = f"{BASE_URL}/server/drug-detail/{{id}}/"
INTERACT_API_URL = f"{BASE_URL}/server/interact-with/{{id}}/"
FOOD_API_URL = f"{BASE_URL}/server/interact-with-food/{{id}}/"
DISEASE_API_URL = f"{BASE_URL}/server/interact-with-disease/{{id}}/"
INTERACT_DETAIL_URL = f"{BASE_URL}/server/interact/{{id}}/"
METABOLISM_API_URL = f"{BASE_URL}/server/linkmarker/{{id}}/"
COMPOUND_PREP_API_URL = f"{BASE_URL}/server/mix-with/{{id}}/"

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    "X-Requested-With": "XMLHttpRequest",
    "Accept": "application/json, text/javascript, */*; q=0.01",
    "Accept-Language": "en-US,en;q=0.9",
    "Connection": "keep-alive"
}

def clean_text(text):
    if not text: return ""
    return " ".join(text.replace("\n", " ").split()).strip()

def auto_commit_checkpoint(message, file_paths):
    """Auto-commit progress to GitHub during scraping"""
    try:
        print(f"\n>>> [CHECKPOINT] {message}", flush=True)
        # Add files
        for fp in file_paths:
            subprocess.run(["git", "add", fp], check=False, capture_output=True)
        # Commit
        result = subprocess.run(
            ["git", "commit", "-m", f"Checkpoint: {message} [skip ci]"],
            check=False,
            capture_output=True,
            text=True
        )
        if result.returncode == 0:
            # Push
            subprocess.run(["git", "push"], check=False, capture_output=True)
            print(f">>> [CHECKPOINT] Committed and pushed successfully", flush=True)
        else:
            print(f">>> [CHECKPOINT] No changes to commit", flush=True)
    except Exception as e:
        print(f">>> [CHECKPOINT ERROR] {e}", flush=True)

class DDInterScraperV7GitHub:
    def __init__(self, drug_ids, output_json="ddinter_exhaustive_v7.json", cache_json="ddinter_inter_cache.json"):
        self.drug_ids = drug_ids
        self.output_json = output_json
        self.cache_json = cache_json
        self.results = {}
        self.inter_cache = {}
        self.lock = threading.Lock()
        self.checkpoint_every = 100  # Auto-commit every 100 drugs
        
        # Load existing results
        if os.path.exists(self.output_json):
            try:
                with open(self.output_json, "r", encoding='utf-8') as f:
                    self.results = json.load(f)
                print(f">>> Resumed: {len(self.results)} drugs loaded", flush=True)
            except: pass
            
        # Load interaction cache
        if os.path.exists(self.cache_json):
            try:
                with open(self.cache_json, "r", encoding='utf-8') as f:
                    self.inter_cache = json.load(f)
                print(f">>> Cache: {len(self.inter_cache)} interactions loaded", flush=True)
            except: pass

    def save(self):
        with self.lock:
            with open(self.output_json, "w", encoding='utf-8') as f:
                json.dump(self.results, f, indent=2, ensure_ascii=False)
            with open(self.cache_json, "w", encoding='utf-8') as f:
                json.dump(self.inter_cache, f, indent=2, ensure_ascii=False)

    def fetch_api_data(self, url, referer, silent=False):
        if not silent: print(f"  [API] {url}", flush=True)
        payload = {"draw": "1", "start": "0", "length": "5000", "search[value]": "", "search[regex]": "false"}
        h = {**HEADERS, "Referer": referer}
        try:
            if "linkmarker" in url or "mix-with" in url:
                res = session.get(url, headers=h, timeout=30)
            else:
                res = session.post(url, headers=h, data=payload, timeout=30)
            
            if res.status_code == 200:
                data = res.json()
                results = data.get("data", data)
                if not silent: print(f"  [OK] {len(results)} items", flush=True)
                return results
            elif res.status_code == 404:
                if not silent: print(f"  [404] Endpoint not available", flush=True)
            else:
                if not silent: print(f"  [!] HTTP {res.status_code}", flush=True)
        except Exception as e:
            if not silent: print(f"  [ERR] {str(e)[:60]}", flush=True)
        return []

    def scrape_drug_metadata(self, drug_id):
        url = DRUG_DETAIL_URL.format(id=drug_id)
        try:
            res = session.get(url, headers=HEADERS, timeout=30)
            if res.status_code != 200: return {}
            soup = BeautifulSoup(res.text, 'html.parser')
            meta = {"id": drug_id, "url": url, "name": "Unknown"}
            
            alert = soup.find('div', role='alert')
            if alert:
                text = alert.get_text()
                if "Drugs Information:" in text:
                    meta["name"] = clean_text(text.split("Drugs Information:")[-1])
            
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
        except: return {}

    def scrape_interaction_details(self, inter_idx):
        idx_str = str(inter_idx)
        # Global Cache Check
        if idx_str in self.inter_cache:
            return self.inter_cache[idx_str]

        url = INTERACT_DETAIL_URL.format(id=inter_idx)
        try:
            res = session.get(url, headers=HEADERS, timeout=30)
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
            
            # Update Cache
            with self.lock:
                self.inter_cache[idx_str] = detail
            return detail
        except: return {}

    def run(self):
        total_drugs = len(self.drug_ids)
        start_time = time.time()
        drugs_processed = 0
        last_checkpoint = 0
        
        for i, drug_id in enumerate(self.drug_ids):
            if drugs_processed > 0:
                elapsed = time.time() - start_time
                avg_time = elapsed / drugs_processed
                remaining = total_drugs - i
                eta_seconds = avg_time * remaining
                eta_str = str(datetime.timedelta(seconds=int(eta_seconds)))
                print(f"\n[{i+1}/{total_drugs}] {drug_id} | Processed: {drugs_processed} | ETA: {eta_str}", flush=True)
            else:
                print(f"\n[{i+1}/{total_drugs}] {drug_id}", flush=True)
            
            if drug_id in self.results and self.results[drug_id].get("status") == "completed":
                continue

            meta = self.scrape_drug_metadata(drug_id)
            if not meta: continue
            
            ref = meta.get("url")
            drug_data = {
                "metadata": meta,
                "food": [], "disease": [], "metabolism": [], "compound_prep": [],
                "interactions": [],
                "status": "partial"
            }
            self.results[drug_id] = drug_data
            self.save()

            # Secondary APIs (silent mode to reduce log spam)
            drug_data["food"] = self.fetch_api_data(FOOD_API_URL.format(id=drug_id), ref, silent=True)
            drug_data["disease"] = self.fetch_api_data(DISEASE_API_URL.format(id=drug_id), ref, silent=True)
            drug_data["metabolism"] = self.fetch_api_data(METABOLISM_API_URL.format(id=drug_id), ref, silent=True)
            drug_data["compound_prep"] = self.fetch_api_data(COMPOUND_PREP_API_URL.format(id=drug_id), ref, silent=True)
            self.save()

            raw_list = self.fetch_api_data(INTERACT_API_URL.format(id=drug_id), ref)
            total_inter = len(raw_list)
            
            if total_inter > 0:
                ids_to_fetch = [item.get("interaction_id") for item in raw_list if item.get("interaction_id")]
                cached = sum(1 for idx in ids_to_fetch if str(idx) in self.inter_cache)
                print(f"  [Cache Hit: {cached}/{len(ids_to_fetch)}] Fetching {len(ids_to_fetch)-cached} with 20 threads", flush=True)
                
                with concurrent.futures.ThreadPoolExecutor(max_workers=20) as executor:
                    future_to_idx = {executor.submit(self.scrape_interaction_details, idx): idx for idx in ids_to_fetch}
                    details_map = {}
                    for future in concurrent.futures.as_completed(future_to_idx):
                        idx = future_to_idx[future]
                        try: details_map[idx] = future.result()
                        except: pass

                for item in raw_list:
                    idx = item.get("interaction_id")
                    details = details_map.get(idx, {})
                    drug_data["interactions"].append({**item, **details})
            
            drug_data["status"] = "completed"
            self.results[drug_id] = drug_data
            self.save()
            drugs_processed += 1
            
            # CHECKPOINT: Auto-commit every N drugs
            if drugs_processed - last_checkpoint >= self.checkpoint_every:
                auto_commit_checkpoint(
                    f"{drugs_processed} drugs completed ({len(self.inter_cache)} cached interactions)",
                    [self.output_json, self.cache_json]
                )
                last_checkpoint = drugs_processed

    def export_csv(self):
        print("\n>>> Exporting CSVs...", flush=True)
        # Metadata
        with open("ddinter_drugs_metadata_v7.csv", "w", newline='', encoding='utf-8') as f:
            w = csv.DictWriter(f, fieldnames=["id", "name", "type", "formula", "weight", "cas", "iupac", "inchi", "smiles", "atc_primary", "atc_others", "links", "url"])
            w.writeheader()
            for d_id, d_val in self.results.items():
                if d_val.get("status") != "completed": continue
                m = d_val["metadata"]; atcs = m.get("atc", [])
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
        
        # Food/Disease/CompoundPrep combined
        with open("ddinter_food_disease_metabolism_v7.csv", "w", newline='', encoding='utf-8') as f:
            w = csv.DictWriter(f, fieldnames=["drug_id", "drug_name", "type", "data"])
            w.writeheader()
            for d_id, d_val in self.results.items():
                if d_val.get("status") != "completed": continue
                name = d_val["metadata"].get("name", "")
                for food in d_val.get("food", []):
                    w.writerow({"drug_id": d_id, "drug_name": name, "type": "food", "data": json.dumps(food, ensure_ascii=False)})
                for disease in d_val.get("disease", []):
                    w.writerow({"drug_id": d_id, "drug_name": name, "type": "disease", "data": json.dumps(disease, ensure_ascii=False)})
                for metab in d_val.get("metabolism", []):
                    w.writerow({"drug_id": d_id, "drug_name": name, "type": "metabolism", "data": json.dumps(metab, ensure_ascii=False)})
                for comp in d_val.get("compound_prep", []):
                    w.writerow({"drug_id": d_id, "drug_name": name, "type": "compound_preparation", "data": json.dumps(comp, ensure_ascii=False)})
        print(">>> CSV Export Complete", flush=True)

if __name__ == "__main__":
    def get_full_ids():
        with open("unique_drugs.json", "r") as f:
            return json.load(f)["unique_drugs"]
    scraper = DDInterScraperV7GitHub(get_full_ids())
    scraper.run()
    scraper.export_csv()
    
    # Final checkpoint
    auto_commit_checkpoint(
        "Scraping completed - Final export",
        ["ddinter_exhaustive_v7.json", "ddinter_inter_cache.json", 
         "ddinter_drugs_metadata_v7.csv", "ddinter_interactions_v7.csv",
         "ddinter_food_disease_metabolism_v7.csv"]
    )
    print(">>> COMPLETE", flush=True)
