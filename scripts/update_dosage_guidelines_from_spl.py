#!/usr/bin/env python3
"""
تحديث جدول dosage_guidelines في قاعدة البيانات بالبيانات الغنية المستخرجة من DailyMed SPL
الإصدار المحسّن - يملأ 40 ع

مود
"""
import gzip
import json
import sqlite3
import os
import re
import glob
from typing import Dict, Optional
from datetime import datetime

# المسارات
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPL_PARTS_DIR = os.path.join(BASE_DIR, 'production_data')
SPL_PATTERN = os.path.join(SPL_PARTS_DIR, 'spl_enriched_dosages_part*.jsonl.gz')
DB_PATH = 'temp_mediswitch_migration.db'  # استخدام القاعدة المحدثة

class EnhancedDosageExtractor:
    """استخراج شامل لمعلومات الجرعات والسلامة من نصوص SPL"""
    
    def __init__(self):
        # أنماط الجرعات المحسّنة - تدعم الأرقام بالفواصل
        # نمط شامل يدعم: 1,000 أو 1000 أو 1.5
        self.dose_pattern = re.compile(
            r'(\d{1,3}(?:,\d{3})*(?:\.\d+)?)\s*(mg|mcg|μg|g|ml|units?|iu|mEq)',
            re.IGNORECASE
        )
        self.range_pattern = re.compile(
            r'(\d{1,3}(?:,\d{3})*(?:\.\d+)?)\s*(?:-|to)\s*(\d{1,3}(?:,\d{3})*(?:\.\d+)?)\s*(mg|mcg|μg|g|ml|units?|iu)',
            re.IGNORECASE
        )
        
        # طريق الإعطاء
        self.route_patterns = {
            'Oral': r'\b(?:oral|orally|mouth|po|p\.o\.|swallow|tablet|capsule)\b',
            'Intravenous': r'\b(?:intravenous|iv|i\.v\.|infusion|intravenously)\b',
            'Intramuscular': r'\b(?:intramuscular|im|i\.m\.|intramuscularly)\b',
            'Subcutaneous': r'\b(?:subcutaneous|sc|s\.c\.|subq|subcutaneously)\b',
            'Topical': r'\b(?:topical|topically|apply|skin|cream|ointment|gel)\b',
            'Inhalation': r'\b(?:inhalation|inhale|inhaled|nebulizer|inhaler)\b',
            'Ophthalmic': r'\b(?:ophthalmic|eye|eyes|ocular|instill)\b',
            'Nasal': r'\b(?:nasal|nose|intranasal)\b',
'Rectal': r'\b(?:rectal|rectally|suppository)\b',
        }
        
        # الشكل الدوائي
        self.dosage_form_patterns = {
            'Tablet': r'\b(?:tablet|tab)s?\b',
            'Capsule': r'\b(?:capsule|cap)s?\b',
            'Solution': r'\b(?:solution|soln)\b',
            'Suspension': r'\b(?:suspension|susp)\b',
            'Injection': r'\b(?:injection|injectable)\b',
            'Cream': r'\b(?:cream)\b',
            'Ointment': r'\b(?:ointment)\b',
        }
        
        # التكرارات (بالساعات) - موسّعة
        self.frequency_map = {
            r'\b(?:once daily|q\.?d\.?|q24h|every 24 hours|once a day)\b': 24,
            r'\b(?:twice daily|b\.?i\.?d\.?|q12h|every 12 hours|2 times|twice)\s*(?:a day|daily|per day)?\b': 12,
            r'\b(?:three times daily|t\.?i\.?d\.?|q8h|every 8 hours|3 times)\s*(?:a day|daily|per day)?\b': 8,
            r'\b(?:four times daily|q\.?i\.?d\.?|q6h|every 6 hours|4 times)\s*(?:a day|daily|per day)?\b': 6,
            r'\b(?:every 4 hours|q4h|4 times daily)\b': 4,
            r'\b(?:5 times|five times)\s*(?:a day|daily|per day)\b': 4.8,  # تقريباً كل 5 ساعات
            r'\b(?:6 times|six times)\s*(?:a day|daily|per day)\b': 4,
            r'\b(?:every 3 hours|q3h)\b': 3,
            r'\b(?:every 2 hours|q2h)\b': 2,
        }
        
        # المدة
        self.duration_pattern = re.compile(r'\b(?:for|duration of|up to)\s*(\d+)\s*(days?|weeks?|months?)', re.IGNORECASE)
        
        # كلمات مفتاحية للفئات
        self.pediatric_keywords = re.compile(r'\b(?:pediatric|child|children|infant|neonatal|adolescent|newborn)\b', re.IGNORECASE)
        self.geriatric_keywords = re.compile(r'\b(?:geriatric|elderly|older adult|aged)\b', re.IGNORECASE)
        
        # القصور الكلوي/الكبدي
        self.renal_keywords = re.compile(r'\b(?:renal impairment|kidney|creatinine clearance|CrCl|ESRD|dialysis)\b', re.IGNORECASE)
        self.hepatic_keywords = re.compile(r'\b(?:hepatic impairment|liver|cirrhosis|Child-Pugh)\b', re.IGNORECASE)
        
        # الحمل والرضاعة
        self.pregnancy_pattern = re.compile(r'(?:pregnancy category|category)\s*([A-DX])', re.IGNORECASE)
        self.lactation_keywords = re.compile(r'\b(?:lactation|breastfeeding|nursing|breast milk)\b', re.IGNORECASE)
    
    def _clean_number(self, num_str: str) -> float:
        """تنظيف وتحويل الأرقام (إزالة الفواصل)"""
        try:
            return float(num_str.replace(',', ''))
        except (ValueError, AttributeError):
            return None
    
    def extract_route(self, text: str) -> Optional[str]:
        """استخراج طريق الإعطاء"""
        text_lower = text.lower()
        for route, pattern in self.route_patterns.items():
            if re.search(pattern, text_lower):
                return route
        return None
    
    def extract_dosage_form(self, text: str) -> Optional[str]:
        """استخراج الشكل الدوائي"""
        text_lower = text.lower()
        for form, pattern in self.dosage_form_patterns.items():
            if re.search(pattern, text_lower):
                return form
        return None
    
    def extract_full_dosage_info(self, record: Dict) -> Dict:
        """استخراج شامل لجميع معلومات الجرعة"""
        text = record.get('section_text', '')
        section_type = record.get('section_type', '')
        
        if not text or len(text.strip()) < 20:
            return {}
        
        text_lower = text.lower()
        result = {
            'extraction_date': datetime.now().isoformat(),
            'spl_version': None,  # يمكن استخراجه من البيانات الوصفية
        }
        
        # === معلومات الجرعة الأساسية ===
        # توسيع: استخراج من أقسام متعددة، ليس فقط dosage_and_administration
        dosage_sections = ['dosage_and_administration', 'how_supplied', 'medication_guide', 
                          'instructions_for_use', 'preparation_instructions']
        
        if section_type in dosage_sections or 'dosage' in text_lower or 'dose' in text_lower:
            # الجرعة الدنيا/القصوى
            range_match = self.range_pattern.search(text)
            if range_match:
                d1 = self._clean_number(range_match.group(1))
                d2 = self._clean_number(range_match.group(2))
                unit = range_match.group(3)
                if d1 and d2:
                    result['min_dose'] = min(d1, d2)
                    result['max_dose'] = max(d1, d2)
                    result['dose_unit'] = unit
            else:
                dose_matches = self.dose_pattern.findall(text)
                if dose_matches:
                    valid_doses = []
                    for num_str, unit in dose_matches:
                        dose_val = self._clean_number(num_str)
                        if dose_val and dose_val < 50000:  # تصفية القيم غير المعقولة
                            valid_doses.append((dose_val, unit))
                    
                    if valid_doses:
                        result['min_dose'] = min([d[0] for d in valid_doses])
                        result['dose_unit'] = valid_doses[0][1]
                        if len(valid_doses) > 1:
                            result['max_dose'] = max([d[0] for d in valid_doses])
            
            # طريق الإعطاء والشكل
            result['route'] = self.extract_route(text)
            result['dosage_form'] = self.extract_dosage_form(text)
            
            # التكرار
            for pattern, hours in self.frequency_map.items():
                if re.search(pattern, text_lower):
                    result['frequency'] = hours
                    break
            
            # المدة
            duration_match = self.duration_pattern.search(text)
            if duration_match:
                num = int(duration_match.group(1))
                unit = duration_match.group(2).lower()
                if 'week' in unit:
                    result['duration'] = num * 7
                elif 'month' in unit:
                    result['duration'] = num * 30
                else:
                    result['duration'] = num
            
            # الجرعة اليومية القصوى
            max_daily_pattern = re.search(
                r'maximum\s*(?:daily)?\s*(?:dose|dosage)?\s*(?:of)?\s*(\d{1,3}(?:,\d{3})*(?:\.\d+)?)\s*(mg|g)',
                text_lower
            )
            if max_daily_pattern:
                result['max_daily_dose'] = self._clean_number(max_daily_pattern.group(1))
            
            # الجرعة التحميلية
            if 'loading dose' in text_lower:
                loading_match = re.search(
                    r'loading dose\s*(?:of)?\s*(\d{1,3}(?:,\d{3})*(?:\.\d+)?)\s*(mg|g)',
                    text_lower
                )
                if loading_match:
                    result['loading_dose'] = self._clean_number(loading_match.group(1))
            
            # جرعة الصيانة
            if 'maintenance' in text_lower:
                maint_match = re.search(
                    r'maintenance\s*(?:dose)?\s*(?:of)?\s*(\d{1,3}(?:,\d{3})*(?:\.\d+)?)\s*(mg|g)',
                    text_lower
                )
                if maint_match:
                    result['maintenance_dose'] = self._clean_number(maint_match.group(1))
            
            # معلومات التدريج
            if 'titrat' in text_lower or 'increase' in text_lower or 'adjust' in text_lower:
                titration_text = text
                result['titration_info'] = re.sub(r'\s+', ' ', titration_text).strip()
            
            # التعليمات
            instructions = text.strip()
            result['instructions'] = re.sub(r'\s+', ' ', instructions)
        
        # === الفئات الخاصة ===
        result['is_pediatric'] = 1 if self.pediatric_keywords.search(text) else 0
        result['is_geriatric'] = 1 if self.geriatric_keywords.search(text) else 0
        
        # القصور الكلوي
        if self.renal_keywords.search(text):
            renal_section = text
            result['renal_adjustment'] = re.sub(r'\s+', ' ', renal_section).strip()
        
        # القصور الكبدي
        if self.hepatic_keywords.search(text):
            hepatic_section = text
            result['hepatic_adjustment'] = re.sub(r'\s+', ' ', hepatic_section).strip()
        
        # الحمل
        preg_match = self.pregnancy_pattern.search(text)
        if preg_match:
            result['pregnancy_category'] = preg_match.group(1).upper()
        
        # الرضاعة
        if self.lactation_keywords.search(text):
            lactation_section = text
            result['lactation_info'] = re.sub(r'\s+', ' ', lactation_section).strip()
        
        # === معلومات السلامة ===
        # استخراج من النص بغض النظر عن section_type (لأن المعلومات قد تكون في أقسام مختلفة)
        if (section_type == 'contraindications') or ('contraindication' in text_lower and len(text) > 50):
            result['contraindications'] = text.strip()
        
        if (section_type == 'warnings') or ('warning' in text_lower and len(text) > 50):
            result['warnings'] = text.strip()
            # البحث عن تحذير الصندوق الأسود
            if 'boxed warning' in text_lower or 'black box' in text_lower:
                result['black_box_warning'] = text.strip()
        
        if (section_type == 'precautions') or ('precaution' in text_lower and len(text) > 50):
            result['precautions'] = text.strip()
        
        if (section_type == 'adverse_reactions') or ('adverse reaction' in text_lower or 'side effect' in text_lower):
            if len(text) > 50 or section_type == 'adverse_reactions':
                result['adverse_reactions'] = text.strip()
        
        if (section_type == 'overdosage') or ('overdosage' in text_lower or 'overdose' in text_lower):
            if len(text) > 50 or section_type == 'overdosage':
                result['overdose_management'] = text.strip()
        
        # === معلومات الفعالية ===
        if section_type == 'indications' or 'indication' in text_lower:
            result['indication'] = text.strip()
        
        if 'mechanism of action' in text_lower:
            moa_section = text
            result['mechanism_of_action'] = re.sub(r'\s+', ' ', moa_section).strip()
        
        # === معلومات إضافية ===
        if 'drug interaction' in text_lower:
            result['drug_interactions_summary'] = text.strip()
        
        if 'monitor' in text_lower:
            monitor_section = text
            result['monitoring_requirements'] = re.sub(r'\s+', ' ', monitor_section).strip()
        
        if 'storage' in text_lower or 'store' in text_lower:
            storage_match = re.search(r'(?:store|storage).*?(?:\.|$)', text_lower, re.DOTALL)
            if storage_match:
                result['storage_conditions'] = storage_match.group(0).strip()
        
        # الفئات الخاصة (ملخص)
        special_pops = []
        if result.get('is_pediatric'):
            special_pops.append('Pediatric')
        if result.get('is_geriatric'):
            special_pops.append('Geriatric')
        if result.get('renal_adjustment'):
            special_pops.append('Renal Impairment')
        if result.get('hepatic_adjustment'):
            special_pops. append('Hepatic Impairment')
        if result.get('pregnancy_category'):
            special_pops.append(f"Pregnancy Cat. {result['pregnancy_category']}")
        if special_pops:
            result['special_populations'] = ', '.join(special_pops)
        
        # === حساب الثقة والاكتمال ===
        non_null_fields = sum(1 for v in result.values() if v is not None and v != '')
        total_fields = 35  # عدد الحقول المحتملة
        result['data_completeness'] = min(1.0, non_null_fields / total_fields)
        
        # درجة الثقة بناءً على نوع القسم ووجود البيانات الأساسية
        confidence = 0.5
        if section_type in ['dosage_and_administration', 'how_supplied']:
            confidence += 0.3
        if result.get('min_dose') or result.get('max_dose'):
            confidence += 0.2
        result['confidence_score'] = min(1.0, confidence)
        
        # تحديد condition
        result['condition'] = section_type or 'General'
        
        return result

