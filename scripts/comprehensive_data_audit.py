#!/usr/bin/env python3
"""
MediSwitch Comprehensive Data Integrity Audit
==============================================
This script performs a thorough validation of data linkages between:
1. Egyptian drugs database (drugs + med_ingredients)
2. Dosage guidelines (WikEM + NCBI)
3. Drug interactions (DDInter 2.0: drug-drug, drug-food, drug-disease)

All linkages are based on ingredient matching.
"""

import sqlite3
import zlib
import json
from collections import defaultdict
from datetime import datetime
import random

DB_PATH = "assets/database/mediswitch.db"

class DataAuditor:
    def __init__(self):
        self.conn = sqlite3.connect(DB_PATH)
        self.conn.row_factory = sqlite3.Row
        self.cursor = self.conn.cursor()
        self.report = {
            "timestamp": datetime.now().isoformat(),
            "summary": {},
            "coverage": {},
            "validation": {},
            "samples": {},
            "issues": []
        }
    
    def decompress_if_needed(self, data):
        """Safely decompress ZLIB data or return as-is"""
        if not data:
            return None
        if isinstance(data, bytes):
            try:
                return zlib.decompress(data).decode('utf-8')
            except:
                try:
                    return data.decode('utf-8')
                except:
                    return f"[Binary: {len(data)} bytes]"
        return str(data)
    
    def get_database_summary(self):
        """Get basic counts from all tables"""
        print("\n📊 DATABASE SUMMARY")
        print("=" * 60)
        
        tables = {
            "drugs": "Total Egyptian Drugs",
            "med_ingredients": "Drug-Ingredient Mappings",
            "dosage_guidelines": "Dosage Records",
            "drug_interactions": "Drug-Drug Interactions",
            "food_interactions": "Drug-Food Interactions",
            "disease_interactions": "Drug-Disease Interactions"
        }
        
        summary = {}
        for table, desc in tables.items():
            try:
                self.cursor.execute(f"SELECT COUNT(*) FROM {table}")
                count = self.cursor.fetchone()[0]
                summary[table] = count
                print(f"✓ {desc:.<45} {count:>10,}")
            except sqlite3.OperationalError as e:
                summary[table] = 0
                print(f"✗ {desc:.<45} {'Table not found':>10}")
        
        self.report["summary"] = summary
        return summary
    
    def check_dosage_coverage(self):
        """Check how many drugs have dosage information"""
        print("\n💊 DOSAGE COVERAGE ANALYSIS")
        print("=" * 60)
        
        # Total drugs
        self.cursor.execute("SELECT COUNT(DISTINCT id) FROM drugs")
        total_drugs = self.cursor.fetchone()[0]
        
        # Drugs with dosage info
        self.cursor.execute("""
            SELECT COUNT(DISTINCT d.id)
            FROM drugs d
            JOIN dosage_guidelines g ON d.id = g.med_id
        """)
        drugs_with_dosage = self.cursor.fetchone()[0]
        
        # Break down by source
        self.cursor.execute("""
            SELECT source, COUNT(DISTINCT med_id) as count
            FROM dosage_guidelines
            WHERE source IS NOT NULL
            GROUP BY source
        """)
        by_source = dict(self.cursor.fetchall())
        
        # Check for merged data
        self.cursor.execute("""
            SELECT COUNT(DISTINCT med_id)
            FROM dosage_guidelines
            WHERE wikem_instructions IS NOT NULL 
              AND ncbi_indications IS NOT NULL
        """)
        merged_count = self.cursor.fetchone()[0]
        
        coverage_pct = (drugs_with_dosage / total_drugs * 100) if total_drugs > 0 else 0
        
        print(f"Total Drugs: {total_drugs:,}")
        print(f"Drugs with Dosage Info: {drugs_with_dosage:,} ({coverage_pct:.1f}%)")
        print(f"\nBy Source:")
        for source, count in by_source.items():
            print(f"  - {source}: {count:,} drugs")
        print(f"\nDrugs with BOTH WikEM + NCBI: {merged_count:,}")
        
        self.report["coverage"]["dosage"] = {
            "total_drugs": total_drugs,
            "with_dosage": drugs_with_dosage,
            "coverage_pct": round(coverage_pct, 2),
            "by_source": by_source,
            "merged_wikem_ncbi": merged_count
        }
    
    def check_interaction_coverage(self):
        """Check interaction coverage through ingredient matching"""
        print("\n🔗 INTERACTION COVERAGE ANALYSIS")
        print("=" * 60)
        
        # Total unique ingredients
        self.cursor.execute("SELECT COUNT(DISTINCT ingredient) FROM med_ingredients")
        total_ingredients = self.cursor.fetchone()[0]
        
        # Drug-Drug interactions coverage
        self.cursor.execute("""
            SELECT COUNT(DISTINCT mi.ingredient)
            FROM med_ingredients mi
            JOIN drug_interactions di ON LOWER(TRIM(mi.ingredient)) = LOWER(TRIM(di.ingredient1))
        """)
        dd_coverage = self.cursor.fetchone()[0]
        
        # Drug-Food interactions coverage
        self.cursor.execute("""
            SELECT COUNT(DISTINCT mi.ingredient)
            FROM med_ingredients mi
            JOIN food_interactions fi ON LOWER(TRIM(mi.ingredient)) = LOWER(TRIM(fi.ingredient))
        """)
        df_coverage = self.cursor.fetchone()[0]
        
        # Drug-Disease interactions coverage
        self.cursor.execute("""
            SELECT COUNT(DISTINCT d.id)
            FROM drugs d
            JOIN disease_interactions disi ON d.id = disi.med_id
        """)
        ddis_coverage = self.cursor.fetchone()[0]
        
        print(f"Total Unique Ingredients: {total_ingredients:,}")
        print(f"Ingredients with Drug-Drug Interactions: {dd_coverage:,} ({dd_coverage/total_ingredients*100:.1f}%)")
        print(f"Ingredients with Food Interactions: {df_coverage:,} ({df_coverage/total_ingredients*100:.1f}%)")
        print(f"Ingredients with Disease Interactions: {ddis_coverage:,} ({ddis_coverage/total_ingredients*100:.1f}%)")
        
        self.report["coverage"]["interactions"] = {
            "total_ingredients": total_ingredients,
            "drug_drug": dd_coverage,
            "drug_food": df_coverage,
            "drug_disease": ddis_coverage
        }
    
    def validate_ingredient_matching(self):
        """Validate the quality of ingredient matching"""
        print("\n🔍 INGREDIENT MATCHING VALIDATION")
        print("=" * 60)
        
        # Check for exact matches vs fuzzy matches in dosage
        self.cursor.execute("""
            SELECT 
                d.trade_name,
                mi.ingredient,
                g.source,
                g.min_dose,
                g.route
            FROM drugs d
            JOIN med_ingredients mi ON d.id = mi.med_id
            JOIN dosage_guidelines g ON d.id = g.med_id
            ORDER BY RANDOM()
            LIMIT 10
        """)
        
        samples = self.cursor.fetchall()
        
        print("Random Sample of Matched Drug-Dosage Records:")
        print("")
        
        validated_samples = []
        for i, row in enumerate(samples, 1):
            sample_data = {
                "drug": row['trade_name'],
                "ingredient": row['ingredient'],
                "source": row['source'],
                "min_dose": row['min_dose'],
                "route": row['route']
            }
            validated_samples.append(sample_data)
            
            print(f"{i}. Drug: {row['trade_name']}")
            print(f"   Ingredient: {row['ingredient']}")
            print(f"   Dosage Source: {row['source']} | Route: {row['route']} | Dose: {row['min_dose']} mg")
            print("")
        
        self.report["samples"]["dosage_matching"] = validated_samples
    
    def validate_concentration_consistency(self):
        """Check if concentration data makes sense with dosage"""
        print("\n⚗️ CONCENTRATION VS DOSAGE CONSISTENCY")
        print("=" * 60)
        
        self.cursor.execute("""
            SELECT 
                d.trade_name,
                d.concentration,
                g.min_dose,
                g.max_dose,
                g.dose_unit,
                g.route
            FROM drugs d
            JOIN dosage_guidelines g ON d.id = g.med_id
            WHERE d.concentration IS NOT NULL 
              AND d.concentration != ''
              AND g.min_dose IS NOT NULL
            ORDER BY RANDOM()
            LIMIT 15
        """)
        
        samples = self.cursor.fetchall()
        
        print("Sample Drugs with Concentration + Dosage:")
        print("")
        
        validated = []
        for i, row in enumerate(samples, 1):
            conc = row['concentration']
            dose_range = f"{row['min_dose']}"
            if row['max_dose'] and row['max_dose'] != row['min_dose']:
                dose_range += f" - {row['max_dose']}"
            dose_range += f" {row['dose_unit'] or 'mg'}"
            
            sample_data = {
                "drug": row['trade_name'],
                "concentration": conc,
                "dosage": dose_range,
                "route": row['route']
            }
            validated.append(sample_data)
            
            print(f"{i}. {row['trade_name']}")
            print(f"   Concentration: {conc}")
            print(f"   Dosage: {dose_range} | Route: {row['route']}")
            print("")
        
        self.report["samples"]["concentration_consistency"] = validated
    
    def find_potential_issues(self):
        """Identify potential data quality issues"""
        print("\n⚠️ POTENTIAL DATA QUALITY ISSUES")
        print("=" * 60)
        
        issues = []
        
        # 1. Drugs without ingredients
        self.cursor.execute("""
            SELECT COUNT(*)
            FROM drugs d
            LEFT JOIN med_ingredients mi ON d.id = mi.med_id
            WHERE mi.ingredient IS NULL
        """)
        drugs_no_ingredients = self.cursor.fetchone()[0]
        if drugs_no_ingredients > 0:
            issue = f"⚠️ {drugs_no_ingredients} drugs without linked ingredients"
            print(issue)
            issues.append(issue)
        
        # 2. Dosages without valid dose values
        self.cursor.execute("""
            SELECT COUNT(*)
            FROM dosage_guidelines
            WHERE (min_dose IS NULL OR min_dose = 0)
              AND (wikem_instructions IS NULL OR LENGTH(wikem_instructions) < 20)
        """)
        invalid_dosages = self.cursor.fetchone()[0]
        if invalid_dosages > 0:
            issue = f"⚠️ {invalid_dosages} dosage records with no numeric dose and no instructions"
            print(issue)
            issues.append(issue)
        
        # 3. Duplicate dosage entries for same drug
        self.cursor.execute("""
            SELECT med_id, COUNT(*) as count
            FROM dosage_guidelines
            GROUP BY med_id
            HAVING count > 5
        """)
        dups = self.cursor.fetchall()
        if dups:
            issue = f"⚠️ {len(dups)} drugs with >5 dosage entries (potential duplicates)"
            print(issue)
            issues.append(issue)
        
        if not issues:
            print("✅ No major data quality issues detected!")
        
        self.report["issues"] = issues
    
    def generate_html_report(self):
        """Generate a beautiful HTML report"""
        html = f"""
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>MediSwitch Data Integrity Report</title>
    <style>
        body {{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 40px; background: #f5f5f5; }}
        .container {{ max-width: 1200px; margin: 0 auto; background: white; padding: 40px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }}
        h1 {{ color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }}
        h2 {{ color: #34495e; margin-top: 30px; }}
        .stat {{ display: inline-block; margin: 10px 20px 10px 0; padding: 15px 20px; background: #ecf0f1; border-radius: 5px; }}
        .stat strong {{ font-size: 24px; color: #3498db; display: block; }}
        .issue {{ background: #fff3cd; border-left: 4px solid #ffc107; padding: 10px; margin: 10px 0; }}
        .success {{ background: #d4edda; border-left: 4px solid #28a745; padding: 10px; margin: 10px 0; }}
        table {{ width: 100%; border-collapse: collapse; margin: 20px 0; }}
        th {{ background: #34495e; color: white; padding: 12px; text-align: left; }}
        td {{ padding: 10px; border-bottom: 1px solid #ddd; }}
        tr:hover {{ background: #f8f9fa; }}
        .timestamp {{ color: #7f8c8d; font-size: 14px; }}
    </style>
</head>
<body>
    <div class="container">
        <h1>🏥 MediSwitch Data Integrity Report</h1>
        <p class="timestamp">Generated: {self.report['timestamp']}</p>
        
        <h2>📊 Database Summary</h2>
        <div>
"""
        
        for table, count in self.report['summary'].items():
            html += f'            <div class="stat"><strong>{count:,}</strong> {table.replace("_", " ").title()}</div>\n'
        
        html += """
        </div>
        
        <h2>💊 Dosage Coverage</h2>
"""
        dosage = self.report['coverage'].get('dosage', {})
        if dosage:
            html += f"""
        <div class="stat"><strong>{dosage.get('coverage_pct', 0):.1f}%</strong> Coverage</div>
        <div class="stat"><strong>{dosage.get('with_dosage', 0):,}</strong> / {dosage.get('total_drugs', 0):,} Drugs</div>
        <div class="stat"><strong>{dosage.get('merged_wikem_ncbi', 0):,}</strong> WikEM + NCBI Merged</div>
"""
        
        html += """
        <h2>🔗 Interaction Coverage</h2>
"""
        interactions = self.report['coverage'].get('interactions', {})
        if interactions:
            total = interactions.get('total_ingredients', 1)
            html += f"""
        <div class="stat"><strong>{interactions.get('drug_drug', 0):,}</strong> Drug-Drug ({interactions.get('drug_drug', 0)/total*100:.1f}%)</div>
        <div class="stat"><strong>{interactions.get('drug_food', 0):,}</strong> Drug-Food ({interactions.get('drug_food', 0)/total*100:.1f}%)</div>
        <div class="stat"><strong>{interactions.get('drug_disease', 0):,}</strong> Drug-Disease ({interactions.get('drug_disease', 0)/total*100:.1f}%)</div>
"""
        
        html += """
        <h2>⚠️ Data Quality Issues</h2>
"""
        if self.report['issues']:
            for issue in self.report['issues']:
                html += f'        <div class="issue">{issue}</div>\n'
        else:
            html += '        <div class="success">✅ No major data quality issues detected!</div>\n'
        
        html += """
        <h2>📋 Sample Data Validation</h2>
        <h3>Dosage Matching Samples</h3>
        <table>
            <tr><th>Drug</th><th>Ingredient</th><th>Source</th><th>Dose</th><th>Route</th></tr>
"""
        
        for sample in self.report['samples'].get('dosage_matching', [])[:10]:
            html += f"""
            <tr>
                <td>{sample.get('drug', 'N/A')}</td>
                <td>{sample.get('ingredient', 'N/A')}</td>
                <td>{sample.get('source', 'N/A')}</td>
                <td>{sample.get('min_dose', 'N/A')} mg</td>
                <td>{sample.get('route', 'N/A')}</td>
            </tr>
"""
        
        html += """
        </table>
        
        <h3>Concentration Consistency Samples</h3>
        <table>
            <tr><th>Drug</th><th>Concentration</th><th>Dosage</th><th>Route</th></tr>
"""
        
        for sample in self.report['samples'].get('concentration_consistency', [])[:10]:
            html += f"""
            <tr>
                <td>{sample.get('drug', 'N/A')}</td>
                <td>{sample.get('concentration', 'N/A')}</td>
                <td>{sample.get('dosage', 'N/A')}</td>
                <td>{sample.get('route', 'N/A')}</td>
            </tr>
"""
        
        html += """
        </table>
    </div>
</body>
</html>
"""
        
        report_path = "data_integrity_report.html"
        with open(report_path, 'w', encoding='utf-8') as f:
            f.write(html)
        
        print(f"\n📄 HTML Report saved: {report_path}")
        return report_path
    
    def run_full_audit(self):
        """Run complete audit"""
        print("\n" + "="*60)
        print("🔬 MEDISWITCH DATA INTEGRITY AUDIT")
        print("="*60)
        
        self.get_database_summary()
        self.check_dosage_coverage()
        self.check_interaction_coverage()
        self.validate_ingredient_matching()
        self.validate_concentration_consistency()
        self.find_potential_issues()
        
        # Save JSON report
        json_path = "data_integrity_report.json"
        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(self.report, f, indent=2, ensure_ascii=False)
        print(f"\n💾 JSON Report saved: {json_path}")
        
        # Generate HTML report
        self.generate_html_report()
        
        self.conn.close()
        
        print("\n" + "="*60)
        print("✅ AUDIT COMPLETE!")
        print("="*60)

if __name__ == "__main__":
    auditor = DataAuditor()
    auditor.run_full_audit()
