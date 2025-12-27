import requests
from bs4 import BeautifulSoup
import urllib3
import time

# Disable SSL warnings (for the expired certificate)
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

BASE_URLS = [
    "https://ddinter2.scbdd.com/ddi/detail/{id}/",
    "https://ddinter2.scbdd.com/server/interaction/detail/{id}/",
    "https://ddinter2.scbdd.com/server/interaction/{id}/",
    "https://ddinter2.scbdd.com/ddinter/interaction-detail/{id}/"
]

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
}

def test_urls():
    # Test IDs 1 to 5
    for i in range(1, 6):
        for base in BASE_URLS:
            url = base.format(id=i)
            print(f"Testing URL: {url}")
            try:
                response = requests.get(url, headers=HEADERS, verify=False, timeout=10)
                if response.status_code == 200:
                    print(f"SUCCESS (200) for {url}")
                    soup = BeautifulSoup(response.text, 'html.parser')
                    # Look for clues in the title or common interaction fields
                    title = soup.title.string if soup.title else "No Title"
                    print(f"Title: {title.strip()}")
                    # Check for "Mechanism" or "Management"
                    if "Mechanism" in response.text or "Management" in response.text:
                        print("Found Mechanism/Management content!")
                        return url
                else:
                    print(f"Failed with status code: {response.status_code}")
            except Exception as e:
                print(f"Error testing {url}: {e}")
            time.sleep(1)
    return None

if __name__ == "__main__":
    winner = test_urls()
    if winner:
        print(f"\nWinner found: {winner}")
    else:
        print("\nNo common pattern found. Need more research.")
