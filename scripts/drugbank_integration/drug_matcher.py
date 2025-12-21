#!/usr/bin/env python3
"""
Optimized Drug Matcher Script - V2
===================================
Fast matching using indexed lookups with optional fuzzy fallback.
"""

import csv
import sqlite3
import re
from pathlib import Path
from typing import Dict, List, Tuple, Optional
from difflib import SequenceMatcher
from collections import defaultdict


class OptimizedDrugMatcher:
    def __init__(self, db_path: str, drugbank_pharmacology_csv: str):
        self.db_path = db_path
        self.drugbank_csv = drugbank_pharmacology_csv
        self.matches = []
        self.unmatched = []
        
    def normalize_ingredient(self, ingredient: str) -> str:
        """Normalize ingredient name for matching."""
        if not ingredient:
            return ""
        normalized = ingredient.lower().strip()
        # Remove common suffixes
        normalized = re.sub(r'\s+(hydrochloride|hcl|sodium|sulfate|phosphate|maleate|citrate|tartrate)$', '', normalized)
        normalized = re.sub(r'\s+', ' ', normalized)
        return normalized
    
    def create_search_keys(self, name: str) -> List[str]:
        """Create multiple search keys for a drug name."""
        keys = set()
        normalized = self.normalize_ingredient(name)
        
        # Full normalized name
        keys.add(normalized)
        
        # First word (often the main compound)
        words = normalized.split()
        if words:
            keys.add(words[0])
        
        # Remove "acid" suffix if present
        if 'acid' in normalized:
            keys.add(normalized.replace(' acid', ''))
        
        return list(keys)
    
    def load_drugbank_index(self, general_info_csv: str) -> Tuple[Dict, Dict, Dict]:
        """
        Load and index DrugBank data for fast lookups.
        
        Returns:
            Tuple of (pharmacology_data, name_index, drugbank_names)
        """
        print("📚 Loading DrugBank pharmacology data...")
        pharmacology_data = {}
        
        with open(self.drugbank_csv, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                db_id = row.get('drugbank_id', '')
                pharmacology_data[db_id] = {
                    'indication': row.get('indication', ''),
                    'mechanism_of_action': row.get('mechanism_of_action', ''),
                    'pharmacodynamics': row.get('pharmacodynamics', ''),
                }
        
        print(f"✅ Loaded {len(pharmacology_data)} pharmacology records")
        
        print("📚 Loading and indexing DrugBank names...")
        drugbank_names = {}
        name_index = defaultdict(list)  # normalized_name -> [drugbank_ids]
        
        with open(general_info_csv, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                db_id = row.get('drugbank_id', '')
                name = row.get('name', '')
                
                if db_id and name:
                    drugbank_names[db_id] = name
                    
                    # Create multiple search keys
                    for key in self.create_search_keys(name):
                        if key:
                            name_index[key].append(db_id)
        
        print(f"✅ Loaded {len(drugbank_names)} drug names")
        print(f"✅ Created index with {len(name_index)} unique keys")
        
        return pharmacology_data, name_index, drugbank_names
    
    def find_best_match(self, active: str, name_index: Dict, pharmacology_data: Dict, 
                        drugbank_names: Dict) -> Optional[Tuple[str, str, float]]:
        """
        Find best match for an active ingredient.
        
        Returns:
            Tuple of (drugbank_id, drugbank_name, confidence) or None
        """
        search_keys = self.create_search_keys(active)
        
        # Try exact matches first
        for key in search_keys:
            if key in name_index:
                for db_id in name_index[key]:
                    if db_id in pharmacology_data:
                        pharma = pharmacology_data[db_id]
                        if pharma['indication'] or pharma['mechanism_of_action']:
                            return (db_id, drugbank_names[db_id], 1.0)
        
        return None
    
    def match_drugs(self, general_info_csv: str) -> Tuple[int, int]:
        """Match DailyMed drugs with DrugBank data using indexed lookups."""
        
        # Load and index DrugBank data
        pharmacology_data, name_index, drugbank_names = self.load_drugbank_index(general_info_csv)
        
        print("\n🔍 Starting fast indexed drug matching...")
        
        # Connect to local database
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT id, tradeName, active 
            FROM drugs 
            WHERE active IS NOT NULL AND active != ''
        """)
        
        dailymed_drugs = cursor.fetchall()
        print(f"📋 Processing {len(dailymed_drugs)} DailyMed drugs...")
        
        matched_count = 0
        unmatched_count = 0
        
        for i, (drug_id, trade_name, active) in enumerate(dailymed_drugs, 1):
            if i % 1000 == 0:
                print(f"   Progress: {i}/{len(dailymed_drugs)} ({matched_count} matched)")
            
            match = self.find_best_match(active, name_index, pharmacology_data, drugbank_names)
            
            if match:
                db_id, db_name, confidence = match
                pharma = pharmacology_data[db_id]
                
                self.matches.append({
                    'dailymed_id': drug_id,
                    'dailymed_trade_name': trade_name,
                    'dailymed_active': active,
                    'drugbank_id': db_id,
                    'drugbank_name': db_name,
                    'indication': pharma['indication'],
                    'mechanism_of_action': pharma['mechanism_of_action'],
                    'pharmacodynamics': pharma['pharmacodynamics'],
                    'confidence': confidence
                })
                matched_count += 1
            else:
                self.unmatched.append({
                    'dailymed_id': drug_id,
                    'dailymed_trade_name': trade_name,
                    'dailymed_active': active,
                })
                unmatched_count += 1
        
        conn.close()
        
        print(f"\n✅ Matching complete!")
        print(f"   Matched: {matched_count}")
        print(f"   Unmatched: {unmatched_count}")
        print(f"   Match rate: {(matched_count / len(dailymed_drugs) * 100):.1f}%")
        
        return matched_count, unmatched_count
    
    def save_results(self, output_dir: str):
        """Save matching results to CSV files."""
        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)
        
        # Save matches
        matches_file = output_path / 'matched_drugs.csv'
        print(f"\n💾 Saving {len(self.matches)} matches to {matches_file}...")
        
        with open(matches_file, 'w', newline='', encoding='utf-8') as f:
            if self.matches:
                fieldnames = list(self.matches[0].keys())
                writer = csv.DictWriter(f, fieldnames=fieldnames)
                writer.writeheader()
                writer.writerows(self.matches)
        
        # Save unmatched
        unmatched_file = output_path / 'unmatched_drugs.csv'
        print(f"💾 Saving {len(self.unmatched)} unmatched to {unmatched_file}...")
        
        with open(unmatched_file, 'w', newline='', encoding='utf-8') as f:
            if self.unmatched:
                fieldnames = list(self.unmatched[0].keys())
                writer = csv.DictWriter(f, fieldnames=fieldnames)
                writer.writeheader()
                writer.writerows(self.unmatched)
        
        print("✅ Results saved successfully!")
    
    def print_sample_matches(self, n=10):
        """Print sample matches for review."""
        print(f"\n📋 Sample matches (first {n}):")
        print("="*80)
        
        for i, match in enumerate(self.matches[:n], 1):
            print(f"\n{i}. {match['dailymed_trade_name']}")
            print(f"   DailyMed: {match['dailymed_active']}")
            print(f"   DrugBank: {match['drugbank_name']}")
            print(f"   Confidence: {match['confidence']:.0%}")
            indication_preview = match['indication'][:100] + "..." if len(match['indication']) > 100 else match['indication']
            print(f"   Indication: {indication_preview if indication_preview else 'N/A'}")


def main():
    """Main execution function."""
    print("🚀 DrugBank Integration - Optimized Drug Matcher V2")
    print("="*80)
    
    # Paths
    db_path = "/home/adminlotfy/project/mediswitch.db"
    drugbank_pharmacology = "/home/adminlotfy/project/DrugBank_Organized_Data/data/drugs/pharmacology.csv"
    drugbank_general_info = "/home/adminlotfy/project/DrugBank_Organized_Data/data/drugs/general_information.csv"
    output_dir = "/home/adminlotfy/project/scripts/drugbank_integration/output"
    
    # Create matcher
    matcher = OptimizedDrugMatcher(db_path, drugbank_pharmacology)
    
    # Run matching
    matched, unmatched = matcher.match_drugs(drugbank_general_info)
    
    # Save results
    matcher.save_results(output_dir)
    
    # Print samples
    matcher.print_sample_matches(15)
    
    print("\n" + "="*80)
    print("✅ Drug matching completed successfully!")
    print(f"📁 Results saved to: {output_dir}")


if __name__ == "__main__":
    main()
