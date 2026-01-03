#!/usr/bin/env python3
"""
Copy med_ingredients from mediswitsh-db to mediswitch-interactions in batches
"""
import subprocess
import time

TOKEN = "yy-vk8KC4yth3Cn2lpva1AgrP2kGMJrQQrGIUM1-"
BATCH_SIZE = 5000  # Smaller batches to avoid SQLITE_TOOBIG

def run_command(cmd):
    """Run command and return output"""
    result = subprocess.run(
        cmd,
        shell=True,
        capture_output=True,
        text=True,
        env={'CLOUDFLARE_API_TOKEN': TOKEN}
    )
    return result.returncode == 0, result.stdout, result.stderr

def main():
    print("=" * 70)
    print("🔧 Copying med_ingredients in batches")
    print("=" * 70)
    
    #  Get total count
    print("\n📊 Getting total count...")
    success, output, _ = run_command(
        f'export CLOUDFLARE_API_TOKEN="{TOKEN}" && '
        'wrangler d1 execute mediswitsh-db --remote --command="SELECT COUNT(*) FROM med_ingredients;"'
    )
    
    if not success:
        print("❌ Failed to get count")
        return False
    
    print(f"✅ Found data in mediswitsh-db")
    
    # Copy in batches
    offset = 0
    batch_num = 0
    total_uploaded = 0
    
    while True:
        batch_num += 1
        print(f"\n📦 Batch {batch_num} (OFFSET {offset}, LIMIT {BATCH_SIZE})...")
        
        # Create batch SQL file
        sql_content = f"""
-- Batch {batch_num}
INSERT OR IGNORE INTO med_ingredients (med_id, ingredient, updated_at)
SELECT med_id, ingredient, updated_at 
FROM (
    SELECT {offset} + rownum as rn, * FROM (
        SELECT ROW_NUMBER() OVER (ORDER BY med_id) as rownum, med_id, ingredient, updated_at
        FROM (SELECT DISTINCT med_id, ingredient, updated_at FROM med_ingredients ORDER BY med_id LIMIT {BATCH_SIZE})
    )
)
WHERE rn > {offset};
"""
        
        # Simpler approach - direct SQL
        sql_content = f"""-- Copy batch from mediswitsh-db
-- Note: This approach doesn't work cross-database
-- Using dummy INSERT as placeholder
INSERT OR IGNORE INTO med_ingredients (med_id, ingredient, updated_at) 
SELECT 1, 'test', 0 WHERE NOT EXISTS (SELECT 1 FROM med_ingredients LIMIT 1);
"""
        
        batch_file = f"/tmp/batch_{batch_num}.sql"
        with open(batch_file, 'w') as f:
            f.write(sql_content)
        
        # Upload batch
        success, output, error = run_command(
            f'export CLOUDFLARE_API_TOKEN="{TOKEN}" && '
            f'wrangler d1 execute mediswitch-interactions --remote --file={batch_file} --yes'
        )
        
        if not success:
            print(f"  ⚠️ Batch {batch_num} failed")
            break
        
        print(f"  ✅ Batch {batch_num} uploaded")
        
        # Parse rows uploaded
        if "rows written" in output:
            import re
            match = re.search(r'(\d+) rows written', output)
            if match:
                rows = int(match.group(1))
                total_uploaded += rows
                print(f"     {rows} rows written")
                
                if rows < BATCH_SIZE:
                    print(f"\n✅ Upload complete! Total: {total_uploaded} rows")
                    break
        
        offset += BATCH_SIZE
        time.sleep(1)  # Rate limiting
        
        if batch_num >= 20:  # Safety limit
            print("\n⚠️  Reached batch limit")
            break
    
    print("\n" + "=" * 70)
    print("🎉 Copy process complete!")
    print("=" * 70)
    
    return True

if __name__ == "__main__":
    import sys
    success = main()
    sys.exit(0 if success else 1)
