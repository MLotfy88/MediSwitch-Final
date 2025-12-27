from bulk_scraper_v6 import DDInterScraperV6
import os

if __name__ == "__main__":
    print("Running rapid local verification for V6 (Aspirin)...")
    if os.path.exists("ddinter_exhaustive_v6.json"):
        os.remove("ddinter_exhaustive_v6.json")
        
    scraper = DDInterScraperV6(["DDInter20"])
    # VERIFY WITH JUST 3 INTERACTIONS
    scraper.run(limit_interactions=3)
    scraper.export_csv()
    print("Verification complete.")
