#!/usr/bin/env python3
"""
Get complete drug list from WikEM Category:Pharmacology
"""

import requests
from bs4 import BeautifulSoup
import time
import sys

def get_all_drugs():
    """Fetch all drug names from WikEM Pharmacology category"""
    
    base_url = "https://wikem.org/w/index.php?title=Category:Pharmacology"
    drugs = set()
    
    print("Fetching drug list from WikEM Category:Pharmacology...", file=sys.stderr)
    
    # WikEM might paginate results, so we need to handle continuation
    url = base_url
    page = 1
    
    while url:
        time.sleep(2)  # Be polite
        print(f"Fetching page {page}...", file=sys.stderr)
        
        try:
            response = requests.get(url, timeout=30)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Find the category members div
            content_div = soup.find('div', id='mw-pages')
            if not content_div:
                break
            
            # Extract drug links
            for link in content_div.find_all('a'):
                href = link.get('href', '')
                if href.startswith('/wiki/') and ':' not in href:
                    drug_name = href.replace('/wiki/', '')
                    # Filter out meta pages
                    if drug_name not in ['Main_Page', 'Pharmacology', 'Category:Pharmacology']:
                        drugs.add(drug_name)
            
            # Check for next page
            next_link = soup.find('a', string='next page')
            if next_link and next_link.get('href'):
                url = 'https://wikem.org' + next_link['href']
                page += 1
            else:
                break
                
        except Exception as e:
            print(f"Error fetching page: {e}", file=sys.stderr)
            break
    
    return sorted(drugs)

if __name__ == "__main__":
    drugs = get_all_drugs()
    print(f"Found {len(drugs)} drugs", file=sys.stderr)
    
    # Output to stdout (one per line)
    for drug in drugs:
        print(drug)
