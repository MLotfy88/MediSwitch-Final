
import json
import os
from pathlib import Path
from collections import Counter

DATA_DIR = Path("scripts/wikem_scraper/scraped_data/drugs")

def validate_scraped_data():
    if not DATA_DIR.exists():
        print(f"❌ Error: Directory {DATA_DIR} does not exist.")
        return

    files = list(DATA_DIR.glob("*.json"))
    total_files = len(files)
    
    print(f"🔍 Starting Comprehensive Analysis of {total_files} files...\n")
    
    stats = {
        "valid_json": 0,
        "corrupt_json": 0,
        "empty_sections": 0,
        "only_intro": 0,
        "rich_content": 0,
        "total_sections": 0,
    }
    
    empty_files = []
    
    for file_path in files:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
                stats["valid_json"] += 1
                
                sections = data.get("sections", {})
                num_sections = len(sections)
                stats["total_sections"] += num_sections
                
                if num_sections == 0:
                    stats["empty_sections"] += 1
                    empty_files.append(file_path.name)
                elif num_sections == 1 and "Intro" in sections:
                    stats["only_intro"] += 1
                else:
                    stats["rich_content"] += 1
                    
        except json.JSONDecodeError:
            stats["corrupt_json"] += 1
            print(f"❌ Corrupt JSON: {file_path.name}")
        except Exception as e:
            print(f"⚠️ Error reading {file_path.name}: {e}")

    # Report
    print("=" * 40)
    print("📊 DATA HEALTH REPORT")
    print("=" * 40)
    print(f"✅ Total Scraped Files: {total_files}")
    print(f"✅ Valid JSON Files:   {stats['valid_json']}")
    print(f"❌ Corrupt Files:      {stats['corrupt_json']}")
    print("-" * 40)
    print(f"💀 Empty (No Data):    {stats['empty_sections']}  <-- Files with 0 sections")
    print(f"⚠️ Intro Only:         {stats['only_intro']}  <-- Files with only Intro")
    print(f"💎 Rich Data:          {stats['rich_content']}  <-- Files with multiple sections")
    print("-" * 40)
    
    if stats['valid_json'] > 0:
        avg = stats['total_sections'] / stats['valid_json']
        print(f"📈 Avg Sections/Page:  {avg:.1f}")
    
    if empty_files:
        print("\n🗑️  SAMPLE EMPTY FILES (First 10):")
        for f in empty_files[:10]:
            print(f"  - {f}")
            
    print("\n🏁 CONCLUSION:")
    if stats["rich_content"] > total_files * 0.8:
        print("🟢 PASSED: High Quality Dataset")
    elif stats["empty_sections"] > total_files * 0.1:
        print("🔴 FAILED: Too many empty files")
    else:
        print("🟡 WARNING: Mixed Quality")

if __name__ == "__main__":
    validate_scraped_data()
