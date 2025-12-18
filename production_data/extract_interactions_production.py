#!/usr/bin/env python3
"""
Production-Grade Drug Interactions Extractor
استخراج تفاعلات دوائية دقيقة وموثوقة

Requirements:
1. Real drug names (ingredient1 + ingredient2) - NO "other medicine" or "multiple"
2. Complete, well-formatted text (proper capitalization)
3. Clear severity levels
4. Recommendations when available
5. Quality validation

Source: production_data/dailymed_full/ (Split GZIP JSONL)
"""

import json
import os
import gzip
import re
import glob
from typing import List, Dict, Set, Optional, Tuple
from collections import defaultdict

# Configuration
INPUT_DIR = 'production_data/dailymed_full'
OUTPUT_DIR = 'production_data'
OUTPUT_FILE = 'production_data/dailymed_interactions.json' # Unified name

# Quality thresholds
MIN_INTERACTION_LENGTH = 50  # Minimum text length
MAX_INTERACTION_LENGTH = 2000  # Maximum to avoid huge blocks (Increased for DailyMed)
MIN_CONFIDENCE_SCORE = 0.7  # Minimum confidence to include

# Known pharmaceutical ingredients (will be expanded)
KNOWN_INGREDIENTS_FILE = 'production_data/known_ingredients.json'


class DrugNameExtractor:
    """Advanced drug name extraction from interaction text"""
    
    def __init__(self, known_ingredients: Set[str]):
        self.known_ingredients = {ing.lower() for ing in known_ingredients}
        
        # Common drug patterns
        self.drug_patterns = [
            # "Drug X" or "Drug Y"
            r'\\b([A-Z][a-z]+(?:ine|cin|pril|olol|statin|mycin|cillin))\\b',
            # CAPITALS DRUG
            r'\\b([A-Z]{3,})\\b',
            # hyphenated drugs
            r'\\b([A-Z][a-z]+(?:-[A-Z][a-z]+)+)\\b',
        ]
    
    def extract_interacting_drugs(self, text: str, primary_drug: str) -> List[str]:
        """
        Extract list of drugs mentioned in interaction text
        Returns real drug names only (excludes generic terms)
        """
        candidates = set()
        text_lower = text.lower()
        primary_lower = primary_drug.lower()
        
        # Method 1: Known ingredients
        for ingredient in self.known_ingredients:
            if ingredient in text_lower and ingredient != primary_lower:
                # Basic context check: Ensure it's not part of a longer word?
                # For now, strict inclusion is okay if list is curated
                candidates.add(ingredient)
        
        # Method 2: Pattern matching
        for pattern in self.drug_patterns:
            matches = re.findall(pattern, text)
            for match in matches:
                match_lower = match.lower()
                if match_lower != primary_lower and len(match) > 3:
                    # Validate it's not a common word
                    if not self._is_common_word(match):
                        candidates.add(match_lower)
        
        # Method 3: Drug class detection
        drug_classes = self._extract_drug_classes(text)
        candidates.update(drug_classes)
        
        return list(candidates)
    
    def _is_common_word(self, word: str) -> bool:
        """Filter out common English words that aren't drugs"""
        common_words = {
            'the', 'and', 'with', 'use', 'when', 'may', 'can', 'should',
            'take', 'dose', 'drug', 'this', 'other', 'have', 'been',
            'such', 'been', 'these', 'those', 'some', 'risk', 'effect',
            'medical', 'doctor', 'patient', 'please', 'contact', 'information'
        }
        return word.lower() in common_words
    
    def _extract_drug_classes(self, text: str) -> Set[str]:
        """Extract drug class names (e.g., 'NSAIDs', 'statins')"""
        class_patterns = [
            r'\\b(NSAID|NSAIDs)\\b',
            r'\\b(beta[- ]?blocker|beta[- ]?blockers)\\b',
            r'\\b(ACE inhibitor|ACE inhibitors)\\b',
            r'\\b(statin|statins)\\b',
            r'\\b(anticoagulant|anticoagulants)\\b',
            r'\\b(antibiotic|antibiotics)\\b',
            r'\\b(corticosteroid|corticosteroids)\\b',
            r'\\b(diuretic|diuretics)\\b',
            r'\\b(MAO inhibitor|MAO inhibitors|MAOI|MAOIs)\\b',
        ]
        
        classes = set()
        for pattern in class_patterns:
            matches = re.findall(pattern, text, re.IGNORECASE)
            for match in matches:
                classes.add(match.lower())
        
        return classes


