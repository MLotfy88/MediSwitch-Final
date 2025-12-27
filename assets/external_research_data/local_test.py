from bulk_scraper_v3 import DDInterScraperV3
import json

class TestScraper(DDInterScraperV3):
    def run(self):
        for drug_id in self.drug_ids:
            print(f"Scraping Drug: {drug_id}...")
            # 1. Base Metadata
            metadata = self.scrape_drug_metadata(drug_id)
            
            # 2. Food/Disease/Metabolism API Data
            print(f"  Fetching Food/Disease/Metabolism for {drug_id}...")
            food = self.fetch_api_data("https://ddinter2.scbdd.com/server/interact-with-food/{id}/".format(id=drug_id))
            disease = self.fetch_api_data("https://ddinter2.scbdd.com/server/interact-with-disease/{id}/".format(id=drug_id))
            metabolism = self.fetch_api_data("https://ddinter2.scbdd.com/server/linkmarker/{id}/".format(id=drug_id))
            
            drug_data = {
                "metadata": metadata,
                "food_interactions": food,
                "disease_interactions": disease,
                "metabolism_data": metabolism,
                "interactions": []
            }
            
            # 3. Drug-Drug Interactions Discovery & Deep Scrape
            print(f"  Discovering DDI for {drug_id}...")
            raw_inter_list = self.fetch_api_data("https://ddinter2.scbdd.com/server/interact-with/{id}/".format(id=drug_id))
            
            # LIMIT TO 2 FOR RAPID LOCAL TEST
            for item in raw_inter_list[:2]:
                idx = item.get("id")
                print(f"    Deep scraping interaction [{idx}]...")
                details = self.scrape_interaction_details(idx)
                details.update(item)
                drug_data["interactions"].append(details)
            
            self.results[drug_id] = drug_data

if __name__ == "__main__":
    print("Running rapid local verification for V3 (Aspirin)...")
    scraper = TestScraper(["DDInter20"])
    scraper.run()
    scraper.export()
    print("Verification complete.")
