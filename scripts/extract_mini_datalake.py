#!/usr/bin/env python3
"""
Mini Data Lake Extractor
Runs the full extraction logic on LOCAL sample files to generate a preview.
"""

import os
import sys
import glob
import json
# Import the logic from the production script
sys.path.append(os.path.join(os.getcwd(), 'production_data'))
try:
    from extract_full_dailymed import FullDailyMedExtractor, process_zip_part
except ImportError:
    # Fallback if path issue
    import importlib.util
    spec = importlib.util.spec_from_file_location("extract_full_dailymed", "production_data/extract_full_dailymed.py")
    extract_full_dailymed = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(extract_full_dailymed)
    FullDailyMedExtractor = extract_full_dailymed.FullDailyMedExtractor
    process_zip_part = extract_full_dailymed.process_zip_part

# Configuration
LOCAL_ZIP_DIR = 'External_source/dailymed/downloaded/extracted/prescription'
OUTPUT_FILE = 'production_data/dailymed_mini_sample.json'

def main():
    print("="*60)
    print("Creating Mini Data Lake for Inspection")
    print("="*60)
    
    # 1. Find local zips
    zips = glob.glob(os.path.join(LOCAL_ZIP_DIR, '*.zip'))
    if not zips:
        print(f"❌ No local zips found in {LOCAL_ZIP_DIR}")
        return

    print(f"Found {len(zips)} local zip files. Processing top 5...")
    
    extractor = FullDailyMedExtractor()
    all_data = []
    
    for zip_path in zips[:5]: # Procss only 5 files
        print(f"  Processing {os.path.basename(zip_path)}...")
        # Note: These local zips are likely the 'nested' zips themselves, not the release parts.
        # The 'process_zip_part' expects a RELEASE zip containing nested zips.
        # So we need to call extractor.extract_from_xml() directly on the contents.
        
        try:
            import zipfile
            with zipfile.ZipFile(zip_path, 'r') as z:
                xml_files = [f for f in z.namelist() if f.endswith('.xml')]
                if xml_files:
                    xml_content = z.read(xml_files[0])
                    record = extractor.extract_from_xml(xml_content)
                    if record:
                        all_data.append(record)
                        print(f"    ✅ Extracted: {record.get('title', 'Unknown')[:50]}...")
        except Exception as e:
            print(f"    ⚠️ Error: {e}")

    print(f"\nTotal Sample Records: {len(all_data)}")
    
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(all_data, f, indent=2, ensure_ascii=False)
    
    print(f"saved to {OUTPUT_FILE}")

if __name__ == "__main__":
    main()
