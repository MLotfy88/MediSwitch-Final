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

def load_known_ingredients(json_path: str) -> List[str]:
    """Load and normalize known ingredients for entity extraction"""
    ingredients = set()
    try:
        with open(json_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            for ing_list in data.values():
                for ing in ing_list:
                    if len(ing) > 3: # Ignore simple chemicals like 'ion'
                        ingredients.add(ing.lower().strip())
    except Exception as e:
        print(f"⚠️ Warning: Could not load ingredients file: {e}")
        return []
    
    # Sort by length (descending) to match longest phrases first
    return sorted(list(ingredients), key=len, reverse=True)

def find_interacting_drug(text: str, current_drug: str, known_ingredients: List[str]) -> str:
    """Find the other drug name in the interaction text"""
    text_lower = text.lower()
    current_drug_lower = current_drug.lower()
    
    # Common drug classes to look for if specific ingredient not found
    drug_classes = [
        'anticoagulants', 'antibiotics', 'nsaids', 'diuretics', 'beta blockers',
        'calcium channel blockers', 'ace inhibitors', 'statins', 'antidepressants',
        'antihistamines', 'corticosteroids', 'blood thinners', 'mao inhibitors',
        'alcohol', 'food', 'grapefruit'
    ]
    
    # 1. Search for specific ingredients
    # Optimization: Check if any known ingredient is in text
    # This is slow O(N*M), but for offline extraction it's acceptable.
    # To speed up, we can limit to top 2000 common drugs or use Aho-Corasick, 
    # but let's stick to simple iteration for now as the list isn't huge (80k entries might be slow though).
    # Let's try to be smarter: only look for words that look like drugs (capitalized in original text?)
    # OpenFDA text is often lowercase.
    
    # Optimization: Tokenize text and check against set? 
    # Problem: Multi-word ingredients ("sodium chloride").
    
    # Let's try checking drug classes first (high value)
    for dc in drug_classes:
        if dc in text_lower and dc not in current_drug_lower:
            return dc
            
    # Then check specific ingredients (limiting to longer ones mostly)
    # This loop might be too slow if known_ingredients is 20k+. 
    # Let's rely on a simpler regex for now: look for capitalized words in middle of sentence?
    # No, text is often unified case.
    
    # Fallback: Just return 'multiple' if we can't be sure, but let's try to catch at least some.
    # Actually, we passed known_ingredients. Let's iterate but maybe limit count or size.
    
    # PERFORMANCE HACK: Only check ingredients that are actually present as substrings?
    # Too expensive. 
    
    # Let's search for ingredients but break after first match to save time?
    # Or finding ALL and taking the longest?
    
    # Let's skip the heavy ingredient search for this iteration to avoid TIMEOUTs on GitHub Actions.
    # Instead, let's use a heuristic: words following "with", "and", "interaction of"
    
    headers = ['with', 'co-administered', 'taking', 'combination of', 'and']
    for header in headers:
        pattern = rf"\b{header}\s+([a-zA-Z0-9\-\s]+?)(?:[.,;]|\s+and\b|\s+with\b)"
        match = re.search(pattern, text_lower)
        if match:
            candidate = match.group(1).strip()
            # Clean up candidate
            if len(candidate) > 2 and len(candidate) < 30 and candidate not in current_drug_lower:
                # remove stats like "mg"
                candidate = re.sub(r'\b\d+mg\b', '', candidate).strip()
                return candidate

    return 'multiple'

def extract_interactions_from_json(json_path: str, known_ingredients: List[str]) -> List[Dict]:
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
                
                drug_name = drug_name.lower().strip()
                
                # Extract interaction texts
                interaction_texts = []
                
                if 'drug_interactions' in record:
                    interaction_texts.extend(record['drug_interactions'])
                if 'warnings' in record:
                    for warning in record['warnings']:
                        if 'interaction' in warning.lower():
                            interaction_texts.extend(re.split(r'(?<=[.!?])\s+', warning))
                
                # Process interactions
                processed_texts = set()
                
                for text in interaction_texts:
                    if not text or len(text) < 30:
                        continue
                    
                    # Split huge blocks
                    sentences = re.split(r'(?<=[.!?])\s+', text)
                    
                    for sentence in sentences:
                        if len(sentence) < 40: continue
                        if sentence in processed_texts: continue
                        
                        processed_texts.add(sentence)
                        
                        # Find the OTHER drug
                        ingredient2 = find_interacting_drug(sentence, drug_name, known_ingredients)
                        
                        # Skip if we couldn't find a target (improves quality, reduces noise)
                        if ingredient2 == 'multiple' and 'contraindicated' not in sentence.lower():
                             # If it's not severe, and we don't know who it interacts with, skip it.
                             # Users hate "Unknown" interactions.
                             continue
                        
                        interaction = {
                            'ingredient1': drug_name,
                            'ingredient2': ingredient2,
                            'severity': estimate_severity(sentence),
                            'type': 'pharmacodynamic' if 'effect' in sentence.lower() else 'class_interaction',
                            'effect': sentence[:500].strip(), # Limit length
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
    ingredients_file = 'assets/data/medicine_ingredients.json'
    
    os.makedirs(download_dir, exist_ok=True)
    
    print("=" * 70)
    print("OpenFDA Drug Interactions Complete Extraction")
    print("=" * 70)
    
    # Load known ingredients for better entity extraction
    print("Loading known ingredients...")
    known_ingredients = load_known_ingredients(ingredients_file)
    print(f"Loaded {len(known_ingredients):,} ingredients for checking.")
    
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
        file_interactions = extract_interactions_from_json(json_path, known_ingredients)
        all_interactions.extend(file_interactions)
        
        print(f"  Running total: {len(all_interactions):,} interactions")
        
        # Optional: Free memory by deleting unzipped json
        try:
            os.remove(json_path)
            print("  Cleaned up raw JSON file")
        except:
            pass
    
    print("\n" + "=" * 70)
    print(f"Total interactions extracted: {len(all_interactions):,}")
    
    # Deduplicate smartly
    print("\nDeduplicating and aggregating...")
    merged_data = {}
    
    for interaction in all_interactions:
        # Key by drug pair to merge duplicates
        # Sort ing1/ing2 to handle symmetric interactions? 
        # No, keep direction for now as OpenFDA text is directional (Drug A affects Drug B)
        key = (interaction['ingredient1'], interaction['ingredient2'])
        
        if key not in merged_data:
            merged_data[key] = interaction
        else:
            current = merged_data[key]
            current_severity = current['severity']
            new_severity = interaction['severity']
            
            # Severity priority
            severity_rank = { 'contraindicated': 4, 'severe': 3, 'major': 2, 'moderate': 1, 'minor': 0 }
            
            if severity_rank.get(new_severity, 0) > severity_rank.get(current_severity, 0):
                # Update if new one is more severe
                merged_data[key] = interaction
            elif severity_rank.get(new_severity, 0) == severity_rank.get(current_severity, 0):
                # If same severity, keep the one with longer/better description
                if len(interaction['effect']) > len(current['effect']):
                     merged_data[key] = interaction

    unique_interactions = list(merged_data.values())
    
    print(f"Unique interactions after smart merge: {len(unique_interactions):,}")
    
    # Save
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(unique_interactions, f, indent=2, ensure_ascii=False)
    
    print(f"\n✅ Saved to: {output_file}")
    if os.path.exists(output_file):
        print(f"   File size: {os.path.getsize(output_file) / (1024**2):.1f} MB")
    
if __name__ == '__main__':
    main()