class DataValidator:
    """التحقق من جودة البيانات قبل الإدراج"""
    
    @staticmethod
    def is_text_complete(text: str, min_length: int = 50) -> bool:
        """التحقق من أن النص كامل وليس مقطوعاً"""
        if not text or len(text) < min_length:
            return False
        
        # التحقق من عدم انتهاء النص بشكل مفاجئ
        truncated_patterns = [
            r'\.\.\.$',  # ينتهي بـ ...
            r'[a-z]$',   # ينتهي بحرف صغير بدون نقطة
            r'\s[A-Z][a-z]{1,3}$',  # ينتهي بكلمة قصيرة غير مكتملة
        ]
        
        for pattern in truncated_patterns:
            if re.search(pattern, text.strip()):
                return False
        
        return True
    
    @staticmethod
    def is_dose_reasonable(dose: float, unit: str) -> bool:
        """التحقق من منطقية الجرعة"""
        if dose <= 0:
            return False
        
        # حدود معقولة حسب الوحدة
        limits = {
            'mg': (0.001, 50000),
            'mcg': (0.001, 10000),
            'g': (0.001, 100),
            'ml': (0.001, 5000),
            'units': (0.001, 100000),
            'iu': (0.001, 1000000),
        }
        
        unit_lower = unit.lower() if unit else 'mg'
        min_limit, max_limit = limits.get(unit_lower, (0, 100000))
        
        return min_limit <= dose <= max_limit
    
    @staticmethod
    def validate_record(dosage_data: Dict) -> tuple:
        """
        التحقق الشامل من السجل - معايير ليبرالية للحصول على أقصى تغطية
        Returns: (is_valid: bool, reason: str)
        """
        # قائمة موسعة من الحقول المفيدة
        useful_fields = [
            'min_dose', 'max_dose', 'dose_unit', 'route', 'dosage_form',
            'frequency', 'duration', 'instructions', 'indication',
            'warnings', 'contraindications', 'precautions', 'adverse_reactions',
            'black_box_warning', 'overdose_management', 'renal_adjustment',
            'hepatic_adjustment', 'pregnancy_category', 'lactation_info',
            'drug_interactions_summary', 'monitoring_requirements',
            'storage_conditions', 'titration_info', 'max_daily_dose',
            'loading_dose', 'maintenance_dose', 'mechanism_of_action',
            'therapeutic_class', 'special_populations'
        ]
        
        # التحقق من وجود أي معلومة مفيدة
        for field in useful_fields:
            value = dosage_data.get(field)
            if value is not None and value != '':
                # للنصوص: على الأقل 20 حرف
                if isinstance(value, str) and len(value.strip()) >= 20:
                    return True, "Valid"
                # للأرقام: أي قيمة صحيحة
                elif not isinstance(value, str):
                    return True, "Valid"
        
        return False, "No meaningful data"

