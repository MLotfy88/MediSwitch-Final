
import json
import os
import sys

try:
    with open('scripts/wikem_scraper/checkpoints/progress.json') as f:
        data = json.load(f)
        
    summary_file = os.environ.get('GITHUB_STEP_SUMMARY')
    if summary_file:
        with open(summary_file, 'a') as f:
            f.write(f"- **Scraped:** {data.get('total_scraped', 0)}\n")
            f.write(f"- **Failed:** {data.get('total_failed', 0)}\n")
            f.write(f"- **Last Updated:** {data.get('last_updated', 'N/A')}\n")
except Exception as e:
    print(f"Error generating summary: {e}")
