import pandas as pd
import os
import re
from datetime import datetime

# Translation dictionaries
MAIN_CATEGORIES = {
    'oncology': 'علاج الأورام',
    'diabetes_care': 'العناية بمرضى السكري',
    'skin_care': 'العناية بالبشرة',
    'eye_care': 'العناية بالعيون',
    'ear_care': 'العناية بالأذن',
    'pain_management': 'مسكنات الألم',
    'anesthetics': 'التخدير',
    'anti_inflammatory': 'مضادات الالتهاب',
    'antihistamine': 'مضادات الهيستامين',
    'anti_infective': 'مضادات العدوى',
    'vitamins': 'الفيتامينات',
    'supplements': 'المكملات الغذائية',
    'probiotics': 'البروبيوتيك',
    'respiratory': 'الجهاز التنفسي',
    'digestive': 'الجهاز الهضمي',
    'cardiovascular': 'القلب والأوعية الدموية',
    'neurological': 'الجهاز العصبي',
    'urology': 'المسالك البولية',
    'soothing': 'مهدئات',
    'cosmetics': 'مستحضرات التجميل',
    'personal_care': 'العناية الشخصية',
    'medical_supplies': 'مستلزمات طبية',
    'hormonal': 'الهرمونات',
    'hematology': 'أمراض الدم',
    'musculoskeletal': 'الجهاز العضلي الهيكلي',
    'immunology': 'المناعة',
    'reproductive_health': 'الصحة الإنجابية',
    'herbal_natural': 'أعشاب ومواد طبيعية',
    'baby_care': 'العناية بالطفل',
    'medical_devices': 'أجهزة طبية',
    'diagnostics': 'التشخيص',
    'other': 'أخرى' # Fallback category
}

# Translations for specific categories (expand as needed)
CATEGORY_TRANSLATIONS = {
    # Add specific category translations here if needed
}

