import zipfile
import xml.etree.ElementTree as ET
import re

zip_path = '/home/adminlotfy/project/External_source/dailymed/downloaded/dm_spl_daily_update_12112025.zip'

with zipfile.ZipFile(zip_path, 'r') as z:
    xml_files = [f for f in z.namelist() if f.endswith('.xml')][:1]
    
    if xml_files:
        print(f"Examining: {xml_files[0]}\n")
        xml_data = z.read(xml_files[0])
        xml_str = xml_data.decode('utf-8', errors='ignore')
        
        # NDC pattern
        ndc_matches = re.findall(r'(\d{4,5}-\d{3,4}-\d{1,2})', xml_str)
        
        # EAN/GTIN
        ean_matches = re.findall(r'(?:EAN|GTIN|barcode)["\s:=]+(\d{13})', xml_str, re.IGNORECASE)
        long_codes = re.findall(r'\b(\d{13})\b', xml_str)
        
        print("=== NDC Codes (US Format) ===")
        print(f"Found: {len(ndc_matches)}")
        for code in ndc_matches[:5]:
            print(f"  {code}")
        
        print("\n=== EAN-13/GTIN (International) ===")
        print(f"Found with label: {len(ean_matches)}")
        print(f"Total 13-digit numbers: {len(long_codes)}")
        
        if ean_matches:
            for code in ean_matches[:5]:
                print(f"  {code}")
        elif long_codes:
            print("Sample 13-digit codes:")
            for code in list(set(long_codes))[:5]:
                print(f"  {code}")
        else:
            print("  None found")
