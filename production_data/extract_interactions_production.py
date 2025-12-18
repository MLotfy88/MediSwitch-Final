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

Source: 
1. production_data/dailymed_full_database.jsonl.gz (Unified)
2. production_data/dailymed_full/part_*.gz (Split Parts - fallback)
"""

import json
import os
import gzip
import re
import glob
import shutil
import tempfile
from typing import List, Dict, Set, Optional, Tuple, Generator
from collections import defaultdict

# Configuration
INPUT_FILE = 'production_data/dailymed_full_database.jsonl.gz'
INPUT_DIR = 'production_data/dailymed_full'
OUTPUT_DIR = 'production_data'
OUTPUT_FILE = 'production_data/dailymed_interactions.json' 

# Quality thresholds
MIN_INTERACTION_LENGTH = 50  # Minimum text length
MAX_INTERACTION_LENGTH = 2000  # Maximum to avoid huge blocks
MIN_CONFIDENCE_SCORE = 0.7  # Minimum confidence to include

# Known pharmaceutical ingredients
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
        """Extract drug class names"""
        class_patterns = [
            r'\b(NSAID|NSAIDs)\b',
            r'\b(beta[- ]?blocker|beta[- ]?blockers)\b',
            r'\b(ACE inhibitor|ACE inhibitors)\b',
            r'\b(statin|statins)\b',
            r'\b(anticoagulant|anticoagulants)\b',
            r'\b(antibiotic|antibiotics)\b',
            r'\b(corticosteroid|corticosteroids)\b',
            r'\b(diuretic|diuretics)\b',
            r'\b(MAO inhibitor|MAO inhibitors|MAOI|MAOIs)\b',
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
        
        # Remove special characters but keep periods, commas, hyphens, percents
        # FIXED: Hyphen '-' moved to the end to avoid regex range error
        text = re.sub(r'[^\w\s.,;:()/%-]', '', text)
        
        # Fix spacing around punctuation
        text = re.sub(r'\s+([.,;:])', r'\1', text)
        text = re.sub(r'([.,;:])\s*', r'\1 ', text)
        
        return text.strip()
    
    @staticmethod
    def capitalize_properly(text: str) -> str:
        """Proper capitalization for medical text"""
        if not text:
            return ""
        
        sentences = re.split(r'([.!?]\s+)', text)
        formatted = []
        
        for i, part in enumerate(sentences):
            if i % 2 == 0:  # Actual sentence
                if part:
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
        
        # Check 1: Has real secondary drug
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
        
        # Check 4: Text quality
        if not effect.strip().endswith(('.', '!', '?')):
            score -= 0.1
            reasons.append("Incomplete sentence")
        
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
        return {
            'warfarin', 'aspirin', 'ibuprofen', 'acetaminophen', 'metformin',
            'lisinopril', 'atorvastatin', 'amlodipine', 'metoprolol', 'losartan',
            'hydrochlorothiazide', 'gabapentin', 'omeprazole', 'albuterol'
        }


def get_input_stream() -> Generator[str, None, None]:
    """
    Get lines from the input file.
    Handles both Unified GZIP file and Split Parts (concatenation).
    """
    
    # 1. Try Unified File
    if os.path.exists(INPUT_FILE):
        print(f"📖 Reading from Unified DB: {INPUT_FILE}")
        with gzip.open(INPUT_FILE, 'rt', encoding='utf-8') as f:
            for line in f:
                yield line
        return

    # 2. Try Split Parts (Reassemble on the fly)
    part_files = sorted(glob.glob(os.path.join(INPUT_DIR, "part_*.gz")))
    if part_files:
        print(f"🧩 Reading from {len(part_files)} split parts in {INPUT_DIR}...")
        
        # Create a temporary file to hold the concatenated gzip stream
        # (Needed because gzip doesn't support reading multiple concatenated streams nicely in all versions,
        # but concatenation of gzip files corresponds to concatenation of streams)
        
        # Strategy: Use a temp file to concat, then read. 
        # Safer than on-the-fly for compatibility.
        with tempfile.TemporaryFile() as temp_gz:
            for part in part_files:
                print(f"   + Stripping/Concatenating {os.path.basename(part)}")
                with open(part, 'rb') as p:
                    shutil.copyfileobj(p, temp_gz)
            
            print("   -> Decompressing unified stream...")
            temp_gz.seek(0)
            
            with gzip.open(temp_gz, 'rt', encoding='utf-8') as f:
                for line in f:
                    yield line
        return
    
    raise FileNotFoundError("Reference database not found (neither Unified .gz nor Split parts)")


def main():
    """Main execution"""
    print("="*80)
    print("Production-Grade Drug Interactions Extractor")
    print("="*80)
    
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    # Load known ingredients
    known_ingredients = load_known_ingredients()
    print(f"\\n📚 Loaded {len(known_ingredients):,} known pharmaceutical ingredients")
    
    # Initialize extractor
    name_extractor = DrugNameExtractor(known_ingredients)
    formatter = TextFormatter()
    validator = QualityValidator()
    
    all_interactions = []
    stats = {
        'total_records': 0,
        'has_interaction': 0,
        'valid': 0
    }
    
    try:
        # Stream records
        for line in get_input_stream():
            if not line.strip(): continue
            try:
                record = json.loads(line)
            except:
                continue
            
            stats['total_records'] += 1
            
            # --- Extraction Logic ---
            
            # 1. Primary Drug
            primary_drug = None
            products = record.get('products', [])
            if products:
                primary_drug = products[0].get('non_proprietary_name') or products[0].get('proprietary_name')
            
            if not primary_drug: continue
            primary_drug = primary_drug.lower().strip()
            
            # 2. Interaction Text
            clinical = record.get('clinical_data', {})
            interaction_text = clinical.get('drug_interactions')
            
            if not interaction_text or len(interaction_text) < MIN_INTERACTION_LENGTH:
                continue
                
            stats['has_interaction'] += 1
            
            # 3. Clean & Process
            cleaned_text = formatter.clean_text(interaction_text)
            formatted_text = formatter.capitalize_properly(cleaned_text)
            
            # 4. Find Secondary Drugs
            interacting_drugs = name_extractor.extract_interacting_drugs(formatted_text, primary_drug)
            
            # 5. Create Records
            for secondary_drug in interacting_drugs:
                severity, sev_conf = SeverityClassifier.classify(formatted_text)
                recommendation = formatter.extract_recommendation(formatted_text)
                
                interaction = {
                    'ingredient1': primary_drug,
                    'ingredient2': secondary_drug,
                    'severity': severity,
                    'severity_confidence': round(sev_conf, 2),
                    'effect': formatted_text[:1000],
                    'recommendation': recommendation or '',
                    'source': 'DailyMed',
                    'quality_validated': True
                }
                
                is_valid, conf, _ = validator.validate_interaction(interaction)
                
                if is_valid:
                    interaction['confidence_score'] = round(conf, 2)
                    all_interactions.append(interaction)
                    stats['valid'] += 1
            
            if stats['total_records'] % 5000 == 0:
                print(f"  Scanned {stats['total_records']:,} | Interactions Found: {stats['valid']:,}")

    except Exception as e:
        print(f"\\n❌ FATAL ERROR: {e}")
        return

    # Deduplicate
    print(f"\\nDeduplicating {len(all_interactions):,} raw interactions...")
    unique_interactions = {}
    for interaction in all_interactions:
        key = (interaction['ingredient1'], interaction['ingredient2'], interaction['severity'])
        if key not in unique_interactions:
            unique_interactions[key] = interaction
        else:
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
    print(f"Total Scanned: {stats['total_records']:,}")
    print(f"Total interactions extracted: {len(all_interactions):,}")
    print(f"Unique interactions (deduplicated): {len(final_interactions):,}")
    print(f"\\nOutput: {OUTPUT_FILE}")
    print(f"Size: {os.path.getsize(OUTPUT_FILE) / 1024:.1f} KB")
    
    print("\\n✅ Production-grade extraction complete!")

if __name__ == '__main__':
    main()
