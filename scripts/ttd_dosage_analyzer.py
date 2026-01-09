#!/usr/bin/env python3
"""
TTD-IDRBLab Dosage Data Analyzer
==================================
يحلل ملفات TTD ويطابقها مع قاعدة البيانات الحالية عبر med_ingredients
لاستخراج معلومات الجرعات بدقة ودمجها في dosage_guidelines
"""

import sqlite3
import pandas as pd
import re
import json
from pathlib import Path
from typing import Dict, List, Tuple, Optional
from collections import defaultdict
import logging

# إعداد السجلات
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class TTDDosageAnalyzer:
    def __init__(self, db_path: str, ttd_dir: str):
        """
        تهيئة المحلل
        
        Args:
            db_path: مسار قاعدة البيانات المحلية (mediswitch.db)
            ttd_dir: مجلد ملفات TTD-IDRBLab
        """
        self.db_path = Path(db_path)
        self.ttd_dir = Path(ttd_dir)
        self.conn = None
        
        #خرائط البيانات
        self.ingredient_to_meds = defaultdict(list)  # ingredient -> [med_ids]
        self.ttd_drugs = {}  # ttd_id -> drug_info
        self.ttd_synonyms = defaultdict(list)  # ttd_id -> [synonyms]
        self.ttd_diseases = defaultdict(list)  # ttd_id -> [disease_info]
        
    def connect_db(self):
        """الاتصال بقاعدة البيانات"""
        self.conn = sqlite3.connect(str(self.db_path))
        self.conn.row_factory = sqlite3.Row
        logger.info(f"✅ Connected to database: {self.db_path}")
    
    def close_db(self):
        """إغلاق الاتصال"""
        if self.conn:
            self.conn.close()
            logger.info("✅ Database connection closed")
    
    def load_med_ingredients(self):
        """تحميل خريطة المكونات من med_ingredients"""
        cursor = self.conn.cursor()
        cursor.execute("""
            SELECT med_id, ingredient
            FROM med_ingredients
        """)
        
        count = 0
        for row in cursor.fetchall():
            ingredient = row['ingredient'].lower().strip()
            med_id = row['med_id']
            self.ingredient_to_meds[ingredient].append(med_id)
            count += 1
        
        logger.info(f"✅ Loaded {count} ingredient mappings for {len(self.ingredient_to_meds)} unique ingredients")
        
        # عرض عينة
        sample_ingredients = list(self.ingredient_to_meds.keys())[:5]
        for ing in sample_ingredients:
            logger.info(f"   📌 '{ing}' → {len(self.ingredient_to_meds[ing])} medicines")
    
    def normalize_ingredient(self, ingredient: str) -> str:
        """
        تطبيع أسماء المواد الفعالة (إزالة الأملاح، lowercase، trim)
        
        مثال: "Amoxicillin trihydrate" -> "amoxicillin"
        """
        # تحويل لحروف صغيرة
        normalized = ingredient.lower().strip()
        
        # إزالة الأملاح الشائعة
        salts_to_remove = [
            'hydrochloride', 'hydrobromide', 'sulfate', 'sulphate',
            'phosphate', 'citrate', 'maleate', 'tartrate', 'mesylate',
            'trihydrate', 'dihydrate', 'monohydrate', 'anhydrous',
            'sodium', 'potassium', 'calcium', 'magnesium'
        ]
        
        for salt in salts_to_remove:
            normalized = re.sub(r'\b' + salt + r'\b', '', normalized)
        
        # إزالة الفراغات الزائدة
        normalized = ' '.join(normalized.split())
        
        return normalized
    
    def parse_ttd_drug_file(self) -> int:
        """
        قراءة ملف P1-02-TTD_drug_download.txt (التنسيق: tab-delimited raw format)
        
        الهيكل:
        D00UZR  DRUG__ID        D00UZR
        D00UZR  TRADNAME        Ibrance
        D00UZR  DRUGTYPE        Small molecular drug
        ...
        """
        file_path = self.ttd_dir / "P1-02-TTD_drug_download.txt"
        logger.info(f"📖 Reading TTD drug file: {file_path}")
        
        current_drug_id = None
        current_drug = {}
        drug_count = 0
        
        with open(file_path, 'r', encoding='utf-8') as f:
            for line_num, line in enumerate(f, 1):
                line = line.strip()
                
                # تجاهل التعليقات والسطور الفارغة
                if not line or line.startswith('TTD') or line.startswith('Title') or line.startswith('---'):
                    continue
                
                # تقسيم السطر
                parts = line.split('\t', 2)
                if len(parts) < 3:
                    continue
                
                drug_id, field_name, value = parts
                
                # بداية دواء جديد
                if drug_id != current_drug_id:
                    # حفظ الدواء السابق
                    if current_drug_id and current_drug:
                        self.ttd_drugs[current_drug_id] = current_drug
                        drug_count += 1
                    
                    # بدء دواء جديد
                    current_drug_id = drug_id
                    current_drug = {'ttd_id': drug_id}
                
                # استخراج الحقول المهمة
                if field_name == 'TRADNAME':
                    current_drug['trade_name'] = value
                elif field_name == 'DRUGTYPE':
                    current_drug['drug_type'] = value
                elif field_name == 'THERCLAS':
                    current_drug['therapeutic_class'] = value
                elif field_name == 'HIGHSTAT':
                    current_drug['approval_status'] = value
        
        # حفظ آخر دواء
        if current_drug_id and current_drug:
            self.ttd_drugs[current_drug_id] = current_drug
            drug_count += 1
        
        logger.info(f"✅ Loaded {drug_count} drugs from TTD")
        
        # عرض عينة
        sample = list(self.ttd_drugs.items())[:3]
        for ttd_id, drug in sample:
            logger.info(f"   📌 {ttd_id}: {drug.get('trade_name', 'N/A')} - {drug.get('therapeutic_class', 'N/A')}")
        
        return drug_count
    
    def parse_ttd_synonyms_file(self) -> int:
        """
        قراءة ملف P1-04-Drug_synonyms.txt
        
        الهيكل:
        TTDDRID\tSynonym\tLanguage
        """
        file_path = self.ttd_dir / "P1-04-Drug_synonyms.txt"
        logger.info(f"📖 Reading TTD synonyms file: {file_path}")
        
        synonym_count = 0
        
        with open(file_path, 'r', encoding='utf-8') as f:
            for line_num, line in enumerate(f, 1):
                line = line.strip()
                
                # تجاهل التعليقات والسطور الفارغة
                if not line or line.startswith('TTD') or line.startswith('Title') or line.startswith('---'):
                    continue
                
                # تقسيم السطر
                parts = line.split('\t')
                if len(parts) < 2:
                    continue
                
                ttd_id = parts[0].strip()
                synonym = parts[1].strip() if len(parts) > 1 else ''
                
                if ttd_id and synonym:
                    self.ttd_synonyms[ttd_id].append(synonym)
                    synonym_count += 1
        
        logger.info(f"✅ Loaded {synonym_count} synonyms for {len(self.ttd_synonyms)} drugs")
        
        # عرض عينة
        sample = list(self.ttd_synonyms.items())[:3]
        for ttd_id, syns in sample:
            logger.info(f"   📌 {ttd_id}: {len(syns)} synonyms")
        
        return synonym_count
    
    def parse_ttd_diseases_file(self) -> int:
        """
        قراءة ملف P1-05-Drug_disease.txt
        
        الهيكل:
        TTDDRUAID\tDrug Name\tIndication\tDisease\tICD-11\tClinical status
        """
        file_path = self.ttd_dir / "P1-05-Drug_disease.txt"
        logger.info(f"📖 Reading TTD disease mapping file: {file_path}")
        
        disease_count = 0
        current_drug_id = None
        
        with open(file_path, 'r', encoding='utf-8') as f:
            for line_num, line in enumerate(f, 1):
                line = line.strip()
                
                # تجاهل التعليقات والسطور الفارغة
                if not line or line.startswith('TTD') or line.startswith('Title') or line.startswith('---') or line.startswith('Abbreviations'):
                    continue
                
                # حقل TTDDRUAID
                if line.startswith('TTDDRUAID'):
                    parts = line.split('\t', 1)
                    if len(parts) > 1:
                        current_drug_id = parts[1].strip()
                    continue
                
                # حقل DRUGNAME
                if line.startswith('DRUGNAME'):
                    continue
                
                # حقل INDICATI (يحتوي على الجرعات والأمراض)
                if line.startswith('INDICATI') and current_drug_id:
                    parts = line.split('\t', 1)
                    if len(parts) > 1:
                        indication_data = parts[1].strip()
                        
                        # تقسيم البيانات (Disease, ICD-11, Clinical status)
                        indication_parts = indication_data.split('\t')
                        if len(indication_parts) >= 2:
                            disease = indication_parts[0].strip()
                            icd_code = indication_parts[1].strip() if len(indication_parts) > 1 else ''
                            clinical_status = indication_parts[2].strip() if len(indication_parts) > 2 else ''
                            
                            self.ttd_diseases[current_drug_id].append({
                                'disease': disease,
                                'icd_code': icd_code,
                                'clinical_status': clinical_status
                            })
                            disease_count += 1
        
        logger.info(f"✅ Loaded {disease_count} disease indications for {len(self.ttd_diseases)} drugs")
        
        # عرض عينة
        sample = list(self.ttd_diseases.items())[:3]
        for ttd_id, diseases in sample:
            logger.info(f"   📌 {ttd_id}: {len(diseases)} indications")
            for d in diseases[:2]:
                logger.info(f"      - {d['disease']} ({d['icd_code']})")
        
        return disease_count
    
    def match_ttd_to_local_meds(self) -> Dict[str, List[int]]:
        """
        مطابقة أدوية TTD مع قاعدة البيانات المحلية عبر المكونات
        
        Returns:
            {ttd_id: [med_ids]}
        """
        logger.info("🔄 Matching TTD drugs with local medicines...")
        
        matches = defaultdict(list)
        matched_count = 0
        
        for ttd_id, drug_info in self.ttd_drugs.items():
            # جمع كل الأسماء الممكنة (trade name + synonyms)
            potential_names = [drug_info.get('trade_name', '')]
            potential_names.extend(self.ttd_synonyms.get(ttd_id, []))
            
            # البحث عن مطابقات
            for name in potential_names:
                if not name:
                    continue
                
                normalized_name = self.normalize_ingredient(name)
                
                # البحث في خريطة المكونات
                if normalized_name in self.ingredient_to_meds:
                    med_ids = self.ingredient_to_meds[normalized_name]
                    matches[ttd_id].extend(med_ids)
                    matched_count += 1
                    break  # إيقاف عند أول مطابقة
        
        logger.info(f"✅ Matched {len(matches)} TTD drugs with local medicines")
        logger.info(f"   Total local medicine connections: {matched_count}")
        
        # عرض عينة
        sample = list(matches.items())[:5]
        for ttd_id, med_ids in sample:
            drug_name = self.ttd_drugs[ttd_id].get('trade_name', ttd_id)
            logger.info(f"   📌 {drug_name} ({ttd_id}): {len(med_ids)} local medicines")
        
        return dict(matches)
    
    def analyze_concentration_column(self):
        """تحليل عمود concentration في meds.csv"""
        logger.info("🔍 Analyzing concentration column...")
        
        cursor = self.conn.cursor()
        cursor.execute("""
            SELECT id, trade_name, concentration, unit, dosage_form
            FROM drugs
            WHERE concentration IS NOT NULL AND concentration != ''
            LIMIT 100
        """)
        
        rows = cursor.fetchall()
        logger.info(f"📊 Sample of {len(rows)} medicines with concentration data:")
        
        for row in rows[:10]:
            logger.info(f"   {row['trade_name']}: {row['concentration']} {row['unit'] or ''} ({row['dosage_form'] or 'N/A'})")
    
    def generate_report(self, output_path: str = None):
        """إنشاء تقرير شامل بالنتائج"""
        if output_path is None:
            output_path = self.ttd_dir / "TTD_ANALYSIS_REPORT.md"
        
        report = []
        report.append("# TTD-IDRBLab Dosage Data Analysis Report")
        report.append(f"**Generated:** {pd.Timestamp.now()}")
        report.append("")
        
        # إحصائيات
        report.append("## 📊 Statistics")
        report.append(f"- **TTD Drugs Loaded:** {len(self.ttd_drugs)}")
        report.append(f"- **TTD Synonyms:** {sum(len(s) for s in self.ttd_synonyms.values())}")
        report.append(f"- **TTD Disease Indications:** {sum(len(d) for d in self.ttd_diseases.values())}")
        report.append(f"- **Local Ingredients:** {len(self.ingredient_to_meds)}")
        report.append("")
        
        # مطابقات
        matches = self.match_ttd_to_local_meds()
        report.append("## 🔗 Matching Results")
        report.append(f"- **Matched TTD Drugs:** {len(matches)}")
        report.append(f"- **Total Local Medicine Connections:** {sum(len(m) for m in matches.values())}")
        report.append("")
        
        # عينة من المطابقات
        report.append("### Sample Matches (Top 10)")
        report.append("| TTD ID | Drug Name | Local Medicines Count |")
        report.append("|--------|-----------|----------------------|")
        
        for ttd_id, med_ids in list(matches.items())[:10]:
            drug_name = self.ttd_drugs[ttd_id].get('trade_name', ttd_id)
            report.append(f"| {ttd_id} | {drug_name} | {len(med_ids)} |")
        
        report.append("")
        
        # كتابة التقرير
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write('\n'.join(report))
        
        logger.info(f"📄 Report generated: {output_path}")
        return output_path


