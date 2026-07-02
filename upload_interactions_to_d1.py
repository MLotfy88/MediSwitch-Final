#!/usr/bin/env python3
"""
Upload Interactions to Cloudflare D1 Database
This script applies schema and uploads all interaction chunks to the cloud database
"""
import subprocess
import sys
import os
import glob
import time

# Configuration
DATABASE_NAME = "mediswitch-interactions"
SCHEMA_FILE = "cloudflare-worker/schema_interactions.sql"
CHUNKS_DIR = "d1_interactions_chunks"

def run_command(cmd, description):
    """Run a command and print the result"""
    print(f"\n{'='*60}")
    print(f"⏳ {description}...")
    print(f"{'='*60}")
    
    try:
        result = subprocess.run(
            cmd,
            shell=True,
            check=True,
            capture_output=True,
            text=True
        )
        print(f"✅ {description} completed successfully")
        if result.stdout:
            print(result.stdout)
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ {description} failed")
        print(f"Error: {e.stderr}")
        return False

def main():
    # Step 1: Apply Schema
    print("\n" + "="*60)
    print("🏗️  STEP 1: Applying Database Schema")
    print("="*60)
    
    if not os.path.exists(SCHEMA_FILE):
        print(f"❌ Schema file not found: {SCHEMA_FILE}")
        return False
    
    schema_cmd = f'cd cloudflare-worker && wrangler d1 execute {DATABASE_NAME} --remote --file=schema_interactions.sql'
    if not run_command(schema_cmd, "Apply schema to remote database"):
        print("\n⚠️  Schema application failed. The table might already exist.")
        print("Continuing with data upload...")
    
    # Step 2: Upload Interaction Chunks
    print("\n" + "="*60)
    print("📦 STEP 2: Uploading Interaction Data Chunks")
    print("="*60)
    
    # Get all SQL chunk files
    chunk_files = sorted(glob.glob(f"{CHUNKS_DIR}/interactions_part_*.sql"))
    
    if not chunk_files:
        print(f"❌ No chunk files found in {CHUNKS_DIR}/")
        return False
    
    total_chunks = len(chunk_files)
    print(f"\n📊 Found {total_chunks} chunk files to upload")
    
    successful = 0
    failed = 0
    
    for i, chunk_file in enumerate(chunk_files, 1):
        chunk_name = os.path.basename(chunk_file)
        print(f"\n[{i}/{total_chunks}] Uploading {chunk_name}...")
        
        upload_cmd = f'wrangler d1 execute {DATABASE_NAME} --remote --file={chunk_file}'
        
        if run_command(upload_cmd, f"Upload {chunk_name}"):
            successful += 1
        else:
            failed += 1
            print(f"⚠️  Failed to upload {chunk_name}, continuing...")
        
        # Small delay to avoid rate limiting
        if i < total_chunks:
            time.sleep(0.5)
    
    # Summary
    print("\n" + "="*60)
    print("📊 UPLOAD SUMMARY")
    print("="*60)
    print(f"✅ Successful: {successful}/{total_chunks}")
    print(f"❌ Failed: {failed}/{total_chunks}")
    
    if failed == 0:
        print("\n🎉 All interactions uploaded successfully!")
        return True
    elif successful > 0:
        print(f"\n⚠️  Partially completed: {successful} out of {total_chunks} chunks uploaded")
        return True
    else:
        print("\n❌ Upload failed completely")
        return False

if __name__ == "__main__":
    print("🚀 MediSwitch Interactions Upload Script")
    print("="*60)
    
    success = main()
    sys.exit(0 if success else 1)
