import os
import subprocess
import time
import glob

# Ensure CLOUDFLARE_API_TOKEN is set
os.environ['CLOUDFLARE_API_TOKEN'] = 'yy-vk8KC4yth3Cn2lpva1AgrP2kGMJrQQrGIUM1-'

# Get list of files
files = sorted(glob.glob("d1_dosages_part_*"))

print(f"Found {len(files)} files to upload.")

for i, f in enumerate(files):
    print(f"[{i+1}/{len(files)}] Uploading {f}...")
    try:
        # Run wrangler command
        # npx wrangler d1 execute mediswitsh-db --file "$f" --remote --yes
        cmd = ["npx", "wrangler", "d1", "execute", "mediswitsh-db", "--file", f, "--remote", "--yes"]
        
        # Run synchronously
        result = subprocess.run(cmd, cwd="/home/adminlotfy/project/cloudflare-worker", check=True, capture_output=True, text=True)
        print(f"Success: {f}")
        # print(result.stdout)
        
    except subprocess.CalledProcessError as e:
        print(f"Error uploading {f}:")
        print(e.stderr)
        print("Retrying in 10 seconds...")
        time.sleep(10)
        try:
             result = subprocess.run(cmd, cwd="/home/adminlotfy/project/cloudflare-worker", check=True, capture_output=True, text=True)
             print(f"Success (on retry): {f}")
        except:
             print(f"Failed again for {f}. Moving on.")
    
    # Wait to avoid rate limiting
    print("Waiting 3 seconds...")
    time.sleep(3)

print("Done.")