# Translations for dosage forms
DOSAGE_FORM_TRANSLATIONS = {
    'tablets': 'أقراص',
    'capsules': 'كبسولات',
    'syrup': 'شراب',
    'suspension': 'معلق',
    'injection': 'حقن',
    'ampoules': 'أمبولات',
    'ampoule': 'أمبولة', # Added translation
    'vial': 'فيال',
    'cream': 'كريم',
    'ointment': 'مرهم',
    'gel': 'جل',
    'drops': 'نقط',
    'eye_drops': 'نقط للعين',
    'eye_ointment': 'مرهم للعين', # Added translation
    'ear_drops': 'نقط للأذن',
    'effervescent': 'فوار', # Added translation
    'nasal_spray': 'بخاخ للأنف',
    'inhaler': 'جهاز استنشاق',
    'suppositories': 'لبوس',
    'suppository': 'لبوسة', # Added translation (singular)
    'powder': 'بودرة',
    'sachets': 'أكياس',
    'lozenges': 'أقراص استحلاب',
    'shampoo': 'شامبو',
    'lotion': 'لوشن',
    'solution': 'محلول',
    'spray': 'بخاخ',
    'patch': 'لصقة',
    'oral_gel': 'جل فموي',
    'oral_drops': 'نقط بالفم',
    'oral_suspension': 'معلق فموي',
    'ointment': 'مرهم', # Added translation (duplicate of existing, ensure correct placement)
    'effervescent_tablets': 'أقراص فوارة',
    'chewable_tablets': 'أقراص للمضغ',
    'soft_gelatin_capsules': 'كبسولات جيلاتينية رخوة',
    'hard_gelatin_capsules': 'كبسولات جيلاتينية صلبة',
    'hair_oil': 'زيت شعر', # Added translation
    'vaginal_suppositories': 'لبوس مهبلي',
    'vaginal_cream': 'كريم مهبلي',
    'vaginal_gel': 'جل مهبلي',
    'vaginal_douche': 'دش مهبلي', # Added translation
    'enema': 'حقنة شرجية',
    'mouthwash': 'غسول فم',
    'toothpaste': 'معجون أسنان',
    'soap': 'صابون',
    'syrup_for_oral_suspension': 'شراب لعمل معلق فموي',
    'powder_for_oral_suspension': 'بودرة لعمل معلق فموي',
    'syrup_for_oral_solution': 'شراب لعمل محلول فموي',
    'powder_for_oral_solution': 'بودرة لعمل محلول فموي',
    'intravenous_infusion': 'تسريب وريدي',
    'subcutaneous_injection': 'حقن تحت الجلد',
    'intramuscular_injection': 'حقن عضلي',
    'intra-articular_injection': 'حقن داخل المفصل',
    'topical_solution': 'محلول موضعي',
    'topical_spray': 'بخاخ موضعي',
    'topical_gel': 'جل موضعي',
    'topical_cream': 'كريم موضعي',
    'topical_ointment': 'مرهم موضعي',
    'transdermal_patch': 'لصقة عبر الجلد',
    'film-coated_tablets': 'أقراص مغلفة',
    'extended-release_tablets': 'أقراص ممتدة المفعول',
    'delayed-release_capsules': 'كبسولات مؤجلة المفعول',
    'oral_powder': 'بودرة فموية',
    'oral_liquid': 'سائل فموي',
    'inhalation_powder': 'بودرة استنشاق',
    'inhalation_solution': 'محلول استنشاق',
    'rectal_suppositories': 'لبوس شرجي',
    'rectal_ointment': 'مرهم شرجي',
    'rectal_foam': 'رغوة شرجية',
    'vaginal_tablets': 'أقراص مهبلية',
    'vaginal_ring': 'حلقة مهبلية',
    'intrauterine_device': 'لولب رحمي',
    'implant': 'زرعة',
    'concentrate_for_solution_for_infusion': 'مركز لمحلول التسريب',
    'lyophilized_powder_for_injection': 'بودرة مجففة بالتجميد للحقن',
    'pre-filled_syringe': 'حقنة معبأة مسبقًا',
    'cartridge': 'خرطوشة',
    'emulsion_for_injection': 'مستحلب للحقن',
    'foam': 'رغوة',
    'facial_wash': 'غسول وجه', # Added translation
    'medicated_shampoo': 'شامبو طبي',
    'medicated_nail_lacquer': 'طلاء أظافر طبي',
    'gargle': 'غرغرة',
    'chewing_gum': 'لبان',
    'oral_paste': 'معجون فموي',
    'dental_gel': 'جل أسنان',
    'orodispersible_tablets': 'أقراص تذوب في الفم',
    'sublingual_tablets': 'أقراص تحت اللسان',
    'buccal_tablets': 'أقراص شدقية',
    'bottle': 'زجاجة', # Added translation
    'nasal_drops': 'نقط للأنف',
    'nasal_ointment': 'مرهم للأنف',
    'otic_solution': 'محلول للأذن',
    'otic_suspension': 'معلق للأذن',
    'otic_spray': 'بخاخ للأذن',
    'paint': 'دهان', # Added translation
    'ophthalmic_solution': 'محلول للعين',
    'ophthalmic_suspension': 'معلق للعين',
    'ophthalmic_ointment': 'مرهم للعين',
    'ophthalmic_gel': 'جل للعين',
    'contact_lens_solution': 'محلول عدسات لاصقة',
    'irrigation_solution': 'محلول ري',
    'dialysis_solution': 'محلول غسيل كلوي',
    'dressing': 'ضمادة',
    'bandage': 'رباط',
    'gauze': 'شاش',
    'swab': 'مسحة',
    'test_strip': 'شريط اختبار',
    'lancet': 'مشرط وخز',
    'syringe': 'حقنة',
    'tablet': 'قرص', # Added translation (singular)
    'needle': 'إبرة',
    'catheter': 'قسطرة',
    'stent': 'دعامة',
    'infusion_set': 'جهاز تسريب',
    'blood_bag': 'كيس دم',
    'urine_bag': 'كيس بول',
    'ostomy_bag': 'كيس فغرة',
    'condom': 'واقي ذكري',
    'pessary': 'فرزجة',
    'pen': 'قلم', # Added translation
    'piece': 'قطعة', # Added translation
    'tampon': 'سدادة قطنية',
    'sanitary_pad': 'فوطة صحية',
    'diaper': 'حفاض',
    'milk_formula': 'حليب أطفال صناعي',
    'nutritional_supplement': 'مكمل غذائي',
    'herbal_tea': 'شاي أعشاب',
    'tincture': 'صبغة',
    'extract': 'مستخلص',
    'essential_oil': 'زيت عطري',
    'homeopathic_preparation': 'مستحضر علاجي بالطب التجانسي',
    'vaccine': 'لقاح',
    'serum': 'مصل',
    'immunoglobulin': 'جلوبيولين مناعي',
    'allergen_extract': 'مستخلص مسبب للحساسية',
    'contrast_media': 'مادة تباين',
    'radiopharmaceutical': 'مستحضر صيدلاني إشعاعي',
    'disinfectant': 'مطهر',
    'antiseptic': 'معقم',
    'lubricant': 'مزلق',
    'sweetener': 'محلي',
    'flavoring_agent': 'عامل نكهة',
    'preservative': 'مادة حافظة',
    'emulsifier': 'مستحلب',
    'stabilizer': 'مثبت',
    'solvent': 'مذيب',
    'diluent': 'مخفف',
    'excipient': 'سواغ',
    'placebo': 'دواء وهمي',
    'other': 'أخرى'
}

