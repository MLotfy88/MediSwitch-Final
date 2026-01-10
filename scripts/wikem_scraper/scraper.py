#!/usr/bin/env python3
"""
WikEM Scraper - Production Grade with Anti-Ban & Resume Support
================================================================

Features:
- User-Agent rotation
- Random delays (3-8s)
- Exponential backoff
- Incremental saving
- Git auto-commit
- Resume capability
"""

import requests
from bs4 import BeautifulSoup
import time
import random
import json
import logging
from pathlib import Path
from datetime import datetime
import sys
from typing import Dict, List, Optional
import subprocess

# ============================================================================
# CONFIGURATION
# ============================================================================

BASE_URL = "https://wikem.org/wiki/"
CHECKPOINT_FILE = Path("scripts/wikem_scraper/checkpoints/progress.json")
DATA_DIR = Path("scripts/wikem_scraper/scraped_data/drugs")
LOG_FILE = Path("scripts/wikem_scraper/logs/scraper.log")

# Anti-Ban Configuration
USER_AGENTS = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:121.0) Gecko/20100101 Firefox/121.0',
    'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:121.0) Gecko/20100101 Firefox/121.0',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Safari/605.1.15',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0',
]

MIN_DELAY = 3  # seconds
MAX_DELAY = 8  # seconds
MAX_RETRIES = 3
BACKOFF_FACTOR = 2  # exponential backoff multiplier
COMMIT_EVERY = 50  # auto-commit every N drugs

# ============================================================================
# LOGGING SETUP
# ============================================================================

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

# ============================================================================
# CHECKPOINT MANAGER
# ============================================================================

class CheckpointManager:
    def __init__(self, checkpoint_file: Path):
        self.checkpoint_file = checkpoint_file
        self.checkpoint_file.parent.mkdir(parents=True, exist_ok=True)
        self.data = self._load()
    
    def _load(self) -> Dict:
        if self.checkpoint_file.exists():
            with open(self.checkpoint_file, 'r') as f:
                return json.load(f)
        return {
            "processed_drugs": [],
            "failed_drugs": [],
            "last_updated": None,
            "total_scraped": 0,
            "total_failed": 0
        }
    
    def save(self):
        self.data["last_updated"] = datetime.now().isoformat()
        with open(self.checkpoint_file, 'w') as f:
            json.dump(self.data, f, indent=2)
    
    def mark_processed(self, drug_name: str):
        if drug_name not in self.data["processed_drugs"]:
            self.data["processed_drugs"].append(drug_name)
            self.data["total_scraped"] += 1
            self.save()
    
    def mark_failed(self, drug_name: str, reason: str):
        failure = {"name": drug_name, "reason": reason, "timestamp": datetime.now().isoformat()}
        self.data["failed_drugs"].append(failure)
        self.data["total_failed"] += 1
        self.save()
    
    def is_processed(self, drug_name: str) -> bool:
        return drug_name in self.data["processed_drugs"]
    
    def get_stats(self) -> Dict:
        return {
            "total_scraped": self.data["total_scraped"],
            "total_failed": self.data["total_failed"],
            "last_updated": self.data["last_updated"]
        }

# ============================================================================
# SAFE HTTP CLIENT
# ============================================================================

