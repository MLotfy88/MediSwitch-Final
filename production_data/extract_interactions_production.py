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
"""

import json
import os
import zipfile
import ijson
import re
from typing import List, Dict, Set, Optional, Tuple
from collections import defaultdict

# Configuration
DOWNLOAD_DIR = 'External_source/drug_interaction/drug-label/downloaded'
OUTPUT_DIR = 'production_data'
OUTPUT_FILE = 'production_data/drug_interactions_clean.json'

# Quality thresholds
MIN_INTERACTION_LENGTH = 50  # Minimum text length
MAX_INTERACTION_LENGTH = 1000  # Maximum to avoid huge blocks
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
            r'\b([A-Z][a-z]+(?:ine|cin|pril|olol|statin|mycin|cillin))\b',
            # CAPITALS DRUG
            r'\b([A-Z]{3,})\b',
            # hyphenated drugs
            r'\b([A-Z][a-z]+(?:-[A-Z][a-z]+)+)\b',
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
            'such', 'been', 'these', 'those', 'some', 'risk', 'effect'
        }
        return word.lower() in common_words
    
    def _extract_drug_classes(self, text: str) -> Set[str]:
        """Extract drug class names (e.g., 'NSAIDs', 'statins')"""
        class_patterns = [
            r'\b(NSAID|NSAIDs)\b',
            r'\b(beta[- ]?blocker|beta[- ]?blockers)\b',
            r'\b(ACE inhibitor|ACE inhibitors)\b',
            r'\b(statin|statins)\b',
            r'\b(anticoagulant|anticoagulants)\b',
            r'\b(antibiotic|antibiotics)\b',
            r'\b(corticosteroid|corticosteroids)\b',
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
        text = re.sub(r'\s+', ' ', text)
        
        # Remove special characters but keep periods, commas, hyphens
        text = re.sub(r'[^\w\s.,;:()\-/%]', '', text)
        
        # Fix spacing around punctuation
        text = re.sub(r'\s+([.,;:])', r'\1', text)
        text = re.sub(r'([.,;:])\s*', r'\1 ', text)
        
        return text.strip()
    
    @staticmethod
    def capitalize_properly(text: str) -> str:
        """Proper capitalization for medical text"""
        if not text:
            return ""
        
        # Capitalize first letter of sentences
        sentences = re.split(r'([.!?]\s+)', text)
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
            r'(?:dose\s+adjustment|reduce\s+dose|increase\s+dose)[^.!?]*[.!?]',
            r'(?:do\s+not|should\s+not)[^.!?]*[.!?]',
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
        if effect.count(',') > 10:  # Too many commas suggests alist
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
            # Add drug classes
            'nsaids', 'ace inhibitors', 'beta blockers', 'statins', 'ssris',
            'anticoagulants', 'corticosteroids', 'opioids', 'benzodiazepines'
        }


def process_file_with_quality(zip_path: str, name_extractor: DrugNameExtractor) -> List[Dict]:
    """Process file with quality validation"""
    interactions = []
    stats = {
        'total_records': 0,
        'has_interactions': 0,
        'passed_validation': 0,
        'rejected_generic_drug': 0,
        'rejected_too_short': 0,
        'rejected_low_confidence': 0
    }
    
    if not os.path.exists(zip_path):
        return interactions
    
    # Extract ZIP
    json_file = zip_path.replace('.zip', '')
    if not os.path.exists(json_file):
        with zipfile.ZipFile(zip_path, 'r') as z:
            z.extractall(os.path.dirname(zip_path))
    
    print(f"\n📄 Processing: {os.path.basename(json_file)}")
    
    formatter = TextFormatter()
    validator = QualityValidator()
    
    try:
        with open(json_file, 'rb') as f:
            parser = ijson.items(f, 'results.item')
            
            for record in parser:
                stats['total_records'] += 1
                
                # Get primary drug name
                openfda = record.get('openfda', {})
                primary_drug = None
                
                for field in ['substance_name', 'generic_name', 'brand_name']:
                    if openfda.get(field):
                        primary_drug = openfda[field][0]
                        break
                
                if not primary_drug:
                    continue
                
                primary_drug = primary_drug.lower().strip()
                
                # Get interaction texts
                interaction_texts = record.get('drug_interactions', [])
                if not interaction_texts:
                    continue
                
                stats['has_interactions'] += 1
                
                # Process each interaction
                for text in interaction_texts:
                    if len(text) < MIN_INTERACTION_LENGTH:
                        stats['rejected_too_short'] += 1
                        continue
                    
                    # Clean and format text
                    cleaned_text = formatter.clean_text(text)
                    formatted_text = formatter.capitalize_properly(cleaned_text)
                    
                    # Extract interacting drugs
                    interacting_drugs = name_extractor.extract_interacting_drugs(
                        formatted_text,
                        primary_drug
                    )
                    
                    if not interacting_drugs:
                        stats['rejected_generic_drug'] += 1
                        continue
                    
                    # Create interactions for each secondary drug
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
                            'effect': formatted_text[:800],  # Limit length
                            'recommendation': recommendation or '',
                            'source': 'OpenFDA',
                            'quality_validated': True
                        }
                        
                        # Validate quality
                        is_valid, confidence, reason = validator.validate_interaction(interaction)
                        
                        if is_valid:
                            interaction['confidence_score'] = round(confidence, 2)
                            interactions.append(interaction)
                            stats['passed_validation'] += 1
                        else:
                            stats['rejected_low_confidence'] += 1
                
                if stats['total_records'] % 5000 == 0:
                    print(f"  Processed {stats['total_records']:,} records")
                    print(f"    ✅ Validated: {stats['passed_validation']:,}")
                    print(f"    ❌ Rejected: {stats['rejected_generic_drug'] + stats['rejected_too_short'] + stats['rejected_low_confidence']:,}")
        
        print(f"\n  📊 Final stats for this file:")
        print(f"    Total records: {stats['total_records']:,}")
        print(f"    With interactions: {stats['has_interactions']:,}")
        print(f"    ✅ Passed validation: {stats['passed_validation']:,}")
        print(f"    ❌ Rejected (generic drug): {stats['rejected_generic_drug']:,}")
        print(f"    ❌ Rejected (too short): {stats['rejected_too_short']:,}")
        print(f"    ❌ Rejected (low confidence): {stats['rejected_low_confidence']:,}")
        
    except Exception as e:
        print(f"  ❌ Error: {e}")
    
    return interactions


def main():
    """Main execution"""
    print("="*80)
    print("Production-Grade Drug Interactions Extractor")
    print("Focus: Quality, Accuracy, Real Drug Names")
    print("="*80)
    
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    # Load known ingredients
    known_ingredients = load_known_ingredients()
    print(f"\n📚 Loaded {len(known_ingredients):,} known pharmaceutical ingredients")
    
    # Initialize extractor
    name_extractor = DrugNameExtractor(known_ingredients)
    
    # Process files (first 3 for testing)
    all_interactions = []
    
    files_to_process = [
        'drug-label-0001-of-0013.json.zip',
        'drug-label-0002-of-0013.json.zip',
        'drug-label-0003-of-0013.json.zip',
    ]
    
    for filename in files_to_process:
        zip_path = os.path.join(DOWNLOAD_DIR, filename)
        interactions = process_file_with_quality(zip_path, name_extractor)
        all_interactions.extend(interactions)
    
    # Deduplicate
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
    print("\n" + "="*80)
    print("📊 FINAL SUMMARY")
    print("="*80)
    print(f"Total interactions extracted: {len(all_interactions):,}")
    print(f"Unique interactions (deduplicated): {len(final_interactions):,}")
    print(f"\nOutput: {OUTPUT_FILE}")
    print(f"Size: {os.path.getsize(OUTPUT_FILE) / 1024:.1f} KB")
    
    # Sample
    print("\n📋 Sample interactions:")
    for i, interaction in enumerate(final_interactions[:3], 1):
        print(f"\n{i}. {interaction['ingredient1'].title()} + {interaction['ingredient2'].title()}")
        print(f"   Severity: {interaction['severity'].upper()} (confidence: {interaction['severity_confidence']})")
        print(f"   Effect: {interaction['effect'][:150]}...")
        if interaction['recommendation']:
            print(f"   Recommendation: {interaction['recommendation']}")
        print(f"   Quality Score: {interaction['confidence_score']}")
    
    print("\n✅ Production-grade extraction complete!")


if __name__ == '__main__':
    main()