class TextFormatter:
    """Format и clean interaction text for production"""
    
    @staticmethod
    def clean_text(text: str) -> str:
        """Clean and normalize text"""
        if not text:
            return ""
        
        # Remove excessive whitespace
        text = re.sub(r'\\s+', ' ', text)
        
        # Remove special characters but keep periods, commas, hyphens, percents
        text = re.sub(r'[^\\w\\s.,;:()\\-/%]', '', text)
        
        # Fix spacing around punctuation
        text = re.sub(r'\\s+([.,;:])', r'\\1', text)
        text = re.sub(r'([.,;:])\\s*', r'\\1 ', text)
        
        return text.strip()
    
    @staticmethod
    def capitalize_properly(text: str) -> str:
        """Proper capitalization for medical text"""
        if not text:
            return ""
        
        # Capitalize first letter of sentences
        sentences = re.split(r'([.!?]\\s+)', text)
        formatted = []
        
        for i, part in enumerate(sentences):
            if i % 2 == 0:  # Actual sentence
                if part:
                    # Capitalize first letter
                    part = part[0].upper() + part[1:] if len(part) > 1 else part.upper()
            formatted.append(part)
        
        return ''.join(formatted)
    
    @staticmethod
    def extract_recommendation(text: str) -> Optional[str]:
        """Extract recommendation/advice from text"""
        recommendation_patterns = [
            r'(?:recommendation|caution|contraindication|avoid|should|must|monitor)[^.!?]*[.!?]',
            r'(?:dose\\s+adjustment|reduce\\s+dose|increase\\s+dose)[^.!?]*[.!?]',
            r'(?:do\\s+not|should\\s+not)[^.!?]*[.!?]',
        ]
        
        for pattern in recommendation_patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                recommendation = match.group(0)
                return TextFormatter.capitalize_properly(recommendation.strip())
        
        return None


class SeverityClassifier:
    """Classify interaction severity with confidence"""
    
    SEVERITY_KEYWORDS = {
        'contraindicated': {
            'keywords': ['contraindicated', 'do not use', 'must not', 'life-threatening', 'fatal', 'death'],
            'score': 1.0
        },
        'severe': {
            'keywords': ['severe', 'serious', 'major', 'significant risk', 'dangerous', 'toxic'],
            'score': 0.9
        },
        'major': {
            'keywords': ['major', 'important', 'significant', 'substantial', 'marked'],
            'score': 0.7
        },
        'moderate': {
            'keywords': ['moderate', 'caution', 'monitor', 'watch', 'careful'],
            'score': 0.5
        },
        'minor': {
            'keywords': ['minor', 'mild', 'slight', 'minimal'],
            'score': 0.3
        }
    }
    
    @classmethod
    def classify(cls, text: str) -> Tuple[str, float]:
        """
        Classify severity and return confidence score
        Returns: (severity_level, confidence)
        """
        text_lower = text.lower()
        
        best_match = ('minor', 0.3)
        highest_score = 0
        
        for severity, data in cls.SEVERITY_KEYWORDS.items():
            for keyword in data['keywords']:
                if keyword in text_lower:
                    if data['score'] > highest_score:
                        highest_score = data['score']
                        best_match = (severity, data['score'])
        
        return best_match