class SafeHTTPClient:
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.9',
            'Accept-Encoding': 'gzip, deflate, br',
            'DNT': '1',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1',
            'Sec-Fetch-Dest': 'document',
            'Sec-Fetch-Mode': 'navigate',
            'Sec-Fetch-Site': 'none',
            'Cache-Control': 'max-age=0',
        })
        self.last_request_time = 0
    
    def get(self, url: str, retries: int = MAX_RETRIES) -> Optional[requests.Response]:
        for attempt in range(retries):
            try:
                # Enforce delay
                self._enforce_delay()
                
                # Rotate User-Agent
                headers = {'User-Agent': random.choice(USER_AGENTS)}
                
                logger.info(f"GET {url} (Attempt {attempt + 1}/{retries})")
                response = self.session.get(url, headers=headers, timeout=30)
                
                if response.status_code == 200:
                    return response
                elif response.status_code in [403, 429]:
                    wait_time = BACKOFF_FACTOR ** attempt * 60
                    logger.warning(f"Rate limited ({response.status_code}). Waiting {wait_time}s...")
                    time.sleep(wait_time)
                elif response.status_code == 404:
                    logger.warning(f"Page not found: {url}")
                    return None
                else:
                    logger.error(f"HTTP {response.status_code}: {url}")
                    
            except requests.RequestException as e:
                logger.error(f"Request failed: {e}")
                if attempt < retries - 1:
                    time.sleep(BACKOFF_FACTOR ** attempt)
        
        return None
    
    def _enforce_delay(self):
        """Enforce random delay between requests"""
        elapsed = time.time() - self.last_request_time
        delay = random.uniform(MIN_DELAY, MAX_DELAY)
        
        if elapsed < delay:
            sleep_time = delay - elapsed
            logger.debug(f"Sleeping {sleep_time:.2f}s (politeness delay)")
            time.sleep(sleep_time)
        
        self.last_request_time = time.time()

# ============================================================================
# WIKEM SCRAPER
# ============================================================================

