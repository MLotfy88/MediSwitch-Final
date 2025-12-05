#!/usr/bin/env python3
"""
Complete OpenFDA Drug Interactions Downloader & Extractor
Downloads fresh data from OpenFDA and extracts all drug interactions
"""

import json
import os
import requests
import zipfile
import ijson
from typing import List, Dict
import re

# OpenFDA URLs
OPENFDA_URLS = [
    "https://download.open.fda.gov/drug/label/drug-label-0001-of-0013.json.zip",
    "https://download.open.fda.gov/drug/label/drug-label-0002-of-0013.json.zip",
    "https://download.open.fda.gov/drug/label/drug-label-0003-of-0013.json.zip",
    "https://download.open.fda.gov/drug/label/drug-label-0004-of-0013.json.zip",
    "https://download.open.fda.gov/drug/label/drug-label-0005-of-0013.json.zip",
    "https://download.open.fda.gov/drug/label/drug-label-0006-of-0013.json.zip",
    "https://download.open.fda.gov/drug/label/drug-label-0007-of-0013.json.zip",
    "https://download.open.fda.gov/drug/label/drug-label-0008-of-0013.json.zip",
    "https://download.open.fda.gov/drug/label/drug-label-0009-of-0013.json.zip",
    "https://download.open.fda.gov/drug/label/drug-label-0010-of-0013.json.zip",
    "https://download.open.fda.gov/drug/label/drug-label-0011-of-0013.json.zip",
    "https://download.open.fda.gov/drug/label/drug-label-0012-of-0013.json.zip",
    "https://download.open.fda.gov/drug/label/drug-label-0013-of-0013.json.zip",
]

