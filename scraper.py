import requests
from bs4 import BeautifulSoup
import pandas as pd
import re
import time
import json
import sys

# --- Configuration ---
LOGIN_URL = "https://dwaprices.com/signin.php"
SERVER_URL = "https://dwaprices.com/server.php"
TARGET_URL = "https://dwaprices.com/lastmore.php"
OUTPUT_FILE = "meds_updated.csv"

# User Credentials (provided by user)
PHONE = "01558166440"
TOKEN = "bfwh2025-03-17"

# Regex for Concentration Extraction (from previous script)
CONCENTRATION_REGEX = re.compile(
    r"""
    (                          # Start capturing group 1
        \d+ (?:[.,]\d+)?       # Match number (integer or decimal with . or ,)
        \s*                    # Optional whitespace
        (?:mg|mcg|g|kg|ml|l|iu|%) # Match common units (case-insensitive)
        (?:                    # Optional second part for compound units (e.g., /ml)
            \s* / \s*          # Match '/' surrounded by optional spaces
            (?:ml|mg|g|kg|l)   # Match second unit (case-insensitive)
        )?
    )                          # End capturing group 1
    """,
    re.IGNORECASE | re.VERBOSE
)

def extract_concentration(name):
    """Extracts concentration from drug name using regex."""
    if not isinstance(name, str):
        return None
    match = CONCENTRATION_REGEX.search(name)
    if match:
        return match.group(1).strip()
    return None

def login(session):
    """Performs the two-step login process."""
    print("Attempting to login...")
    
    # Step 1: Check Credentials
    payload_step1 = {
        'checkLoginForPrices': 1,
        'phone': PHONE,
        'tokenn': TOKEN
    }
    
    try:
        response1 = session.post(SERVER_URL, data=payload_step1)
        response1.raise_for_status()
        
        try:
            data1 = response1.json()
        except json.JSONDecodeError:
            print("Error: Failed to parse JSON response from server.php")
            print("Response text:", response1.text[:200])
            return False

        if data1.get('numrows', 0) > 0 and 'data' in data1:
            user_data = data1['data'][0]
            print(f"Credentials verified for user: {user_data.get('name')}")
            
            # Step 2: Set Session
            payload_step2 = {
                'accessgranted': 1,
                'namepricesub': user_data.get('name'),
                'phonepricesub': user_data.get('phone'),
                'tokenpricesub': user_data.get('token'),
                'grouppricesub': user_data.get('usergroup'),
                'approvedsub': user_data.get('approved'),
                'IDpricesub': user_data.get('id')
            }
            
            response2 = session.post(LOGIN_URL, data=payload_step2)
            response2.raise_for_status()
            
            # Verify login by checking if we are redirected or if session cookies are set
            # For now, assume success if no error.
            print("Session established successfully.")
            return True
        else:
            print("Login failed: Invalid credentials or no data returned.")
            return False
            
    except Exception as e:
        print(f"Login error: {e}")
        return False

def scrape_data(session):
    """Scrapes data from the target page."""
    print(f"Accessing {TARGET_URL}...")
    
    all_meds = []
    page = 0
    has_more = True
    
    # The page seems to load more data via scrolling or a button. 
    # Based on standard PHP pagination, it might use a query param like ?page=X or ?offset=X.
    # However, the user said "click button to show rest". This often implies AJAX or a simple link.
    # Let's try to fetch the first page and see if we can find the "next" link or if it's all in one go (unlikely for large lists).
    # If it's a "Load More" button, it usually triggers an AJAX call.
    # Without inspecting the live page with DevTools, it's hard to know the exact pagination mechanism.
    # Strategy: 
    # 1. Fetch main page.
    # 2. Parse the table.
    # 3. Look for a "Load More" button and see what it does (e.g. data-page attribute, or href).
    
    # For this initial version, let's fetch the main page and try to find the pagination logic dynamically.
    
    response = session.get(TARGET_URL)
    if response.status_code != 200:
        print(f"Failed to load page: {response.status_code}")
        return []
    
    # Debug: Save HTML to file
    with open("lastmore_debug.html", "w", encoding="utf-8") as f:
        f.write(response.text)
    print("Saved page content to lastmore_debug.html")

    soup = BeautifulSoup(response.text, 'html.parser')
    
    # Find the table - based on user image, it has columns: No, Name, New Price, Old Price, Update
    # Inspecting temp_signin.html showed tables with class 'mytblnew' or id 'tblDrug'.
    # Let's look for a table.
    table = soup.find('table') 
    if not table:
        print("No table found on the page.")
        # Maybe it's loaded via AJAX?
        return []
        
    # Extract rows
    rows = table.find_all('tr')
    print(f"Found {len(rows)} rows in the initial table.")
    
    # Process rows (skip header if exists)
    for row in rows:
        cols = row.find_all('td')
        if not cols or len(cols) < 4:
            continue
            
        # Structure based on image:
        # Col 0: No
        # Col 1: Name (HTML contains Name, Arabic Name, etc.)
        # Col 2: New Price
        # Col 3: Old Price
        # Col 4: Update Date
        
        try:
            # Extract Name Info
            name_cell = cols[1]
            # The name cell seems to contain multiple lines (English, Arabic, ID, etc.)
            # We need to clean it.
            full_text = name_cell.get_text(separator=' ', strip=True)
            
            # Try to extract the English name (usually the first part or bolded)
            # Looking at the image: "Tineacure 1% top. cream 20 gm (2947) ..."
            # Let's take the text before the first parenthesis or Arabic char?
            # Simple approach: Take the whole text for now, or try to find the <a> tag inside which usually has the name.
            name_link = name_cell.find('a')
            if name_link:
                trade_name = name_link.get_text(strip=True)
                # If link text is empty, fallback to cell text
                if not trade_name:
                    trade_name = full_text.split('(')[0].strip() # Heuristic
            else:
                trade_name = full_text.split('(')[0].strip()
                
            # Extract Prices
            new_price = cols[2].get_text(strip=True)
            old_price = cols[3].get_text(strip=True)
            update_date = cols[4].get_text(strip=True)
            
            # Extract Concentration
            concentration = extract_concentration(trade_name)
            
            med_data = {
                'trade_name': trade_name,
                'price': new_price,
                'old_price': old_price,
                'last_price_update': update_date,
                'concentration': concentration,
                # 'full_text': full_text # Debugging
            }
            all_meds.append(med_data)
            
        except Exception as e:
            print(f"Error parsing row: {e}")
            continue

    print(f"Extracted {len(all_meds)} medicines from the first page.")
    
    # TODO: Implement Pagination
    # Since I can't interactively check the "Load More" button behavior without running it,
    # I will save what I have. The user can run this and tell me if it only got 100 items (likely).
    # If so, we'll need to update the script to handle the specific pagination of this site.
    
    return all_meds

def main():
    session = requests.Session()
    # Add headers to mimic a browser
    session.headers.update({
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    })
    
    if login(session):
        meds = scrape_data(session)
        
        if meds:
            df = pd.DataFrame(meds)
            print(f"Saving {len(df)} records to {OUTPUT_FILE}...")
            df.to_csv(OUTPUT_FILE, index=False, encoding='utf-8-sig')
            print("Done.")
        else:
            print("No data extracted.")
    else:
        print("Aborting due to login failure.")

if __name__ == "__main__":
    main()
