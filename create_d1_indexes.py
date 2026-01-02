import os
import subprocess

# Credentials (from upload script)
CLOUDFLARE_API_TOKEN = "yy-vk8KC4yth3Cn2lpva1AgrP2kGMJrQQrGIUM1-"
CLOUDFLARE_EMAIL = "eedf653449abdca28e865ddf3511dd4c62ed2"
DATABASE_NAME = "mediswitsh-db"

def run_command(cmd, env=None):
    try:
        current_env = os.environ.copy()
        if env:
            current_env.update(env)
            
        result = subprocess.run(
            cmd, 
            shell=True, 
            check=True, 
            stdout=subprocess.PIPE, 
            stderr=subprocess.PIPE,
            text=True,
            env=current_env
        )
        return True, result.stdout
    except subprocess.CalledProcessError as e:
        return False, f"STDOUT: {e.stdout}\nSTDERR: {e.stderr}"

def create_d1_indexes():
    print("🚀 Creating Indexes on Cloudflare D1...")
    print("="*80)
    
    env = {
        "CLOUDFLARE_API_TOKEN": CLOUDFLARE_API_TOKEN,
        "CLOUDFLARE_EMAIL": CLOUDFLARE_EMAIL
    }
    
    indexes = [
        "CREATE INDEX IF NOT EXISTS idx_disease_med ON disease_interactions(med_id)",
        "CREATE INDEX IF NOT EXISTS idx_disease_severity ON disease_interactions(severity)",
        "CREATE INDEX IF NOT EXISTS idx_disease_name ON disease_interactions(disease_name)",
        "CREATE INDEX IF NOT EXISTS idx_food_med ON food_interactions(med_id)",
        "CREATE INDEX IF NOT EXISTS idx_ddi_ing1 ON drug_interactions(ingredient1)",
        "CREATE INDEX IF NOT EXISTS idx_ddi_ing2 ON drug_interactions(ingredient2)",
        "CREATE INDEX IF NOT EXISTS idx_ddi_severity ON drug_interactions(severity)",
        "CREATE INDEX IF NOT EXISTS idx_drugs_active ON drugs(active)"
    ]
    
    for sql in indexes:
        print(f"\n🔧 Executing: {sql}")
        cmd = f'npx wrangler d1 execute {DATABASE_NAME} --command="{sql}" --remote'
        success, output = run_command(cmd, env)
        if success:
            print("   ✅ Success")
        else:
            print(f"   ❌ Failed: {output[:200]}...") # Truncate error for readability

    print("\n✅ Index creation complete.")

if __name__ == "__main__":
    create_d1_indexes()
