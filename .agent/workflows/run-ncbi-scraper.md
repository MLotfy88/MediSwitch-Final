---
description: Run NCBI StatPearls scraper with auto-resume and git safety
---

This workflow manages the high-volume scraping of NCBI data.

1.  **Check/Generate Targets**:
    Ensure `scripts/statpearls_scraper/targets.csv` exists. If not, generate it.
    ```bash
    if [ ! -f "scripts/statpearls_scraper/targets.csv" ]; then
        echo "Generating targets..."
        python3 scripts/statpearls_scraper/generate_targets.py
    else
        echo "Targets file exists. Skipping generation."
    fi
    ```

2.  **Run Async Scraper**:
    Run the high-speed scraper. It has built-in resume logic (checks for existing JSON files).
    // turbo
    ```bash
    python3 scripts/statpearls_scraper/async_scraper.py
    ```

3.  **Commit Progress**:
    Commit the scraped data to the repository.
    // turbo
    ```bash
    git add scripts/statpearls_scraper/scraped_data/
    git commit -m "feat(data): update ncbi statpearls scraped data" || echo "No changes to commit"
    ```

4.  **Verify Results**:
    Check how many files were scraped.
    // turbo
    ```bash
    find scripts/statpearls_scraper/scraped_data/ -name "*.json" | wc -l
    ```