def download_file(url: str, output_path: str, max_retries: int = 3) -> bool:
    """Download a file from URL with retry logic"""
    for attempt in range(max_retries):
        try:
            print(f"\nDownloading: {os.path.basename(url)}" + (f" (Attempt {attempt + 1}/{max_retries})" if attempt > 0 else ""))
            
            response = requests.get(url, stream=True, timeout=30)
            response.raise_for_status()
            
            total_size = int(response.headers.get('content-length', 0))
            downloaded = 0
            
            with open(output_path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    if chunk:  # filter out keep-alive chunks
                        f.write(chunk)
                        downloaded += len(chunk)
                        if total_size:
                            percent = (downloaded / total_size) * 100
                            print(f"  Progress: {percent:.1f}%", end='\r')
            
            print(f"  ✅ Downloaded: {downloaded / (1024**2):.1f} MB                    ")
            return True
            
        except Exception as e:
            print(f"  ❌ Error on attempt {attempt + 1}: {e}")
            if attempt < max_retries - 1:
                print(f"  🔄 Retrying in 5 seconds...")
                import time
                time.sleep(5)
            else:
                print(f"  ❌ Failed after {max_retries} attempts")
                return False
    
    return False

def extract_zip(zip_path: str, extract_to: str) -> str:
    """Extract ZIP file and return path to JSON"""
    try:
        print(f"Extracting: {os.path.basename(zip_path)}")
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(extract_to)
        
        # Find the JSON file
        json_file = zip_path.replace('.zip', '')
        if os.path.exists(json_file):
            print(f"  ✅ Extracted successfully")
            return json_file
        else:
            print(f"  ⚠️ JSON file not found after extraction")
            return None
    except Exception as e:
        print(f"  ❌ Error extracting: {e}")
        return None

def estimate_severity(text: str) -> str:
    """Estimate interaction severity"""
    text_lower = text.lower()
    if any(w in text_lower for w in ['contraindicated', 'do not use', 'life-threatening', 'avoid']):
        return 'contraindicated'
    elif any(w in text_lower for w in ['severe', 'serious']):
        return 'severe'
    elif any(w in text_lower for w in ['major', 'significant']):
        return 'major'
    elif any(w in text_lower for w in ['moderate', 'caution', 'monitor']):
        return 'moderate'
    else:
        return 'minor'

def extract_interactions_from_json(json_path: str) -> List[Dict]:
    """Extract interactions using streaming JSON parser"""
    interactions = []
    
    print(f"\nProcessing: {os.path.basename(json_path)}")
    
    try:
        with open(json_path, 'rb') as f:
            parser = ijson.items(f, 'results.item')
            
            count = 0
            for record in parser:
                count += 1
                
                # Get drug name
                openfda = record.get('openfda', {})
                drug_name = None
                
                if 'brand_name' in openfda and openfda['brand_name']:
                    drug_name = openfda['brand_name'][0]
                elif 'generic_name' in openfda and openfda['generic_name']:
                    drug_name = openfda['generic_name'][0]
                elif 'substance_name' in openfda and openfda['substance_name']:
                    drug_name = openfda['substance_name'][0]
                
                if not drug_name:
                    continue
                
                # Extract interaction texts
                interaction_texts = []
                
                # Check drug_interactions field
                if 'drug_interactions' in record:
                    interaction_texts.extend(record['drug_interactions'])
                
                # Check warnings
                if 'warnings' in record:
                    for warning in record['warnings']:
                        if 'interaction' in warning.lower():
                            interaction_texts.append(warning)
                
                # Check precautions
                if 'precautions' in record:
                    for precaution in record['precautions']:
                        if 'interaction' in precaution.lower():
                            interaction_texts.append(precaution)
                
                # Process interactions
                for text in interaction_texts:
                    if not text or len(text) < 30:
                        continue
                    
                    # Split into sentences
                    sentences = re.split(r'(?<=[.!?])\s+', text)
                    
                    for sentence in sentences:
                        if len(sentence) < 40:  # Skip very short
                            continue
                        
                        interaction = {
                            'ingredient1': drug_name.lower().strip(),
                            'ingredient2': 'multiple',
                            'severity': estimate_severity(sentence),
                            'type': 'pharmacodynamic' if 'effect' in sentence.lower() else 'pharmacokinetic',
                            'effect': sentence[:1000],
                            'arabic_effect': '',
                            'recommendation': '',
                            'arabic_recommendation': '',
                            'source': 'OpenFDA'
                        }
                        interactions.append(interaction)
                
                if count % 2000 == 0:
                    print(f"  Processed {count:,} records → {len(interactions):,} interactions")
        
        print(f"  ✅ Total: {len(interactions):,} interactions from {count:,} records")
        
    except Exception as e:
        print(f"  ❌ Error: {e}")
    
    return interactions

def main():
    download_dir = 'External_source/drug_interaction/drug-label/downloaded'
    # Use environment variable if set by GitHub Action, otherwise default
    output_file = os.environ.get('INTERACTIONS_OUTPUT', 'assets/data/drug_interactions.json')
    
    os.makedirs(download_dir, exist_ok=True)
    
    print("=" * 70)
    print("OpenFDA Drug Interactions Complete Extraction")
    print("=" * 70)
    
    all_interactions = []
    
    # Process ALL 13 files
    for i, url in enumerate(OPENFDA_URLS, 1):
        print(f"\n[{i}/{len(OPENFDA_URLS)}] Processing file {i}...")
        
        # Download
        zip_filename = os.path.basename(url)
        zip_path = os.path.join(download_dir, zip_filename)
        
        if not os.path.exists(zip_path):
            if not download_file(url, zip_path):
                continue
        else:
            print(f"  Using cached: {zip_filename}")
        
        # Extract
        json_path = extract_zip(zip_path, download_dir)
        if not json_path:
            continue
        
        # Extract interactions
        file_interactions = extract_interactions_from_json(json_path)
        all_interactions.extend(file_interactions)
        
        print(f"  Running total: {len(all_interactions):,} interactions")
    
    print("\n" + "=" * 70)
    print(f"Total interactions extracted: {len(all_interactions):,}")
    
    # Deduplicate
    unique_interactions = []
    seen = set()
    
    for interaction in all_interactions:
        key = (interaction['ingredient1'], interaction['effect'][:100])
        if key not in seen:
            seen.add(key)
            unique_interactions.append(interaction)
    
    print(f"Unique interactions: {len(unique_interactions):,}")
    
    # Save
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(unique_interactions, f, indent=2, ensure_ascii=False)
    
    print(f"\n✅ Saved to: {output_file}")
    print(f"   File size: {os.path.getsize(output_file) / (1024**2):.1f} MB")

if __name__ == '__main__':
    main()
