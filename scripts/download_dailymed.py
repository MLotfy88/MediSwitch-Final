#!/usr/bin/env python3
"""
Download DailyMed Full Release (Human Rx - All 5 Parts)
Downloads complete DailyMed database for comprehensive drug coverage
"""

import os
import requests
from concurrent.futures import ThreadPoolExecutor, as_completed

# DailyMed Full Release URLs (Human Rx - Prescription drugs)
DAILYMED_URLS = [
    "https://dailymed-data.nlm.nih.gov/public-release-files/dm_spl_release_human_rx_part1.zip",
    "https://dailymed-data.nlm.nih.gov/public-release-files/dm_spl_release_human_rx_part2.zip",
    "https://dailymed-data.nlm.nih.gov/public-release-files/dm_spl_release_human_rx_part3.zip",
    "https://dailymed-data.nlm.nih.gov/public-release-files/dm_spl_release_human_rx_part4.zip",
    "https://dailymed-data.nlm.nih.gov/public-release-files/dm_spl_release_human_rx_part5.zip",
]

DOWNLOAD_DIR = "External_source/dailymed/downloaded"

def download_file(url, output_path):
    """Download single file with progress tracking"""
    filename = os.path.basename(output_path)
    
    # Check if already exists
    if os.path.exists(output_path):
        file_size = os.path.getsize(output_path) / (1024 ** 3)  # GB
        print(f"✓ {filename} already exists ({file_size:.2f} GB)")
        return True
    
    print(f"\n📥 Downloading {filename}...")
    
    try:
        response = requests.get(url, stream=True, timeout=300)
        response.raise_for_status()
        
        total_size = int(response.headers.get('content-length', 0))
        downloaded = 0
        
        last_printed_step = -1
        
        with open(output_path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                if chunk:
                    f.write(chunk)
                    downloaded += len(chunk)
                    if total_size:
                        percent = (downloaded / total_size) * 100
                        # Calculate step (0, 1, 2, 3, 4 corresponding to 0, 25, 50, 75, 100)
                        current_step = int(percent // 25)
                        
                        if current_step > last_printed_step:
                             mb_downloaded = downloaded / (1024 ** 2)
                             mb_total = total_size / (1024 ** 2)
                             print(f"  {filename}: {current_step * 25}% ({mb_downloaded:.1f}/{mb_total:.1f} MB)")
                             last_printed_step = current_step
        
        print(f"\n✅ {filename} downloaded successfully!")
        print(f"   Size: {os.path.getsize(output_path) / (1024 ** 3):.2f} GB")
        return True
        
    except Exception as e:
        print(f"\n❌ {filename} download failed: {e}")
        if os.path.exists(output_path):
            os.remove(output_path)
        return False

def download_dailymed():
    """Download all DailyMed Full Release parts"""
    os.makedirs(DOWNLOAD_DIR, exist_ok=True)
    
    print("="*80)
    print("DailyMed Full Release Downloader")
    print("Downloading all 5 parts (Human Rx - Prescription drugs)")
    print("="*80)
    
    # Download files sequentially (parallel might overwhelm server)
    results = []
    for url in DAILYMED_URLS:
        filename = os.path.basename(url)
        output_path = os.path.join(DOWNLOAD_DIR, filename)
        success = download_file(url, output_path)
        results.append((filename, success))
    
    # Summary
    print("\n" + "="*80)
    print("DOWNLOAD SUMMARY")
    print("="*80)
    
    successful = sum(1 for _, success in results if success)
    total = len(results)
    
    for filename, success in results:
        status = "✅" if success else "❌"
        print(f"{status} {filename}")
    
    print(f"\nCompleted: {successful}/{total} files")
    
    if successful == total:
        print("\n🎉 All files downloaded successfully!")
        
        # Calculate total size
        total_gb = sum(
            os.path.getsize(os.path.join(DOWNLOAD_DIR, os.path.basename(url))) / (1024 ** 3)
            for url in DAILYMED_URLS
        )
        print(f"Total size: {total_gb:.2f} GB")
    else:
        print("\n⚠️ Some files failed to download. Please retry.")
        raise Exception("Download incomplete")

if __name__ == '__main__':
    download_dailymed()