# Translations for usage (expand as needed)
USAGE_TRANSLATIONS = {
    'eff': 'فوار', # Added translation
    'oral': 'عن طريق الفم',
    'oral.liquid': 'سائل فموي', # Added translation
    'oral.solid': 'صلب فموي', # Added translation
    'topical': 'موضعي',
    'unknown': 'غير معروف', # Added translation
    'injection': 'حقن',
    'inhalation': 'استنشاق',
    'rectal': 'شرجي',
    'soap': 'صابون', # Added translation
    'spray': 'بخاخ', # Added translation
    'vaginal': 'مهبلي',
    'ophthalmic': 'للعين',
    'otic': 'للأذن',
    'nasal': 'للأنف',
    'sublingual': 'تحت اللسان',
    'buccal': 'شدقي',
    'transdermal': 'عبر الجلد',
    'intravenous': 'وريدي',
    'intramuscular': 'عضلي',
    'subcutaneous': 'تحت الجلد',
    'intra-articular': 'داخل المفصل',
    'intrathecal': 'داخل القراب',
    'epidural': 'فوق الجافية',
    'irrigation': 'ري',
    'dialysis': 'غسيل كلوي',
    'diagnostic': 'تشخيصي',
    'other': 'أخرى'
}

# Helper function to safely convert to lowercase string
def safe_str_lower(value):
    if pd.isna(value):
        return ''
    return str(value).lower()

# Helper function to clean text (replace underscores, apply title case)
def clean_text_formatting(text):
    if pd.isna(text):
        return ''
    text = str(text).replace('_', ' ')
    # Apply title case, but handle potential all-caps words or acronyms if needed later
    return text.title()

# Helper function to apply sentence case
def apply_sentence_case(text):
    if pd.isna(text):
        return ''
    text = str(text).lower() # Start by lowercasing everything
    # Capitalize the first letter of the text and after sentence-ending punctuation
    text = re.sub(r'(^|[.!?]\s+)([a-z])', lambda p: p.group(1) + p.group(2).upper(), text)
    # Capitalize the very first letter if it wasn't caught
    if text:
        text = text[0].upper() + text[1:]
    return text

# Helper function to shorten company names (basic example)
def clean_company_name(name):
    if pd.isna(name):
        return ''
    name = str(name).strip()
    # Remove common suffixes
    suffixes = [' Pharmaceuticals', ' Pharma', ' Ltd', ' Inc', ' Corp', ' Company', ' Group', ' International', ' Egypt', ' S.A.E', ' SAE']
    for suffix in suffixes:
        if name.endswith(suffix):
            name = name[:-len(suffix)].strip()
            break # Remove only one suffix for now
    # Take first 1 or 2 words after suffix removal
    words = name.split()
    return ' '.join(words[:2]) # Return the first two words