def load_drug_concentrations(db_path: str) -> Dict[int, str]:
    """تحميل التركيزات من جدول drugs"""
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    concentrations = {}
    
    try:
        cursor.execute("SELECT id, concentration FROM drugs WHERE concentration IS NOT NULL")
        for med_id, concentration in cursor.fetchall():
            concentrations[med_id] = concentration
        
        print(f"✅ تم تحميل {len(concentrations):,} تركيز من جدول drugs")
    except sqlite3.Error as e:
        print(f"⚠️ خطأ في تحميل التركيزات: {e}")
    finally:
        conn.close()
    
    return concentrations

def update_database_enhanced():
    """تحديث قاعدة البيانات بالبيانات الغنية"""
    
    spl_files = sorted(glob.glob(SPL_PATTERN))
    
    if not spl_files:
        print(f"❌ لم يتم العثور على ملفات SPL")
        return
    
    print(f"📂 تم العثور على {len(spl_files)} ملف")
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # تحميل التركيزات من جدول drugs
    print("\n📊 تحميل البيانات المساعدة...")
    drug_concentrations = load_drug_concentrations(DB_PATH)
    
    extractor = EnhancedDosageExtractor()
    validator = DataValidator()
    
    total_records = 0
    inserted_count = 0
    skipped_count = 0
    validation_failures = {}  # تتبع أسباب الفشل
    
    print("\n🔄 بدء المعالجة...")
    
    for i, spl_file in enumerate(spl_files, 1):
        filename = os.path.basename(spl_file)
        print(f"\n[{i}/{len(spl_files)}] {filename}")
        
        file_inserted = 0
        
        try:
            with gzip.open(spl_file, 'rt', encoding='utf-8') as f:
                for line in f:
                    if not line.strip():
                        continue
                    
                    try:
                        record = json.loads(line)
                        total_records += 1
                        
                        med_id = record.get('med_id')
                        if not med_id:
                            skipped_count += 1
                            continue
                        
                        # استخراج كامل
                        dosage_data = extractor.extract_full_dosage_info(record)
                        
                        if not dosage_data:
                            skipped_count += 1
                            continue
                        
                        # التحقق من صحة البيانات
                        is_valid, reason = validator.validate_record(dosage_data)
                        if not is_valid:
                            skipped_count += 1
                            # تتبع أسباب الفشل
                            validation_failures[reason] = validation_failures.get(reason, 0) + 1
                            continue
                        
                        # ربط التركيز من جدول drugs
                        concentration = drug_concentrations.get(med_id)
                        
                        # إدراج في القاعدة
                        cursor.execute("""
                            INSERT INTO dosage_guidelines 
                            (med_id, dailymed_setid, min_dose, max_dose, frequency, duration, 
                             instructions, condition, source, is_pediatric,
                             dose_unit, route, dosage_form, titration_info, max_daily_dose,
                             loading_dose, maintenance_dose, is_geriatric, renal_adjustment, 
                             hepatic_adjustment, pregnancy_category, lactation_info,
                             contraindications, warnings, precautions, adverse_reactions, 
                             black_box_warning, overdose_management, indication, 
                             mechanism_of_action, therapeutic_class, drug_interactions_summary,
                             monitoring_requirements, storage_conditions, special_populations,
                             extraction_date, spl_version, confidence_score, data_completeness)
                            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
                                    ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                        """, (
                            med_id,
                            record.get('spl_set_id'),
                            dosage_data.get('min_dose'),
                            dosage_data.get('max_dose'),
                            dosage_data.get('frequency'),
                            dosage_data.get('duration'),
                            dosage_data.get('instructions'),
                            dosage_data.get('condition'),
                            'DailyMed SPL Enhanced',
                            dosage_data.get('is_pediatric'),
                            dosage_data.get('dose_unit'),
                            dosage_data.get('route'),
                            dosage_data.get('dosage_form'),
                            dosage_data.get('titration_info'),
                            dosage_data.get('max_daily_dose'),
                            dosage_data.get('loading_dose'),
                            dosage_data.get('maintenance_dose'),
                            dosage_data.get('is_geriatric'),
                            dosage_data.get('renal_adjustment'),
                            dosage_data.get('hepatic_adjustment'),
                            dosage_data.get('pregnancy_category'),
                            dosage_data.get('lactation_info'),
                            dosage_data.get('contraindications'),
                            dosage_data.get('warnings'),
                            dosage_data.get('precautions'),
                            dosage_data.get('adverse_reactions'),
                            dosage_data.get('black_box_warning'),
                            dosage_data.get('overdose_management'),
                            dosage_data.get('indication'),
                            dosage_data.get('mechanism_of_action'),
                            dosage_data.get('therapeutic_class'),
                            dosage_data.get('drug_interactions_summary'),
                            dosage_data.get('monitoring_requirements'),
                            dosage_data.get('storage_conditions'),
                            dosage_data.get('special_populations'),
                            dosage_data.get('extraction_date'),
                            dosage_data.get('spl_version'),
                            dosage_data.get('confidence_score'),
                            dosage_data.get('data_completeness'),
                        ))
                        
                        inserted_count += 1
                        file_inserted += 1
                        
                    except (json.JSONDecodeError, sqlite3.Error):
                        continue
            
            conn.commit()
            print(f"  ✅ {file_inserted:,} سجل")
            
        except Exception as e:
            print(f"  ❌ خطأ: {e}")
            continue
    
    conn.close()
    
    print("\n" + "="*80)
    print("📊 ملخص التحديث:")
    print("="*80)
    print(f"  📄 السجلات المعالجة: {total_records:,}")
    print(f"  ✅ السجلات المُدرجة: {inserted_count:,}")
    print(f"  ⏭️  السجلات المتجاوزة: {skipped_count:,}")
    print(f"  📈 معدل النجاح: {(inserted_count/total_records*100) if total_records > 0 else 0:.1f}%")
    print("="*80)
    
    return inserted_count

def main():
    print("="*80)
    print("تحديث قاعدة بيانات الجرعات - الإصدار المحسّن الشامل")
    print("="*80)
    
    if not os.path.exists(DB_PATH):
        print(f"❌ قاعدة البيانات غير موجودة: {DB_PATH}")
        print("⚠️  يرجى تشغيل migrate_dosage_schema.py أولاً")
        return
    
    inserted = update_database_enhanced()
    
    if inserted > 0:
        print(f"\n✅ تم التحديث بنجاح!")
        print(f"📂 قاعدة البيانات: {DB_PATH}")
        print(f"\n💡 الخطوة التالية: نسخ/تقسيم هذا الملف إلى assets/database/")
    else:
        print(f"\n⚠️ لم يتم إدراج أي سجلات")
    
    print("\n✅ انتهى")

if __name__ == "__main__":
    main()
