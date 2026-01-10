#!/usr/bin/env python3
"""
Get ALL pages from ALL WikEM categories
"""

import requests
from bs4 import BeautifulSoup
import time
import sys

# All major WikEM categories
CATEGORIES = [
    'Pharmacology',
    'Toxicology',
    'Critical_Care',
    'Cardiology',
    'Neurology',
    'ID',  # Infectious Disease
    'Heme/Onc',
    'Endocrinology',
    'GI',
    'Pulmonary',
    'Renal',
    'Psychiatry',
    'Pediatrics',
    'OBGYN',
    'ENT',
    'Ophthalmology',
    'Dermatology',
    'Orthopedics',
    'Surgery',
    'Trauma',
    # 'Emergency_Medicine', # Removed: Page does not exist (404)
    'Procedures',
    'Rheumatology',
    'Urology',
    'Vascular',
    'Sports_Medicine',
    'Palliative_Medicine',
    'Tropical_Medicine',
    'Space_Medicine',
    'Military',
    'EMS'
]

def get_category_pages(category_name):
    """Fetch all pages from a specific category"""
    base_url = f"https://wikem.org/w/index.php?title=Category:{category_name}"
    pages = set()
    
    print(f"Fetching {category_name}...", file=sys.stderr)
    url = base_url
    page_num = 1
    
    while url:
        time.sleep(2)  # Be polite
        
        try:
            response = requests.get(url, timeout=30)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Find the category members
            content_div = soup.find('div', id='mw-pages')
            if not content_div:
                break
            
            # Extract page links
            for link in content_div.find_all('a'):
                href = link.get('href', '')
                if href.startswith('/wiki/') and ':' not in href:
                    page_name = href.replace('/wiki/', '')
                    if page_name not in ['Main_Page', category_name]:
                        pages.add(page_name)
            
            # Check for next page
            next_link = soup.find('a', string='next page')
            if next_link and next_link.get('href'):
                url = 'https://wikem.org' + next_link['href']
                page_num += 1
            else:
                break
                
        except Exception as e:
            print(f"Error fetching {category_name}: {e}", file=sys.stderr)
            break
    
    print(f"  → {len(pages)} pages", file=sys.stderr)
    return pages

if __name__ == "__main__":
    all_pages = set()
    
    print("Fetching pages from ALL WikEM categories...", file=sys.stderr)
    print("=" * 60, file=sys.stderr)
    
    for category in CATEGORIES:
        category_pages = get_category_pages(category)
        all_pages.update(category_pages)
    
    print("=" * 60, file=sys.stderr)
    print(f"Total unique pages: {len(all_pages)}", file=sys.stderr)
    
    # Output to stdout (one per line)
    for page in sorted(all_pages):
        print(page)