class QualityValidator:
    """Validate interaction quality"""
    
    @staticmethod
    def validate_interaction(interaction: Dict) -> Tuple[bool, float, str]:
        """
        Validate interaction quality
        Returns: (is_valid, confidence_score, reason)
        """
        score = 1.0
        reasons = []
        
        # Check 1: Has real secondary drug (not "other" or "multiple")
        ingredient2 = interaction.get('ingredient2', '').lower()
        if ingredient2 in ['other', 'multiple', 'other_medications', 'various', 'unknown']:
            return False, 0.0, "Generic secondary drug name"
        
        if not ingredient2 or len(ingredient2) < 3:
            return False, 0.0, "Missing or invalid secondary drug"
        
        # Check 2: Effect text quality
        effect = interaction.get('effect', '')
        if len(effect) < MIN_INTERACTION_LENGTH:
            return False, 0.0, f"Effect text too short ({len(effect)} chars)"
        
        if len(effect) > MAX_INTERACTION_LENGTH:
            score -= 0.2
            reasons.append("Effect text very long")
        
        # Check 3: Has severity
        severity = interaction.get('severity', '')
        if not severity or severity == 'unknown':
            score -= 0.3
            reasons.append("Unknown severity")
        
        # Check 4: Text quality (complete sentences)
        if not effect.strip().endswith(('.', '!', '?')):
            score -= 0.1
            reasons.append("Incomplete sentence")
        
        # Check 5: Has meaningful content (not just lists)
        if effect.count(',') > 15:  # Slightly more lenient for long blocks
            score -= 0.2
            reasons.append("Text appears to be a list")
        
        is_valid = score >= MIN_CONFIDENCE_SCORE
        reason = "; ".join(reasons) if reasons else "Passed all checks"
        
        return is_valid, score, reason


def load_known_ingredients() -> Set[str]:
    """Load known pharmaceutical ingredients"""
    try:
        with open(KNOWN_INGREDIENTS_FILE, 'r') as f:
            data = json.load(f)
            return set(data.get('ingredients', []))
    except:
        # Bootstrap with common ingredients
        return {
            'warfarin', 'aspirin', 'ibuprofen', 'acetaminophen', 'metformin',
            'lisinopril', 'atorvastatin', 'amlodipine', 'metoprolol', 'losartan',
            'hydrochlorothiazide', 'gabapentin', 'omeprazole', 'albuterol',
            'levothyroxine', 'amoxicillin', 'citalopram', 'atenolol', 'furosemide',
            'ciprofloxacin', 'azithromycin', 'doxycycline', 'tramadol', 'clopidogrel',
            # Add drug classes
            'nsaids', 'ace inhibitors', 'beta blockers', 'statins', 'ssris',
            'anticoagulants', 'corticosteroids', 'opioids', 'benzodiazepines'
        }


def process_part_file(file_path: str, name_extractor: DrugNameExtractor) -> List[Dict]:
    """Process a single GZIP JSONL part file"""
    interactions = []
    stats = {
        'total_records': 0,
        'has_interaction_text': 0,
        'passed_validation': 0,
        'rejected': 0
    }
    
    print(f"\\n📄 Processing: {os.path.basename(file_path)}")
    
    formatter = TextFormatter()
    validator = QualityValidator()
    
    try:
        with gzip.open(file_path, 'rt', encoding='utf-8') as f:
            for line in f:
                if not line.strip(): continue
                try:
                    record = json.loads(line)
                except:
                    continue
                
                stats['total_records'] += 1
                
                # 1. Get Primary Drug Name
                primary_drug = None
                products = record.get('products', [])
                if products:
                    # Prefer generic name, then proprietary
                    primary_drug = products[0].get('non_proprietary_name') or products[0].get('proprietary_name')
                
                if not primary_drug:
                    continue
                
                primary_drug = primary_drug.lower().strip()
                
                # 2. Get Interaction Text
                clinical = record.get('clinical_data', {})
                interaction_text = clinical.get('drug_interactions')
                
                if not interaction_text:
                    continue
                
                stats['has_interaction_text'] += 1
                
                if len(interaction_text) < MIN_INTERACTION_LENGTH:
                    continue
                
                # 3. Clean Text
                cleaned_text = formatter.clean_text(interaction_text)
                formatted_text = formatter.capitalize_properly(cleaned_text)
                
                # 4. Extract Interacting Drugs
                interacting_drugs = name_extractor.extract_interacting_drugs(
                    formatted_text,
                    primary_drug
                )
                
                if not interacting_drugs:
                    stats['rejected'] += 1
                    continue
                
                # 5. Create Interaction Records
                for secondary_drug in interacting_drugs:
                    # Classify severity
                    severity, severity_confidence = SeverityClassifier.classify(formatted_text)
                    
                    # Extract recommendation
                    recommendation = formatter.extract_recommendation(formatted_text)
                    
                    # Create interaction record
                    interaction = {
                        'ingredient1': primary_drug,
                        'ingredient2': secondary_drug,
                        'severity': severity,
                        'severity_confidence': round(severity_confidence, 2),
                        'effect': formatted_text[:1000],  # Limit length (slightly larger for DailyMed)
                        'recommendation': recommendation or '',
                        'source': 'DailyMed_Full',
                        'quality_validated': True
                    }
                    
                    # Validate quality
                    is_valid, confidence, reason = validator.validate_interaction(interaction)
                    
                    if is_valid:
                        interaction['confidence_score'] = round(confidence, 2)
                        interactions.append(interaction)
                        stats['passed_validation'] += 1
                    else:
                        stats['rejected'] += 1
                
                if stats['total_records'] % 2000 == 0:
                     print(f"  Scanned {stats['total_records']:,} | Found {stats['passed_validation']:,} valid interactions...")
        
        print(f"  Summary for file: {stats['passed_validation']:,} interactions found.")
        
    except Exception as e:
        print(f"  ❌ Error reading file: {e}")
        
    return interactions