class WikEMScraper:
    def __init__(self):
        self.client = SafeHTTPClient()
        self.checkpoint = CheckpointManager(CHECKPOINT_FILE)
        DATA_DIR.mkdir(parents=True, exist_ok=True)
    
    def extract_table(self, table_elem) -> List[Dict]:
        """Extract HTML table as structured data"""
        rows = []
        headers = []
        
        # Extract headers
        header_row = table_elem.find('tr')
        if header_row:
            headers = [th.get_text(strip=True) for th in header_row.find_all(['th', 'td'])]
        
        # Extract data rows
        for row in table_elem.find_all('tr')[1:]:  # Skip header
            cells = [td.get_text(strip=True) for td in row.find_all(['td', 'th'])]
            if cells:
                if headers:
                    row_dict = dict(zip(headers, cells))
                else:
                    row_dict = {"cells": cells}
                rows.append(row_dict)
        
        return rows
    
    def extract_section_content(self, soup: BeautifulSoup, section_id_pattern: str) -> Optional[Dict]:
        """Extract content with structure preservation using regex for ID"""
        # Find header with regex ID match (e.g. "Antibiotic_Sensitivities" matching "Antibiotic_Sensitivities[1]")
        import re
        header_span = soup.find('span', id=re.compile(f"^{section_id_pattern}(?:\[\d+\])?$"))
        
        if not header_span:
            # Try finding by text if ID fails
            header_span = soup.find('span', class_='mw-headline', string=re.compile(f"^{section_id_pattern}", re.I))
            
        if not header_span:
            return None
        
        parent_h2 = header_span.parent
        content = {
            "text": "",
            "subsections": {},
            "tables": [],
            "links": []
        }
        
        next_node = parent_h2.next_sibling
        current_subsection = None
        
        while next_node:
            if next_node.name == 'h2':
                break
            
            # H3/H4 Subsections (Contextual Dosing, Monitoring)
            if next_node.name in ['h3', 'h4']:
                subsection_span = next_node.find('span', class_='mw-headline')
                if subsection_span:
                    # Clean ID/Text for subsection key
                    raw_id = subsection_span.get('id', subsection_span.get_text(strip=True))
                    # Remove [1], [2] etc from subsection keys
                    current_subsection = re.sub(r'\[\d+\]$', '', raw_id)
                    
                    content["subsections"][current_subsection] = {
                        "text": "",
                        "tables": []
                    }
            
            # Tables (Antibiotic Sensitivities)
            elif next_node.name == 'table':
                table_data = self.extract_table(next_node)
                if table_data:
                    if current_subsection and current_subsection in content["subsections"]:
                        content["subsections"][current_subsection]["tables"].append(table_data)
                    else:
                        content["tables"].append(table_data)
            
            # Text content
            elif next_node.name in ['p', 'ul', 'ol', 'dl']:
                text = next_node.get_text(separator='\n', strip=True)
                
                # Extract links
                for link in next_node.find_all('a', href=True):
                    href = link.get('href', '')
                    if href.startswith('/wiki/') and 'Special:' not in href:
                        link_text = link.get_text(strip=True)
                        if link_text:
                            content["links"].append({
                                "text": link_text,
                                "url": f"https://wikem.org{href}"
                            })
                
                if text:
                    if current_subsection and current_subsection in content["subsections"]:
                        content["subsections"][current_subsection]["text"] += text + "\n"
                    else:
                        content["text"] += text + "\n"
            
            next_node = next_node.next_sibling
        
        # Clean up
        content["text"] = content["text"].strip()
        for sub in content["subsections"].values():
            sub["text"] = sub["text"].strip()
        
        # Remove empty subsections
        content["subsections"] = {k: v for k, v in content["subsections"].items() 
                                   if v["text"] or v["tables"]}
        
        # Return None if completely empty
        if not content["text"] and not content["subsections"] and not content["tables"]:
            return None
        
        return content
        current_subsection = None
        
        while next_node:
            if next_node.name == 'h2':
                break
            
            # H3/H4 Subsections (Contextual Dosing)
            if next_node.name in ['h3', 'h4']:
                subsection_span = next_node.find('span', class_='mw-headline')
                if subsection_span:
                    current_subsection = subsection_span.get('id', subsection_span.get_text(strip=True))
                    content["subsections"][current_subsection] = {
                        "text": "",
                        "tables": []
                    }
            
            # Tables (Antibiotic Sensitivities)
            elif next_node.name == 'table':
                table_data = self.extract_table(next_node)
                if table_data:
                    if current_subsection and current_subsection in content["subsections"]:
                        content["subsections"][current_subsection]["tables"].append(table_data)
                    else:
                        content["tables"].append(table_data)
            
            # Text content
            elif next_node.name in ['p', 'ul', 'ol', 'dl']:
                text = next_node.get_text(separator='\n', strip=True)
                
                # Extract links
                for link in next_node.find_all('a', href=True):
                    href = link.get('href', '')
                    if href.startswith('/wiki/') and 'Special:' not in href:
                        link_text = link.get_text(strip=True)
                        if link_text:
                            content["links"].append({
                                "text": link_text,
                                "url": f"https://wikem.org{href}"
                            })
                
                if text:
                    if current_subsection and current_subsection in content["subsections"]:
                        content["subsections"][current_subsection]["text"] += text + "\n"
                    else:
                        content["text"] += text + "\n"
            
            next_node = next_node.next_sibling
        
        # Clean up
        content["text"] = content["text"].strip()
        for sub in content["subsections"].values():
            sub["text"] = sub["text"].strip()
        
        # Remove empty subsections
        content["subsections"] = {k: v for k, v in content["subsections"].items() 
                                   if v["text"] or v["tables"]}
        
        # Return None if completely empty
        if not content["text"] and not content["subsections"] and not content["tables"]:
            return None
        
        return content
    
    def scrape_drug(self, drug_name: str) -> Optional[Dict]:
        """Scrape all data for a single drug"""
        url = f"{BASE_URL}{drug_name}"
        response = self.client.get(url)
        
        if not response:
            return None
        
        soup = BeautifulSoup(response.content, 'html.parser')
        
        # Extract all sections
        sections = [
            'General', 'Adult_Dosing', 'Pediatric_Dosing',
            'Special_Populations', 'Contraindications',
            'Adverse_Reactions', 'Pharmacology', 'Comments',
            'Antibiotic_Sensitivities', 'Monitoring'
        ]
        
        drug_data = {
            "drug_name": drug_name,
            "url": url,
            "scraped_at": datetime.now().isoformat(),
            "sections": {}
        }
        
        for section in sections:
            content = self.extract_section_content(soup, section)
            if content:
                drug_data["sections"][section] = content
        
        return drug_data
    
    def save_drug_data(self, drug_name: str, data: Dict):
        """Save drug data to JSON file"""
        safe_name = drug_name.replace('/', '_').replace(' ', '_')
        file_path = DATA_DIR / f"{safe_name}.json"
        
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        
        logger.info(f"✓ Saved: {file_path}")
    
    def git_commit(self, message: str):
        """Auto-commit to git"""
        try:
            subprocess.run(['git', 'add', str(DATA_DIR)], check=True, cwd='.')
            subprocess.run(['git', 'add', str(CHECKPOINT_FILE)], check=True, cwd='.')
            subprocess.run(['git', 'commit', '-m', message], check=True, cwd='.')
            logger.info(f"✓ Git commit: {message}")
        except subprocess.CalledProcessError as e:
            logger.warning(f"Git commit failed: {e}")
    
    def run(self, drug_list: List[str]):
        """Main scraping loop with resume support"""
        logger.info(f"Starting scraper. Total drugs: {len(drug_list)}")
        stats = self.checkpoint.get_stats()
        logger.info(f"Checkpoint: {stats['total_scraped']} scraped, {stats['total_failed']} failed")
        
        processed_count = 0
        
        for i, drug_name in enumerate(drug_list, 1):
            # Skip if already processed
            if self.checkpoint.is_processed(drug_name):
                logger.debug(f"Skipping (already processed): {drug_name}")
                continue
            
            logger.info(f"[{i}/{len(drug_list)}] Scraping: {drug_name}")
            
            try:
                data = self.scrape_drug(drug_name)
                
                if data:
                    self.save_drug_data(drug_name, data)
                    self.checkpoint.mark_processed(drug_name)
                    processed_count += 1
                    
                    # Auto-commit every N drugs
                    if processed_count % COMMIT_EVERY == 0:
                        try:
                            self.git_commit(f"WikEM scraping: {processed_count} drugs completed")
                        except Exception as e:
                            logger.warning(f"Git commit failed (non-critical): {e}")
                else:
                    self.checkpoint.mark_failed(drug_name, "Scraping returned None")
                    
            except Exception as e:
                logger.error(f"Error scraping {drug_name}: {e}")
                self.checkpoint.mark_failed(drug_name, str(e))
        
        # Final commit
        if processed_count % COMMIT_EVERY != 0:
            self.git_commit(f"Final commit: {processed_count} drugs scraped")
        
        logger.info("=" * 60)
        logger.info("SCRAPING COMPLETE!")
        final_stats = self.checkpoint.get_stats()
        logger.info(f"Total scraped: {final_stats['total_scraped']}")
        logger.info(f"Total failed: {final_stats['total_failed']}")
        logger.info("=" * 60)

# ============================================================================
# MAIN
# ============================================================================

if __name__ == "__main__":
    # Load drug list from file (or use sample if file doesn't exist)
    drug_list_file = Path("scripts/wikem_scraper/drug_list.txt")
    
    if drug_list_file.exists():
        logger.info(f"Loading drug list from {drug_list_file}")
        with open(drug_list_file, 'r') as f:
            DRUG_LIST = [line.strip() for line in f if line.strip()]
        logger.info(f"Loaded {len(DRUG_LIST)} drugs from file")
    else:
        logger.warning("drug_list.txt not found. Using sample drugs.")
        DRUG_LIST = [
            "Metronidazole",
            "Vancomycin",
            "Amiodarone",
            "Warfarin",
            "Morphine"
        ]
    
    scraper = WikEMScraper()
    scraper.run(DRUG_LIST)
