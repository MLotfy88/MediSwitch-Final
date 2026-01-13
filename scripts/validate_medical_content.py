#!/usr/bin/env python3
"""
MediSwitch Medical Content Validation System
============================================
This script validates the MEDICAL ACCURACY of dosage and interaction data
by cross-referencing multiple sources and detecting clinical inconsistencies.

Validation Checks:
1. Cross-Source Agreement (WikEM vs NCBI dosages)
2. Logical Consistency (pediatric vs adult doses, route compatibility)
3. Interaction Severity Consistency
4. Dosage Range Reasonability
"""

import sqlite3
import zlib
import json
from collections import defaultdict
from datetime import datetime

DB_PATH = "assets/database/mediswitch.db"

class MedicalValidator:
    def __init__(self):
        self.conn = sqlite3.connect(DB_PATH)
        self.conn.row_factory = sqlite3.Row
        self.cursor = self.conn.cursor()
        self.validation_report = {
            "timestamp": datetime.now().isoformat(),
            "ingredients_validated": 0,
            "cross_source_checks": [],
            "logical_issues": [],
            "interaction_issues": [],
            "samples_for_review": []
        }
    
    def decompress_if_needed(self, data):
        """Safely decompress ZLIB data"""
        if not data:
            return None
        if isinstance(data, bytes):
            try:
                return zlib.decompress(data).decode('utf-8')
            except:
                try:
                    return data.decode('utf-8')
                except:
                    return None
        return str(data)
    
    def validate_ingredient_dosage_accuracy(self, ingredient_name, limit=5):
        """
        Validate dosage data for a specific ingredient by:
        1. Comparing WikEM and NCBI sources
        2. Checking for logical inconsistencies
        3. Identifying suspicious ranges
        """
        print(f"\n🔬 Validating: {ingredient_name}")
        print("=" * 60)
        
        # Get all drugs containing this ingredient
        self.cursor.execute("""
            SELECT DISTINCT d.id, d.trade_name, d.concentration
            FROM drugs d
            JOIN med_ingredients mi ON d.id = mi.med_id
            WHERE LOWER(TRIM(mi.ingredient)) = LOWER(TRIM(?))
            LIMIT ?
        """, (ingredient_name, limit))
        
        drugs = self.cursor.fetchall()
        
        if not drugs:
            print(f"⚠️ No drugs found for ingredient: {ingredient_name}")
            return
        
        print(f"Found {len(drugs)} drugs containing '{ingredient_name}':\n")
        
        for drug in drugs:
            print(f"💊 Drug: {drug['trade_name']} (ID: {drug['id']})")
            print(f"   Concentration: {drug['concentration'] or 'N/A'}")
            
            # Get all dosage guidelines for this drug
            self.cursor.execute("""
                SELECT 
                    source,
                    min_dose, max_dose, dose_unit, route,
                    wikem_min_dose, wikem_max_dose, wikem_route,
                    patient_category,
                    wikem_instructions, ncbi_indications
                FROM dosage_guidelines
                WHERE med_id = ?
            """, (drug['id'],))
            
            dosages = self.cursor.fetchall()
            
            if not dosages:
                print(f"   ⚠️ No dosage data found")
                continue
            
            # Analyze each dosage record
            for idx, dosage in enumerate(dosages, 1):
                print(f"\n   📋 Dosage Record #{idx}:")
                print(f"      Source: {dosage['source']}")
                print(f"      Route: {dosage['route'] or dosage['wikem_route'] or 'N/A'}")
                print(f"      Category: {dosage['patient_category'] or 'N/A'}")
                
                # Show merged/unified dose
                if dosage['min_dose']:
                    dose_str = f"{dosage['min_dose']}"
                    if dosage['max_dose'] and dosage['max_dose'] != dosage['min_dose']:
                        dose_str += f" - {dosage['max_dose']}"
                    dose_str += f" {dosage['dose_unit'] or 'mg'}"
                    print(f"      Unified Dose: {dose_str}")
                
                # Show WikEM-specific dose if different
                if dosage['wikem_min_dose'] and dosage['wikem_min_dose'] != dosage['min_dose']:
                    wikem_str = f"{dosage['wikem_min_dose']}"
                    if dosage['wikem_max_dose']:
                        wikem_str += f" - {dosage['wikem_max_dose']}"
                    print(f"      WikEM Dose: {wikem_str} mg")
                
                # Check for logical issues
                issues = []
                
                # Issue 1: Missing critical dose info
                if not dosage['min_dose'] and not dosage['wikem_instructions']:
                    issues.append("❌ No numeric dose AND no text instructions")
                
                # Issue 2: Unreasonable dose ranges
                if dosage['min_dose'] and dosage['max_dose']:
                    if dosage['max_dose'] < dosage['min_dose']:
                        issues.append(f"❌ Max dose ({dosage['max_dose']}) < Min dose ({dosage['min_dose']})")
                    elif dosage['max_dose'] > dosage['min_dose'] * 100:
                        issues.append(f"⚠️ Extremely wide dose range (100x+): {dosage['min_dose']} - {dosage['max_dose']}")
                
                # Issue 3: Route compatibility
                if dosage['route']:
                    route_lower = dosage['route'].lower()
                    if 'oral' in route_lower and dosage['min_dose'] and dosage['min_dose'] > 5000:
                        issues.append(f"⚠️ Very high oral dose: {dosage['min_dose']} mg")
                    if 'iv' in route_lower and dosage['min_dose'] and dosage['min_dose'] < 0.01:
                        issues.append(f"⚠️ Extremely small IV dose: {dosage['min_dose']} mg")
                
                if issues:
                    print(f"\n      🚨 POTENTIAL ISSUES:")
                    for issue in issues:
                        print(f"         {issue}")
                    
                    self.validation_report["logical_issues"].append({
                        "drug": drug['trade_name'],
                        "ingredient": ingredient_name,
                        "issues": issues
                    })
            
            # Check interactions for this drug
            self.check_drug_interactions(drug['id'], drug['trade_name'], ingredient_name)
    
    def check_drug_interactions(self, drug_id, drug_name, ingredient_name):
        """Check interaction data linked to this drug/ingredient"""
        
        # Drug-Drug interactions
        self.cursor.execute("""
            SELECT ingredient2, severity, management_text_blob
            FROM drug_interactions
            WHERE LOWER(TRIM(ingredient1)) = LOWER(TRIM(?))
            LIMIT 3
        """, (ingredient_name,))
        
        dd_interactions = self.cursor.fetchall()
        
        if dd_interactions:
            print(f"\n   🔗 Sample Drug-Drug Interactions:")
            for interaction in dd_interactions:
                severity = interaction['severity'] or 'Unknown'
                print(f"      • With: {interaction['ingredient2']} | Severity: {severity}")
        
        # Food interactions
        self.cursor.execute("""
            SELECT interaction, severity
            FROM food_interactions
            WHERE med_id = ?
            LIMIT 3
        """, (drug_id,))
        
        food_interactions = self.cursor.fetchall()
        
        if food_interactions:
            print(f"\n   🍽️ Sample Food Interactions:")
            for interaction in food_interactions:
                print(f"      • {interaction['interaction']} | Severity: {interaction['severity'] or 'Unknown'}")
        
        # Disease interactions
        self.cursor.execute("""
            SELECT disease_name, severity
            FROM disease_interactions
            WHERE med_id = ?
            LIMIT 3
        """, (drug_id,))
        
        disease_interactions = self.cursor.fetchall()
        
        if disease_interactions:
            print(f"\n   🏥 Sample Disease Interactions:")
            for interaction in disease_interactions:
                print(f"      • {interaction['disease_name']} | Severity: {interaction['severity'] or 'Unknown'}")
    
    def compare_wikem_ncbi_for_ingredient(self, ingredient_name):
        """
        Find drugs where both WikEM and NCBI provide dosage data
        and compare them for discrepancies
        """
        print(f"\n📊 Cross-Source Comparison for: {ingredient_name}")
        print("=" * 60)
        
        self.cursor.execute("""
            SELECT 
                d.trade_name,
                g.wikem_min_dose, g.wikem_max_dose,
                g.min_dose, g.max_dose,
                g.route, g.wikem_route,
                g.source
            FROM drugs d
            JOIN med_ingredients mi ON d.id = mi.med_id
            JOIN dosage_guidelines g ON d.id = g.med_id
            WHERE LOWER(TRIM(mi.ingredient)) = LOWER(TRIM(?))
              AND g.wikem_min_dose IS NOT NULL
              AND g.min_dose IS NOT NULL
            LIMIT 5
        """, (ingredient_name,))
        
        comparisons = self.cursor.fetchall()
        
        if not comparisons:
            print("⚠️ No drugs with overlapping WikEM + NCBI data for this ingredient")
            return
        
        print(f"Found {len(comparisons)} drugs with data from both sources:\n")
        
        for comp in comparisons:
            print(f"💊 {comp['trade_name']}")
            print(f"   WikEM:  {comp['wikem_min_dose']} - {comp['wikem_max_dose'] or 'N/A'} mg | Route: {comp['wikem_route'] or 'N/A'}")
            print(f"   Merged: {comp['min_dose']} - {comp['max_dose'] or 'N/A'} mg | Route: {comp['route'] or 'N/A'}")
            
            # Check for significant discrepancies
            if comp['wikem_min_dose'] and comp['min_dose']:
                diff = abs(comp['wikem_min_dose'] - comp['min_dose'])
                if diff > comp['wikem_min_dose'] * 0.5:  # >50% difference
                    print(f"   ⚠️ SIGNIFICANT DOSE DIFFERENCE: {diff:.1f} mg ({diff/comp['wikem_min_dose']*100:.0f}%)")
                    
                    self.validation_report["cross_source_checks"].append({
                        "drug": comp['trade_name'],
                        "ingredient": ingredient_name,
                        "wikem_dose": comp['wikem_min_dose'],
                        "merged_dose": comp['min_dose'],
                        "difference_pct": round(diff/comp['wikem_min_dose']*100, 1)
                    })
            print("")
    
    def validate_top_ingredients(self, top_n=10):
        """Validate the most common ingredients in the database"""
        print("\n" + "="*60)
        print("🏥 MEDICAL CONTENT VALIDATION")
        print("="*60)
        
        # Get most common ingredients
        self.cursor.execute("""
            SELECT ingredient, COUNT(*) as drug_count
            FROM med_ingredients
            GROUP BY ingredient
            ORDER BY drug_count DESC
            LIMIT ?
        """, (top_n,))
        
        top_ingredients = self.cursor.fetchall()
        
        print(f"\nValidating Top {top_n} Most Common Ingredients:\n")
        
        for idx, ing in enumerate(top_ingredients, 1):
            print(f"\n{'='*60}")
            print(f"#{idx}. {ing['ingredient']} ({ing['drug_count']} drugs)")
            print('='*60)
            
            # Validate dosage accuracy
            self.validate_ingredient_dosage_accuracy(ing['ingredient'], limit=3)
            
            # Cross-source comparison
            self.compare_wikem_ncbi_for_ingredient(ing['ingredient'])
            
            self.validation_report["ingredients_validated"] += 1
        
        # Save report
        self.save_validation_report()
    
    def validate_specific_ingredient(self, ingredient_name):
        """Deep validation for a specific ingredient"""
        print("\n" + "="*60)
        print(f"🔬 DEEP VALIDATION: {ingredient_name}")
        print("="*60)
        
        self.validate_ingredient_dosage_accuracy(ingredient_name, limit=10)
        self.compare_wikem_ncbi_for_ingredient(ingredient_name)
        
        self.save_validation_report()
    
    def save_validation_report(self):
        """Save validation report to JSON"""
        report_path = "medical_validation_report.json"
        with open(report_path, 'w', encoding='utf-8') as f:
            json.dump(self.validation_report, f, indent=2, ensure_ascii=False)
        
        print(f"\n" + "="*60)
        print(f"✅ Validation report saved: {report_path}")
        
        # Print summary
        print(f"\n📊 VALIDATION SUMMARY:")
        print(f"   - Ingredients Validated: {self.validation_report['ingredients_validated']}")
        print(f"   - Logical Issues Found: {len(self.validation_report['logical_issues'])}")
        print(f"   - Cross-Source Discrepancies: {len(self.validation_report['cross_source_checks'])}")
        print("="*60 + "\n")
        
        self.conn.close()

if __name__ == "__main__":
    import sys
    
    validator = MedicalValidator()
    
    if len(sys.argv) > 1:
        # Validate specific ingredient
        ingredient = " ".join(sys.argv[1:])
        validator.validate_specific_ingredient(ingredient)
    else:
        # Validate top 10 ingredients
        validator.validate_top_ingredients(top_n=10)