def main():
    """Main execution"""
    print("="*80)
    print("Production-Grade Drug Interactions Extractor")
    print(f"Source: {INPUT_DIR}")
    print("="*80)
    
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    # Load known ingredients
    known_ingredients = load_known_ingredients()
    print(f"\\n📚 Loaded {len(known_ingredients):,} known pharmaceutical ingredients")
    
    # Initialize extractor
    name_extractor = DrugNameExtractor(known_ingredients)
    
    # Find all part files
    part_files = sorted(glob.glob(os.path.join(INPUT_DIR, "part_*.gz")))
    
    if not part_files:
        print(f"❌ No part files found in {INPUT_DIR}")
        return
        
    print(f"Found {len(part_files)} part files.")
    
    all_interactions = []
    
    # Process files
    for file_path in part_files:
        interactions = process_part_file(file_path, name_extractor)
        all_interactions.extend(interactions)
    
    # Deduplicate
    print(f"\\nDeduplicating {len(all_interactions):,} raw interactions...")
    unique_interactions = {}
    for interaction in all_interactions:
        key = (
            interaction['ingredient1'],
            interaction['ingredient2'],
            interaction['severity']
        )
        
        if key not in unique_interactions:
            unique_interactions[key] = interaction
        else:
            # Keep the one with higher confidence
            if interaction['confidence_score'] > unique_interactions[key]['confidence_score']:
                unique_interactions[key] = interaction
    
    final_interactions = list(unique_interactions.values())
    
    # Save
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(final_interactions, f, indent=2, ensure_ascii=False)
    
    # Summary
    print("\\n" + "="*80)
    print("📊 FINAL SUMMARY")
    print("="*80)
    print(f"Total interactions extracted: {len(all_interactions):,}")
    print(f"Unique interactions (deduplicated): {len(final_interactions):,}")
    print(f"\\nOutput: {OUTPUT_FILE}")
    print(f"Size: {os.path.getsize(OUTPUT_FILE) / 1024:.1f} KB")
    
    # Sample
    if final_interactions:
        print("\\n📋 Sample interactions:")
        for i, interaction in enumerate(final_interactions[:3], 1):
            print(f"\\n{i}. {interaction['ingredient1'].title()} + {interaction['ingredient2'].title()}")
            print(f"   Severity: {interaction['severity'].upper()} (confidence: {interaction['severity_confidence']})")
            print(f"   Effect: {interaction['effect'][:150]}...")
            if interaction['recommendation']:
                print(f"   Recommendation: {interaction['recommendation']}")
            print(f"   Quality Score: {interaction['confidence_score']}")
    
    print("\\n✅ Production-grade extraction complete!")


if __name__ == '__main__':
    main()
