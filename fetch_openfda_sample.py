#!/usr/bin/env python3
import requests
import json
import sys

def main():
    url = "https://api.fda.gov/drug/label.json?limit=1"
    print(f"Fetching sample from {url}...")
    
    try:
        resp = requests.get(url, timeout=10)
        resp.raise_for_status()
        data = resp.json()
        
        results = data.get('results', [])
        if not results:
            print("No results found!")
            return
            
        rec = results[0]
        
        # Save raw
        with open('openfda_sample.json', 'w') as f:
            json.dump(rec, f, indent=2)
            
        print("Saved openfda_sample.json")
        
        # Check Dosage Section
        print("\n--- Dosage Section ---")
        dosage = rec.get('dosage_and_administration', [])
        print(f"Type: {type(dosage)}")
        print(f"Content: {dosage}")
        
        # Check Structured fields?
        print("\n--- OpenFDA Fields ---")
        openfda = rec.get('openfda', {})
        print(f"Brand Name: {openfda.get('brand_name')}")
        print(f"Generic Name: {openfda.get('generic_name')}")
        print(f"Product Type: {openfda.get('product_type')}")
        print(f"Route: {openfda.get('route')}")
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == '__main__':
    main()
