
import requests
from bs4 import BeautifulSoup
import time
import sys

# Sample ingredients from the DB
INGREDIENTS = [
    'Candesartan',
    'Flupentixol',
    'Ciclopirox',
    'Valaciclovir',
    'Metronidazole'
]

BASE_URL = "https://wikem.org/wiki/"

def get_wikem_dosage(ingredient):
    url = f"{BASE_URL}{ingredient}"
    print(f"\n🔍 Fetching: {ingredient} ({url})...")
    
    try:
        response = requests.get(url, timeout=10)
        if response.status_code == 404:
            print(f"❌ Page not found.")
            return
        
        soup = BeautifulSoup(response.content, 'html.parser')
        
        # WikEM structure usually uses h2 for headers
        # We look for "Adult Dosing" and "Pediatric Dosing"
        
        sections = ['Adult Dosing', 'Pediatric Dosing', 'Special Populations', 'Contraindications']
        found_data = False
        
        for section_name in sections:
            # Find the header span with the id (approximate match)
            # WikEM headers: <h2><span class="mw-headline" id="Adult_Dosing">Adult Dosing</span></h2>
            header_id = section_name.replace(' ', '_')
            header_span = soup.find('span', id=header_id)
            
            if header_span:
                found_data = True
                print(f"  👉 \033[1m{section_name}:\033[0m")
                # Get the content following the header until the next h2
                parent_h2 = header_span.parent
                next_node = parent_h2.next_sibling
                
                content_text = ""
                while next_node:
                    if next_node.name == 'h2':
                        break
                    
                    if next_node.name == 'h3':
                         # Keep h3 structure (e.g. "Renal Dosing")
                         text = next_node.get_text(separator=' ', strip=True)
                         if text:
                            content_text += f"\n    === {text} ===\n"

                    elif next_node.name in ['ul', 'li', 'p', 'div', 'dl']:
                        text = next_node.get_text(separator='\n', strip=True)
                        if text:
                            # Add indentation for readability
                            indented_text = '\n'.join(['     ' + line for line in text.split('\n') if line.strip()])
                            content_text += indented_text + "\n"
                    
                    next_node = next_node.next_sibling
                
                print(content_text)
        
        if not found_data:
            print("  ⚠️ No structured dosing sections found (might be a different template).")

    except Exception as e:
        print(f"❌ Error: {e}")
    
    time.sleep(1) # Be polite

if __name__ == "__main__":
    print("🚀 Starting WikEM Sampler...\n")
    for ing in INGREDIENTS:
        get_wikem_dosage(ing)
    print("\n✅ Sampling Complete.")