def main():
    """الدالة الرئيسية"""
    # المسارات - استخدام قاعدة البيانات الصحيحة
    PROJECT_ROOT = Path('/home/adminlotfy/project')
    DB_PATH = PROJECT_ROOT / 'assets' / 'database' / 'mediswitch.db'
    TTD_DIR = PROJECT_ROOT / 'External_source' / 'TTD-IDRBLab'
    
    logger.info("🚀 Starting TTD-IDRBLab Dosage Data Analysis")
    logger.info(f"📂 Database Path: {DB_PATH}")
    logger.info(f"📂 TTD Directory: {TTD_DIR}")
    
    # إنشاء كائن المحلل
    analyzer = TTDDosageAnalyzer(str(DB_PATH), str(TTD_DIR))
    
    try:
        # 1. الاتصال بقاعدة البيانات
        analyzer.connect_db()
        
        # 2. تحميل med_ingredients
        analyzer.load_med_ingredients()
        
        # 3. قراءة ملفات TTD
        logger.info("")
        logger.info("=" * 80)
        logger.info("📖 Reading TTD-IDRBLab Files")
        logger.info("=" * 80)
        
        analyzer.parse_ttd_drug_file()
        analyzer.parse_ttd_synonyms_file()
        analyzer.parse_ttd_diseases_file()
        
        # 4. مطابقة البيانات
        logger.info("")
        logger.info("=" * 80)
        logger.info("🔗 Matching TTD Drugs with Local Database")
        logger.info("=" * 80)
        
        matches = analyzer.match_ttd_to_local_meds()
        
        # 5. إنشاء تقرير محدث
        logger.info("")
        logger.info("=" * 80)
        logger.info("📊 Generating Detailed Analysis Report")
        logger.info("=" * 80)
        
        # تقرير مخصص محسّن
        report_path = TTD_DIR / "TTD_ANALYSIS_REPORT.md"
        
        # جلب أسماء الأدوية المحلية للعرض
        cursor = analyzer.conn.cursor()
        
        with open(report_path, 'w', encoding='utf-8') as f:
            f.write("# TTD-IDRBLab Dosage Data Analysis Report\n")
            f.write(f"**Generated:** {pd.Timestamp.now()}\n")
            f.write(f"**Database:** `{DB_PATH}`\n\n")
            
            f.write("## 📊 Statistics\n\n")
            
            # إحصائيات من قاعدة البيانات
            total_meds = cursor.execute("SELECT COUNT(*) FROM drugs").fetchone()[0]
            total_ingredients = cursor.execute("SELECT COUNT(DISTINCT ingredient) FROM med_ingredients").fetchone()[0]
            total_dosages = cursor.execute("SELECT COUNT(*) FROM dosage_guidelines").fetchone()[0]
            
            f.write(f"- **Local Medicines (Database):** {total_meds:,}\n")
            f.write(f"- **Unique Active Ingredients:** {total_ingredients:,}\n")
            f.write(f"- **Existing Dosage Guidelines:** {total_dosages:,}\n")
            f.write(f"- **med_ingredients Records:** {len(analyzer.ingredient_to_meds):,}\n\n")
            
            f.write(f"- **TTD Drugs Loaded:** {len(analyzer.ttd_drugs):,}\n")
            f.write(f"- **TTD Synonyms:** {sum(len(s) for s in analyzer.ttd_synonyms.values()):,}\n")
            f.write(f"- **TTD Disease Indications:** {sum(len(d) for d in analyzer.ttd_diseases.values()):,}\n\n")
            
            f.write("## 🔗 Matching Results\n\n")
            f.write(f"- **Matched TTD Drugs:** {len(matches):,}\n")
            f.write(f"- **Total Local Medicine Connections:** {sum(len(m) for m in matches.values()):,}\n")
            f.write(f"- **Matching Rate:** {len(matches) / len(analyzer.ttd_drugs) * 100:.2f}%\n\n")
            
            if len(matches) > 0:
                f.write("### Sample Matches (Top 20)\n\n")
                f.write("| TTD ID | Drug Name | Therapeutic Class | Local Medicines Count | Sample Local Names |\n")
                f.write("|--------|-----------|-------------------|----------------------|--------------------|\n")
                
                for ttd_id, med_ids in list(matches.items())[:20]:
                    drug_info = analyzer.ttd_drugs[ttd_id]
                    drug_name = drug_info.get('trade_name', ttd_id)
                    therapeutic_class = drug_info.get('therapeutic_class', 'N/A')
                    
                    # الحصول على أسماء الأدوية المحلية
                    local_names = []
                    for med_id in med_ids[:3]:
                        result = cursor.execute(
                            "SELECT trade_name FROM drugs WHERE id = ?", (med_id,)
                        ).fetchone()
                        if result:
                            local_names.append(result[0])
                    
                    names_str = ', '.join(local_names)
                    if len(med_ids) > 3:
                        names_str += f" (+{len(med_ids) - 3} more)"
                    
                    f.write(f"| {ttd_id} | {drug_name} | {therapeutic_class} | {len(med_ids)} | {names_str} |\n")
                
                f.write("\n")
            else:
                f.write("⚠️ **No matches found.** This suggests nomenclature mismatch between TTD and local database.\n\n")
                f.write("**Recommended Next Steps:**\n")
                f.write("1. Implement ATC code matching\n")
                f.write("2. Use fuzzy string matching for drug names\n")
                f.write("3. Create manual mapping file for common drugs\n\n")
        
        logger.info(f"📄 Report generated: {report_path}")
        logger.info("")
        logger.info("=" * 80)
        logger.info("✅ Analysis Completed Successfully!")
        logger.info("=" * 80)
        logger.info(f"📊 Summary: {len(matches):,} TTD drugs matched with local database")
        logger.info(f"📊 Matching Rate: {len(matches) / len(analyzer.ttd_drugs) * 100:.2f}%")
        
    except Exception as e:
        logger.error(f"❌ Error during analysis: {e}", exc_info=True)
    finally:
        analyzer.close_db()




if __name__ == "__main__":
    main()

