#!/usr/bin/env python3
"""
OpenFDA Drug Label Data Downloader
Downloads all 13 drug label ZIP files from OpenFDA for dosage extraction
"""

import os
import requests
from typing import List

# OpenFDA URLs for drug label data
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

DOWNLOAD_DIR = 'External_source/drug_interaction/drug-label/downloaded'

def download_file(url: str, output_path: str, max_retries: int = 3) -> bool:
    """Download a file from URL with retry logic"""
    for attempt in range(max_retries):
        try:
            print(f"\nDownloading: {os.path.basename(url)}" + 
                  (f" (Attempt {attempt + 1}/{max_retries})" if attempt > 0 else ""))
            
            response = requests.get(url, stream=True, timeout=60)
            response.raise_for_status()
            
            total_size = int(response.headers.get('content-length', 0))
            downloaded = 0
            
            with open(output_path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    if chunk:
                        f.write(chunk)
                        downloaded += len(chunk)
                        if total_size:
                            percent = (downloaded / total_size) * 100
                            print(f"\r  Progress: {percent:.1f}% ({downloaded:,}/{total_size:,} bytes)", end='')
            
            print()  # New line after progress
            
            # Verify file size
            actual_size = os.path.getsize(output_path)
            if total_size > 0 and actual_size != total_size:
                print(f"⚠️  Size mismatch: expected {total_size:,}, got {actual_size:,}")
                if attempt < max_retries - 1:
                    continue
            
            print(f"✅ Downloaded successfully ({actual_size:,} bytes)")
            return True
            
        except Exception as e:
            print(f"❌ Download failed: {e}")
            if attempt < max_retries - 1:
                print(f"   Retrying in 5 seconds...")
                import time
                time.sleep(5)
            else:
                print(f"   Max retries reached for {os.path.basename(url)}")
                return False
    
    return False

def main():
    """Main download process"""
    print("="*80)
    print("OpenFDA Drug Label Data Downloader")
    print("="*80)
    
    # Create download directory
    os.makedirs(DOWNLOAD_DIR, exist_ok=True)
    print(f"\n📁 Download directory: {DOWNLOAD_DIR}")
    
    # Download all files
    total_files = len(OPENFDA_URLS)
    successful = 0
    failed = []
    
    print(f"\n📥 Starting download of {total_files} files...\n")
    
    for i, url in enumerate(OPENFDA_URLS, 1):
        filename = os.path.basename(url)
        output_path = os.path.join(DOWNLOAD_DIR, filename)
        
        print(f"\n[{i}/{total_files}] {filename}")
        
        # Skip if file already exists and is valid
        if os.path.exists(output_path):
            size = os.path.getsize(output_path)
            if size > 1000000:  # At least 1MB
                print(f"  ℹ️  File already exists ({size:,} bytes), skipping...")
                successful += 1
                continue
        
        # Download file
        if download_file(url, output_path):
            successful += 1
        else:
            failed.append(filename)
    
    # Summary
    print("\n" + "="*80)
    print("📊 Download Summary")
    print("="*80)
    print(f"  • Total files: {total_files}")
    print(f"  • Successful: {successful}")
    print(f"  • Failed: {len(failed)}")
    
    if failed:
        print(f"\n⚠️  Failed files:")
        for f in failed:
            print(f"    - {f}")
        exit(1)
    else:
        print(f"\n✅ All files downloaded successfully!")
        print(f"📁 Location: {os.path.abspath(DOWNLOAD_DIR)}")

if __name__ == "__main__":
    main()
