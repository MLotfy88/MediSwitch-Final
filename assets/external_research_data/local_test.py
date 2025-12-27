from bulk_scraper_v5 import DDInterScraperV5
import json
import os

class TestScraper(DDInterScraperV5):
    def run(self):
        for drug_id in self.drug_ids:
            # We refresh to ensure we don't skip in local test if we want to see it again
            print(f"Scraping Drug: {drug_id}...")
            meta = self.scrape_drug_metadata(drug_id)
            if not meta: continue

            ref = meta.get("url")
            drug_data = {
                "metadata": meta,
                "food": self.fetch_api_data("https://ddinter2.scbdd.com/server/interact-with-food/{id}/".format(id=drug_id), ref),
                "disease": self.fetch_api_data("https://ddinter2.scbdd.com/server/interact-with-disease/{id}/".format(id=drug_id), ref),
                "metabolism": self.fetch_api_data("https://ddinter2.scbdd.com/server/linkmarker/{id}/".format(id=drug_id), ref),
                "interactions": []
            }
            
            print(f"  Discovery for {drug_id}...")
            raw_list = self.fetch_api_data("https://ddinter2.scbdd.com/server/interact-with/{id}/".format(id=drug_id), ref)
            
            # LIMIT TO 2 FOR RAPID LOCAL TEST
            for item in raw_list[:2]:
                idx = item.get("interaction_id")
                if not idx: continue
                print(f"    - [{idx}] vs {item.get('drug_name')}...")
                details = self.scrape_interaction_details(idx)
                # Merge logic
                full_inter = {**item, **details}
                drug_data["interactions"].append(full_inter)
            
            self.results[drug_id] = drug_data
            self.save()

if __name__ == "__main__":
    import os
    # Clear old V5 json for a fresh test if it exists
    if os.path.exists("ddinter_exhaustive_v5.json"):
        os.remove("ddinter_exhaustive_v5.json")
        
    print("Running local verification for V5 (Aspirin)...")
    scraper = TestScraper(["DDInter20"])
    scraper.run()
    scraper.export_csv()
    print("Verification complete.")
