#!/usr/bin/env python3
"""
TTD-IDRBLab Complete CSV Generator - FINAL VERSION
==================================================
يقرأ جميع ملفات TTD بدقة ويدمجها في CSV شامل
"""

import pandas as pd
from pathlib import Path
from collections import defaultdict
import logging

logging.basicConfig(level=logging.INFO, format='%(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


class TTDCompleteGenerator:
    def __init__(self, ttd_dir):
        self.ttd_dir = Path(ttd_dir)
        self.drugs = {}
        self.synonyms = defaultdict(list)
        self.diseases = defaultdict(list)
        self.targets = defaultdict(list)
    
    def parse_p1_02(self):
        """P1-02: Drug Information"""
        file = self.ttd_dir / "P1-02-TTD_drug_download.txt"
        logger.info(f"📖 P1-02: {file.name}")
        
        current_id = None
        skip_header = True
        
        for line in open(file, encoding='utf-8'):
            line = line.strip()
            
            # Skip header section
            if '____' in line or'---' in line:
                skip_header = False
                continue
            if skip_header or not line:
                continue
            
            parts = line.split('\t', 2)
            if len(parts) < 3:
                continue
            
            drug_id, field, value = parts
            
            if drug_id != current_id:
                current_id = drug_id
                if drug_id not in self.drugs:
                    self.drugs[drug_id] = {'drug_id': drug_id}
            
            field_map = {
                'TRADNAME': 'trade_name', 'DRUGCOMP': 'company',
                'THERCLAS': 'therapeutic_class', 'DRUGTYPE': 'drug_type',
                'HIGHSTAT': 'approval_status', 'DRUGINCH': 'inchi',
                'DRUGINKE': 'inchikey', 'DRUGSMIL': 'smiles'
            }
            
            if field in field_map:
                self.drugs[drug_id][field_map[field]] = value
        
        logger.info(f"   ✅ {len(self.drugs):,} drugs")
        return len(self.drugs)
    
    def parse_p1_04(self):
        """P1-04: Synonyms"""
        file = self.ttd_dir / "P1-04-Drug_synonyms.txt"
        logger.info(f"📖 P1-04: {file.name}")
        
        count, skip_header = 0, True
        for line in open(file, encoding='utf-8'):
            line = line.strip()
            
            if '---' in line:
                skip_header = False
                continue
            if skip_header or not line:
                continue
            
            parts = line.split('\t')
            if len(parts) >= 2:
                drug_id, synonym = parts[0].strip(), parts[1].strip()
                if drug_id and synonym and not synonym.startswith('DRUGNAME'):
                    self.synonyms[drug_id].append(synonym)
                    count += 1
        
        logger.info(f"   ✅ {count:,} synonyms for {len(self.synonyms):,} drugs")
        return count
    
    def parse_p1_05(self):
        """P1-05: Drug-Disease Mapping - FIXED PARSER"""
        file = self.ttd_dir / "P1-05-Drug_disease.txt"
        logger.info(f"📖 P1-05: {file.name}")
        
        count, current_id, skip_header = 0, None, True
        
        for line in open(file, encoding='utf-8'):
            line = line.rstrip()
            
            if '---' in line:
                skip_header = False
                continue
            if skip_header or not line:
                continue
            
            # Read TTDDRUAID line
            if line.startswith('TTDDRUAID'):
                parts = line.split('\t')
                current_id = parts[1].strip() if len(parts) >= 2 else None
                continue
            
            # Skip DRUGNAME line
            if line.startswith('DRUGNAME'):
                continue
            
            # Read INDICATI line
            if line.startswith('INDICATI') and current_id:
                parts = line.split('\t')
                
                # تخطي الرأس الذي يحتوي على "Indication" أو "Disease entry"
                if len(parts) > 1 and ('Indication' in parts[1] or 'Disease entry' in parts[2] if len(parts)>2 else False):
                    continue
                
                # التنسيق: INDICATI \t Disease \t ICD \t Status
                if len(parts) >= 2:
                    disease = parts[1].strip()
                    icd = parts[2].replace('ICD-11:', '').strip() if len(parts) >= 3 else ''
                    status = parts[3].strip() if len(parts) >= 4 else ''
                    
                    if disease:
                        self.diseases[current_id].append({
                            'disease': disease, 'icd': icd, 'status': status
                        })
                        count += 1
        
        logger.info(f"   ✅ {count:,} diseases for {len(self.diseases):,} drugs")
        
        # Sample
        for drug_id in list(self.diseases.keys())[:2]:
            logger.info(f"      📌 {drug_id}: {len(self.diseases[drug_id])} diseases")
        
        return count
    
    def parse_p1_07(self):
        """P1-07: Drug-Target Mapping (Excel)"""
        file = self.ttd_dir / "P1-07-Drug-TargetMapping.xlsx"
        
        if not file.exists():
            logger.warning(f"⚠️  P1-07 not found")
            return 0
        
        logger.info(f"📖 P1-07: {file.name}")
        
        try:
            df = pd.read_excel(file, engine='openpyxl')
            
            for _, row in df.iterrows():
                drug_id = str(row['DrugID']).strip()
                if drug_id and drug_id != 'nan':
                    self.targets[drug_id].append({
                        'target_id': str(row.get('TargetID', '')),
                        'moa': str(row.get('MOA', '')),
                        'status': str(row.get('Highest_status', ''))
                    })
            
            logger.info(f"   ✅ {len(df):,} targets for {len(self.targets):,} drugs")
            return len(df)
            
        except Exception as e:
            logger.warning(f"   ⚠️  Error: {e}")
            return 0
    
    def generate_csv(self, output=None):
        """Generate Final CSV"""
        if not output:
            output = self.ttd_dir / "TTD_Complete_Merged.csv"
        
        logger.info("🔄 Merging all data into CSV...")
        
        rows = []
        for drug_id, info in self.drugs.items():
            row = {
                'Drug_ID': drug_id,
                'Trade_Name': info.get('trade_name', ''),
                'Company': info.get('company', ''),
                'Therapeutic_Class': info.get('therapeutic_class', ''),
                'Drug_Type': info.get('drug_type', ''),
                'Approval_Status': info.get('approval_status', ''),
            }
            
            # Synonyms
            syns = self.synonyms.get(drug_id, [])
            row['Synonyms'] = '; '.join(syns[:20]) if syns else ''
            row['Synonyms_Count'] = len(syns)
            
            # Diseases
            diseases = self.diseases.get(drug_id, [])
            if diseases:
                row['Primary_Disease'] = diseases[0]['disease']
                row['Primary_ICD_Code'] = diseases[0]['icd']
                row['Primary_Clinical_Status'] = diseases[0]['status']
                row['All_Diseases'] = '; '.join([d['disease'] for d in diseases])
            else:
                row.update({'Primary_Disease': '', 'Primary_ICD_Code': '', 
                           'Primary_Clinical_Status': '', 'All_Diseases': ''})
            row['Diseases_Count'] = len(diseases)
            
            # Targets
            targets = self.targets.get(drug_id, [])
            if targets:
                row['Primary_Target'] = targets[0]['target_id']
                row['Primary_MOA'] = targets[0]['moa']
            else:
                row['Primary_Target'] = row['Primary_MOA'] = ''
            row['Targets_Count'] = len(targets)
            
            # Chemistry
            row.update({
                'InChI': info.get('inchi', ''),
                'InChIKey': info.get('inchikey', ''),
                'SMILES': info.get('smiles', '')
            })
            
            rows.append(row)
        
        df = pd.DataFrame(rows)
        df.to_csv(output, index=False, encoding='utf-8-sig')
        
        logger.info(f"\n{'='*80}")
        logger.info(f"✅ CSV Created: {output}")
        logger.info(f"📊 Statistics:")
        logger.info(f"   - Total Drugs: {len(df):,}")
        logger.info(f"   - With Synonyms: {(df['Synonyms_Count'] > 0).sum():,}")
        logger.info(f"   - With Diseases: {(df['Diseases_Count'] > 0).sum():,}")
        logger.info(f"   - With Targets: {(df['Targets_Count'] > 0).sum():,}")
        logger.info(f"   - Approved: {(df['Approval_Status'] == 'Approved').sum():,}")
        logger.info(f"{'='*80}\n")
        
        return output


def main():
    TTD_DIR = '/home/adminlotfy/project/External_source/TTD-IDRBLab'
    
    print("\n" + "="*80)
    print("TTD-IDRBLab Complete CSV Generator")
    print("="*80 + "\n")
    
    gen = TTDCompleteGenerator(TTD_DIR)
    
    try:
        gen.parse_p1_02()
        gen.parse_p1_04()
        gen.parse_p1_05()
        gen.parse_p1_07()
        
        output = gen.generate_csv()
        
        # Display sample
        print("📋 Sample Data (First 10 rows):\n")
        df = pd.read_csv(output)
        print(df[['Drug_ID', 'Trade_Name', 'Therapeutic_Class', 'Synonyms_Count', 
                  'Diseases_Count', 'Targets_Count', 'Approval_Status']].head(10).to_string(index=False))
        
        print(f"\n✅ Complete! File saved at:\n   {output}\n")
        
    except Exception as e:
        logger.error(f"❌ Error: {e}", exc_info=True)


if __name__ == "__main__":
    main()