# Main processing function
def process_drug_data():
    try:
        # Read Excel file
        print('#### قراءة ملف البيانات... ####')
        excel_file = 'druglist.xlsx'  # Input file name
        if not os.path.exists(excel_file):
            raise FileNotFoundError(f'#### ملف البيانات {excel_file} غير موجود ####')
            
        # Read Excel file with specific columns (B-N,P)
        df = pd.read_excel(excel_file, usecols='B:N,P')
        total_rows = len(df)
        print(f'#### جاري معالجة {total_rows} صف من البيانات ... ####')

        # Rename columns to match required structure
        column_mapping = {
            df.columns[0]: 'trade_name',      # B
            df.columns[1]: 'arabic_name',     # C
            df.columns[2]: 'old_price',       # D
            df.columns[3]: 'price',           # E
            df.columns[4]: 'active',          # F
            df.columns[5]: 'drug_pic_url',    # G
            df.columns[6]: 'category',        # H
            df.columns[7]: 'company',         # I
            df.columns[8]: 'dosage_form',     # J
            df.columns[9]: 'unit',            # K
            df.columns[10]: 'barcode',        # L
            df.columns[11]: 'usage',          # M
            df.columns[12]: 'description',    # N
            df.columns[13]: 'last_price_update' # P
        }
        df = df.rename(columns=column_mapping)

        # Helper function for main category assignment
        def assign_main_category(category_value):
            normalized_category = safe_str_lower(category_value)
            if not normalized_category:
                return 'other'

            # --- Start of Enhanced Category Logic ---

            # High Priority & Specific Conditions
            if 'cancer' in normalized_category or 'oncology' in normalized_category or 'sarcoma' in normalized_category or 'neoplastic' in normalized_category or 'tumor' in normalized_category or 'anti-angiogenic' in normalized_category or 'egfr inhibitor' in normalized_category or 'tyrosine kinase inhibitor' in normalized_category or 'proteasome inhibitor' in normalized_category or 'antimetabolite' in normalized_category:
                return 'oncology'
            if 'diabetic' in normalized_category or 'diabetes' in normalized_category or 'insulin' in normalized_category or 'glucose' in normalized_category or 'hypoglycemic' in normalized_category or 'alpha-glucosidase inhibitor' in normalized_category or 'glp-1 agonist' in normalized_category:
                return 'diabetes_care'
            if 'anesthetic' in normalized_category or 'anaesthetic' in normalized_category or 'anesthesia' in normalized_category:
                 return 'anesthetics'
            if 'vaccine' in normalized_category:
                return 'immunology' # Vaccines are primarily immunology
            if 'contrast' in normalized_category or 'diagnostic' in normalized_category:
                return 'diagnostics'
            if 'antidote' in normalized_category or 'anti-dote' in normalized_category:
                return 'other' # Keep antidotes broad for now
            if 'milk formula' in normalized_category or 'milk products' in normalized_category or 'nan' in normalized_category or 'sma' in normalized_category or 'hypo-allergenic milk' in normalized_category or 'lactose free milk' in normalized_category:
                return 'baby_care'
            if 'diaper' in normalized_category or 'diaber' in normalized_category or 'antidiper' in normalized_category:
                return 'baby_care'

            # System-Based Categories (Order matters: check more specific systems first)
            if 'hormone' in normalized_category or 'estrogen' in normalized_category or 'progesterone' in normalized_category or 'progestogen' in normalized_category or 'progestrone' in normalized_category or 'androgen' in normalized_category or 'thyroid' in normalized_category or 'corticosteroid' in normalized_category or 'steroid' in normalized_category or 'gnrh' in normalized_category or 'lh-rh agonist' in normalized_category or 'reductase inhibitor' in normalized_category or 'adenocorticoid' in normalized_category or 'glucocorticoid' in normalized_category or 'glucocorticoide' in normalized_category or 'testerone inhibitor' in normalized_category or 'calcimimetic' in normalized_category:
                return 'hormonal'
            if 'epileptic' in normalized_category or 'antiepiliptic' in normalized_category or 'convulsant' in normalized_category or 'depressant' in normalized_category or 'anxiolytic' in normalized_category or 'alzheimer' in normalized_category or 'parkinson' in normalized_category or 'neuro' in normalized_category or 'psychiatric' in normalized_category or 'nootropic' in normalized_category or 'migraine' in normalized_category or 'vertigo' in normalized_category or 'cholinesterase' in normalized_category or 'dopamine' in normalized_category or 'serotonin' in normalized_category or 'ssri' in normalized_category or 'mao inhibitor' in normalized_category or 'monoamine oxidase inhibitor' in normalized_category or 'adrenergic' in normalized_category or 'sympathomimetic' in normalized_category or 'nmda' in normalized_category or 'cns stimulant' in normalized_category or 'cns.stimulant' in normalized_category or 'wakefulness-promoting' in normalized_category or 'sleep aid' in normalized_category or 'insomnia' in normalized_category or 'melatonin' in normalized_category or 'attention deficit' in normalized_category or 'brain health' in normalized_category or 'cerebral vasodilator' in normalized_category or 'myasthenia gravis' in normalized_category or 'multiple sclerosis' in normalized_category or 'schizophrenia' in normalized_category or 'comt reversible inhibitor' in normalized_category or 'para sympathomimtic' in normalized_category:
                return 'neurological'
            if 'anemia' in normalized_category or 'antianemic' in normalized_category or 'coagulant' in normalized_category or 'platelet' in normalized_category or 'antiplatlet' in normalized_category or 'hematinic' in normalized_category or 'haematinic' in normalized_category or 'thrombin' in normalized_category or 'heparin' in normalized_category or 'fibrinolytic' in normalized_category or 'erythropoiesis' in normalized_category or 'blood' in normalized_category or 'factor xa' in normalized_category or 'thrombocytopenia' in normalized_category or 'thrombocythemia' in normalized_category or 'anti-rh' in normalized_category or 'human albumin' in normalized_category or 'albumin' in normalized_category or 'plasma expander' in normalized_category or 'systemic haemostatic' in normalized_category or 'thrombolytic agent' in normalized_category or 'tissue plasminogen activator' in normalized_category:
                return 'hematology'
            if 'muscle relaxant' in normalized_category or 'joint' in normalized_category or 'chondro' in normalized_category or 'condroprotective' in normalized_category or 'arthritis' in normalized_category or 'artharitic' in normalized_category or 'rheumatic' in normalized_category or 'bone' in normalized_category or 'spasmo' in normalized_category: # Moved antispasmodic here if muscle-related
                return 'musculoskeletal'
            if 'immune' in normalized_category or 'immuno' in normalized_category or 'tnf' in normalized_category or 'interleukin' in normalized_category or 'il-17a' in normalized_category or 'allergy' in normalized_category or 'allergic' in normalized_category or 'histamine' in normalized_category or 'anti-histaminic' in normalized_category or 'h1 antagonist' in normalized_category or 'h1 receptor antagonist' in normalized_category or 'h1-receptor antagonist' in normalized_category or 'mast cell stabilizer' in normalized_category or 'leukotriene' in normalized_category or 'colony stimulating factor' in normalized_category or 'janus kinase' in normalized_category or 'selective t cell costimulation modulator' in normalized_category or 'antitoxin' in normalized_category or 'iv.ig' in normalized_category or 'immunoglobulin' in normalized_category:
                return 'immunology'
            if 'contraceptive' in normalized_category or 'contraception' in normalized_category or 'fertility' in normalized_category or 'aphrodisiac' in normalized_category or 'ejaculation' in normalized_category or 'premature ej' in normalized_category or 'vaginal' in normalized_category or 'vagina' in normalized_category or 'iud' in normalized_category or 'prostate' in normalized_category or 'bph' in normalized_category or 'menopausal' in normalized_category or 'menstrual' in normalized_category or 'oligospermia' in normalized_category or 'women sexual desire' in normalized_category or 'lactagogue' in normalized_category or 'lactagauge' in normalized_category or 'lactogogue' in normalized_category or 'uterine relaxant' in normalized_category or 'labour inducer' in normalized_category or 'feminine gel' in normalized_category:
                return 'reproductive_health'
            if 'helminthic' in normalized_category or 'anthelmintic' in normalized_category or 'malarial' in normalized_category or 'protozoal' in normalized_category or 'tubercular' in normalized_category or 'viral' in normalized_category or 'scabicide' in normalized_category or 'scabicid' in normalized_category or 'lice' in normalized_category or 'antibiotic' in normalized_category or 'antiboitic' in normalized_category or 'bacterial' in normalized_category or 'antibecterial' in normalized_category or 'infective' in normalized_category or 'antiseptic' in normalized_category or 'penicillin' in normalized_category or 'peniciilins' in normalized_category or 'antifungal' in normalized_category or 'fungal' in normalized_category or 'hepatitis c' in normalized_category or 'herpes simplex' in normalized_category or 'chicken pox' in normalized_category or 'topical infections' in normalized_category or 'luminal amebicide' in normalized_category or 'luminal amoebicide' in normalized_category or 'metronidazole' in normalized_category or 'triple therapy for h.pylori' in normalized_category:
                 return 'anti_infective'
            if 'pain' in normalized_category or 'analgesic' in normalized_category or 'headache' in normalized_category or 'gout' in normalized_category or 'nsaid' in normalized_category or 'cox-2' in normalized_category or 'antipyretic' in normalized_category or 'anal fissure' in normalized_category or 'hemmoroid' in normalized_category or 'hemorrhoids' in normalized_category or 'haemorrhoids' in normalized_category:
                return 'pain_management'
            if 'inflam' in normalized_category or 'antiphlogistic' in normalized_category or 'pde-4' in normalized_category or 'edema' in normalized_category or 'antioedima' in normalized_category or 'swelling' in normalized_category:
                return 'anti_inflammatory'
            if 'cough' in normalized_category or 'couph' in normalized_category or 'anticogh' in normalized_category or 'anti.couph' in normalized_category or 'cold' in normalized_category or 'respiratory' in normalized_category or 'asthma' in normalized_category or 'bronchodilator' in normalized_category or 'bronchitis' in normalized_category or 'tussive' in normalized_category or 'nasal' in normalized_category or 'expectorant' in normalized_category or 'mucolytic' in normalized_category or 'mucolytec' in normalized_category or 'sore throat' in normalized_category or 'throat lozenges' in normalized_category:
                 return 'respiratory'
            if 'digest' in normalized_category or 'antacid' in normalized_category or 'laxative' in normalized_category or 'diarrhea' in normalized_category or 'antidiarrhoeal' in normalized_category or 'flatulence' in normalized_category or 'antiflatulent' in normalized_category or 'anti gas' in normalized_category or 'colic' in normalized_category or 'bowel' in normalized_category or 'emetic' in normalized_category or 'ulcer' in normalized_category or 'gastric' in normalized_category or 'carminative' in normalized_category or 'cholelithiasis' in normalized_category or 'cholecystitis' in normalized_category or 'motility' in normalized_category or 'ppi' in normalized_category or 'proton pump' in normalized_category or 'spasmodic' in normalized_category or 'spastic colon' in normalized_category or 'git' in normalized_category or 'choleretic' in normalized_category or 'bile acid sequestrant' in normalized_category or 'prokinetic agent' in normalized_category or 'h2-blocker' in normalized_category or '5-ht4 receptor agonist' in normalized_category or 'selective 5ht4 agonist' in normalized_category or '5-ht3 receptor antagonist' in normalized_category or 'nausea and vomiting' in normalized_category:
                return 'digestive'
            if 'cardio' in normalized_category or 'hypertens' in normalized_category or 'angina' in normalized_category or 'lipidemic' in normalized_category or 'anti-hyperlipidemia' in normalized_category or 'cholesterol' in normalized_category or 'blood pressure' in normalized_category or 'heart' in normalized_category or 'hypotension' in normalized_category or 'antihypotensive' in normalized_category or 'diuretic' in normalized_category or 'arrhythmia' in normalized_category or 'antiarrhythmic' in normalized_category or 'anti tachycardia' in normalized_category or 'statin' in normalized_category or 'nitrate' in normalized_category or 'beta blocker' in normalized_category or 'ace inhibitor' in normalized_category or 'angiotensin' in normalized_category or 'vasodilator' in normalized_category or 'vasoprotective' in normalized_category or 'vascular protecting' in normalized_category or 'vascular protective' in normalized_category or 'vascular-protecting' in normalized_category or 'vasoprotector' in normalized_category or 'capillary-stabilising' in normalized_category or 'anti-ischemic' in normalized_category or 'angioprotectors' in normalized_category or 'aldosterone receptor antagonist' in normalized_category or 'vasopressin analogue' in normalized_category or 'prostacyclin receptor agonist' in normalized_category or 'endothelian receptor antagonist' in normalized_category or 'potassium channel blocker' in normalized_category:
                return 'cardiovascular'
            if 'bladder' in normalized_category or 'urology' in normalized_category or 'alkalinizer' in normalized_category or 'alkalinizing agent' in normalized_category or 'urinary alkalinizing agent' in normalized_category or 'uti' in normalized_category or 'urinary tract infection' in normalized_category or 'renal' in normalized_category or 'nephro' in normalized_category or 'kidney' in normalized_category or 'urolithiac' in normalized_category or 'uroprotectant' in normalized_category or 'urination difficulty' in normalized_category or 'alpha1 blocker' in normalized_category or 'alpha blocker' in normalized_category or 'arginine vasopressin receptor 2 antagonist' in normalized_category or 'hyper-oxaluria' in normalized_category or 'hyperphosphatemia' in normalized_category or 'phosphate binder' in normalized_category or 'potassium binders' in normalized_category:
                 return 'urology'
            if 'skin' in normalized_category or 'acne' in normalized_category or 'dandruff' in normalized_category or 'scar' in normalized_category or 'wrinkle' in normalized_category or 'aging' in normalized_category or 'anti ageing' in normalized_category or 'hair' in normalized_category or 'peeling' in normalized_category or 'eczema' in normalized_category or 'psoriasis' in normalized_category or 'antipsoriatic' in normalized_category or 'dermatitis' in normalized_category or 'panthenol' in normalized_category or 'burn' in normalized_category or 'wound' in normalized_category or 'healing' in normalized_category or 'impetigo' in normalized_category or 'keratolytic' in normalized_category or 'anti stretch mark' in normalized_category or 'whiting cream' in normalized_category or 'vitiligo' in normalized_category or 'sclerosant' in normalized_category or 'tissue adhesive' in normalized_category or 'topical' in normalized_category:
                return 'skin_care'
            if 'eye' in normalized_category or 'ophthalmic' in normalized_category or 'glaucoma' in normalized_category or 'conjunctivitis' in normalized_category or 'mydriatic' in normalized_category or 'ocular pressure' in normalized_category or 'anti-intra occular pressure' in normalized_category or 'cataract' in normalized_category or 'corneal vascularity' in normalized_category:
                 return 'eye_care'
            if 'ear' in normalized_category or 'otic' in normalized_category:
                 return 'ear_care'

            # General Categories (Lower Priority)
            if 'vitamin' in normalized_category or 'vit d' in normalized_category or 'vit c' in normalized_category or 'vit b' in normalized_category or 'multivitamin' in normalized_category or 'multiviamin' in normalized_category or 'multiviatmin' in normalized_category or 'multivutamin' in normalized_category or 'vitd3' in normalized_category or 'folate' in normalized_category or 'folic' in normalized_category or 'b12' in normalized_category or 'b complex' in normalized_category or 'nicotinic acid' in normalized_category:
                return 'vitamins'
            if 'supplement' in normalized_category or 'supplment' in normalized_category or 'mineral' in normalized_category or 'iron' in normalized_category or 'calcium' in normalized_category or 'calciam' in normalized_category or 'zinc' in normalized_category or 'omega' in normalized_category or 'amino acid' in normalized_category or 'osteoporosis' in normalized_category or 'antioxidant' in normalized_category or 'anti oxidant' in normalized_category or 'anti-oxidant' in normalized_category or 'anti-oxident' in normalized_category or 'antioxidabt' in normalized_category or 'collagen' in normalized_category or 'lactoferrin' in normalized_category or 'nutraceutical' in normalized_category or 'tonic' in normalized_category or 'protein' in normalized_category or 'fiber' in normalized_category or 'cod liver oil' in normalized_category or 'coenzyme q10' in normalized_category or 'magnesium' in normalized_category or 'selenium' in normalized_category or 'potassium' in normalized_category or 'appetizer' in normalized_category or 'immunity' in normalized_category or 'immunty' in normalized_category or 'inhance immunity' in normalized_category or 'brain booster' in normalized_category or 'memory booster' in normalized_category or 'mind booster' in normalized_category or 'liver support' in normalized_category or 'hepatoprotective' in normalized_category or 'nutrition' in normalized_category or 'nutritive powder' in normalized_category or 'high protien drink' in normalized_category or 'cereals' in normalized_category or 'sweetener' in normalized_category or 'sugar substitute' in normalized_category or 'stevia' in normalized_category or 'artificial sweetener' in normalized_category or 'diatery supplment' in normalized_category or 'enzyme' in normalized_category or 'proteolytic' in normalized_category or 'lactase' in normalized_category or 'agar' in normalized_category or 'apple vinegar' in normalized_category or 'evening primrose oil' in normalized_category or 'probiotic' in normalized_category or 'inulin' in normalized_category or 'obesity' in normalized_category or 'weight management' in normalized_category or 'weight loss' in normalized_category or 'weigh loss' in normalized_category or 'fat burner' in normalized_category or 'diet' in normalized_category:
                return 'supplements'
            # Removed probiotics from here as it's now under supplements
            if 'herbal' in normalized_category or 'ginseng' in normalized_category or 'ginko' in normalized_category or 'natural' in normalized_category or 'plant extract' in normalized_category or 'herbs' in normalized_category or 'chamomile' in normalized_category or 'turmeric' in normalized_category or 'ginger' in normalized_category or 'thymus' in normalized_category or 'eucalyptus' in normalized_category or 'clove oil' in normalized_category or 'camphor oil' in normalized_category or 'peppermint oil' in normalized_category or 'morinda citrifolia' in normalized_category or 'saw palmetto' in normalized_category or 'pumpkin seed oil' in normalized_category or 'snake oil' in normalized_category or 'garlicoil' in normalized_category or 'olive oil' in normalized_category or 'wheat germ oil' in normalized_category or 'almond oil' in normalized_category or 'aloeoil' in normalized_category or 'sunflower oil' in normalized_category or 'avocado extract' in normalized_category or 'lavander oil' in normalized_category or 'caraway oil' in normalized_category:
                return 'herbal_natural'
            # Moved baby care higher up
            if 'cosmetic' in normalized_category or 'beauty' in normalized_category or 'shampoo' in normalized_category or 'serum' in normalized_category or 'sunscreen' in normalized_category or 'sunblock' in normalized_category or 'sun block' in normalized_category or 'sun screen' in normalized_category or 'sunscreeen' in normalized_category or 'moisturizing' in normalized_category or 'moisturiser' in normalized_category or 'moisturizer' in normalized_category or 'moisturise' in normalized_category or 'emollient' in normalized_category or 'emollinent' in normalized_category or 'whitening' in normalized_category or 'firming' in normalized_category or 'exfoliating' in normalized_category or 'contour cream' in normalized_category or 'facial cleansing' in normalized_category or 'facial cream' in normalized_category or 'facial gel' in normalized_category or 'hydrating lotion' in normalized_category or 'body lotion' in normalized_category or 'rejuvenating' in normalized_category or 'antiperspirant' in normalized_category:
                 return 'cosmetics'
            if 'care' in normalized_category or 'personal lubricant' in normalized_category or 'lubricant' in normalized_category or 'lubricating jelly' in normalized_category or 'delay gel' in normalized_category or 'delay lubricant' in normalized_category or 'dental' in normalized_category or 'mouthwash' in normalized_category or 'toothpaste' in normalized_category or 'tooth gel' in normalized_category or 'deodorant' in normalized_category or 'cleanser' in normalized_category or 'wash' in normalized_category or 'massage' in normalized_category or 'message cream' in normalized_category or 'message spray' in normalized_category or 'soothing' in normalized_category or 'calm' in normalized_category or 'mouth refresh' in normalized_category or 'oral fresh' in normalized_category or 'oral spray' in normalized_category or 'soap' in normalized_category or 'disinfectant' in normalized_category or 'antiseptic' in normalized_category or 'demulcent' in normalized_category or 'astringent' in normalized_category or 'antipruritic' in normalized_category or 'scalp lotion' in normalized_category or 'napkin lotion' in normalized_category or 'hydrogel' in normalized_category or 'silicon gel' in normalized_category:
                 return 'personal_care'
            if 'supply' in normalized_category or 'supplies' in normalized_category or 'dressing' in normalized_category or 'bandage' in normalized_category or 'gauze' in normalized_category or 'syringe' in normalized_category or 'needle' in normalized_category or 'test strip' in normalized_category or 'parenteral' in normalized_category or 'solution' in normalized_category or 'saline' in normalized_category or 'ringer' in normalized_category or 'water' in normalized_category or 'drops' in normalized_category or 'drop' in normalized_category or 'spray' in normalized_category or 'cream' in normalized_category or 'lotion' in normalized_category or 'gel' in normalized_category or 'ointment' in normalized_category or 'powder' in normalized_category or 'suspension' in normalized_category or 'syrup' in normalized_category or 'tablets' in normalized_category or 'capsules' in normalized_category or 'lozenges' in normalized_category or 'ampoules' in normalized_category or 'vial' in normalized_category or 'sachets' in normalized_category or 'enema' in normalized_category or 'suppositories' in normalized_category or 'patch' in normalized_category or 'inhaler' in normalized_category: # Generic forms might fall here if not caught by specific categories
                return 'medical_supplies'
            if 'device' in normalized_category: # Catch-all for devices if not IUD
                return 'medical_devices'
            # Removed weight management as it's now under supplements

            # --- End of Enhanced Category Logic ---

            # Fallback (if none of the above matched)
            return 'other'

        # Process translations using existing dictionaries
        def safe_str_lower(value):
            if pd.isna(value):
                return ''
            return str(value).lower()

        # Apply the new function for main category assignment
        df['main_category'] = df['category'].apply(assign_main_category)

        # --- Add code to identify 'other' categories --- (Keep this for verification)
        other_categories = df[df['main_category'] == 'other']['category'].unique()
        if len(other_categories) > 0:
            print("\nالفئات التي لا تزال مصنفة كـ 'أخرى' بعد التحسين:") # Corrected string literal
            # Filter out potential NaN/None before converting to string and sorting
            filtered_categories = [str(c) for c in other_categories if pd.notna(c) and str(c).strip() and str(c).strip() != '.']
            for cat in sorted(filtered_categories):
                print(f"- {cat}")
        # --- End of added code ---

        # Update main_category_ar mapping, handling 'other' explicitly
        df['main_category_ar'] = df['main_category'].apply(lambda k: MAIN_CATEGORIES.get(k, MAIN_CATEGORIES['other'])) # Use 'أخرى' for 'other' or any unmapped key

        # Format main_category for display (Title Case, spaces instead of underscores)
        df['main_category'] = df['main_category'].apply(lambda x: str(x).replace('_', ' ').title())
        
        # Fix category_ar mapping by cleaning and normalizing the category values
        # Consider improving this if CATEGORY_TRANSLATIONS needs expansion
        df['category_ar'] = df['category'].apply(lambda x: CATEGORY_TRANSLATIONS.get(safe_str_lower(x).replace(' ', '_'), ''))

        # Clean Dosage Form (Title Case, Underscores) BEFORE translation lookup
        df['dosage_form'] = df['dosage_form'].apply(clean_text_formatting)
        df['dosage_form_ar'] = df['dosage_form'].apply(safe_str_lower).map(DOSAGE_FORM_TRANSLATIONS) # Lookup uses lower case

        # Clean Usage (Title Case, Underscores) BEFORE translation lookup
        df['usage'] = df['usage'].apply(clean_text_formatting)
        df['usage_ar'] = df['usage'].apply(safe_str_lower).map(USAGE_TRANSLATIONS) # Lookup uses lower case

        # Clean Company Names
        df['company'] = df['company'].apply(clean_company_name)

        # Clean Description (Sentence Case)
        df['description'] = df['description'].apply(apply_sentence_case)

        # Fix last_price_update conversion
        def safe_to_timestamp(date_str):
            try:
                if pd.isna(date_str):
                    return None
                if isinstance(date_str, (int, float)):
                    # Convert Unix timestamp (milliseconds since epoch)
                    if date_str > 1e10:  # Assuming milliseconds if value is large
                        date_str = date_str / 1000
                    return datetime.fromtimestamp(date_str).strftime('%d/%m/%Y')
                if isinstance(date_str, str):
                    # Try parsing as datetime string
                    return pd.to_datetime(date_str).strftime('%d/%m/%Y')
                return None
            except:
                return None

        df['last_price_update'] = df['last_price_update'].apply(safe_to_timestamp)

        # Reorder columns as specified
        column_order = [
            'trade_name',
            'arabic_name',
            'old_price',
            'price',
            'active',
            'main_category',
            'main_category_ar',
            'category',
            'category_ar',
            'company',
            'dosage_form',
            'dosage_form_ar',
            'unit',
            'usage',
            'usage_ar',
            'description',
            'last_price_update'
        ]
        df = df[column_order]

        # Save processed data
        print('#### حفظ البيانات... ####')
        today_date = datetime.now().strftime('%d-%m-%Y')
        output_file = f'druglist-{today_date}.csv'
        df.to_csv(output_file, index=False, encoding='utf-8-sig') # Use utf-8-sig for better compatibility with Excel
        print(f'✅✅✅✅ تم حفظ البيانات بنجاح في {output_file}! ✅✅✅✅')

    except Exception as e:
        print(f'❌❌❌❌ حدث خطأ: {str(e)} ❌❌❌❌')

if __name__ == '__main__':
    process_drug_data()