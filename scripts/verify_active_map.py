import sys
import os

# Add scripts dir to path to import process_datalake
sys.path.append(os.path.join(os.getcwd(), 'scripts'))

from process_datalake import load_app_data, clean_drug_name

def main():
    print("🧪 Testing Active Ingredient Mapping...")
    
    app_map, active_map = load_app_data()
    
    print(f"\n📊 Results:")
    print(f"  Trade Name Keys: {len(app_map)}")
    print(f"  Active Ingredient Keys: {len(active_map)}")
    
    # Check some known examples
    # 1. Simple
    sample = "fluoxetine"
    if sample in active_map:
        print(f"✅ Found '{sample}': matched {len(active_map[sample])} records")
        print(f"   Example: {active_map[sample][0]['trade_name']}")
    else:
        print(f"❌ '{sample}' NOT found in active map!")
        
    # 2. Complex/Multi (Normalized)
    # Check what key "camphor+menthol" produces
    # "camphor menthol" (sorted)
    
    # Let's inspect some keys to see normalization
    print("\n🔍 Random Keys from Active Map:")
    keys = list(active_map.keys())
    import random
    if keys:
        for k in random.sample(keys, min(10, len(keys))):
            print(f"  - '{k}' -> {len(active_map[k])} records")
            
if __name__ == "__main__":
    main()
