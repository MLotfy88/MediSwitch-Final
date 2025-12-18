class CategoryMapperHelper {
  // --- 1. Cardiovascular ---
  static const _cardioKeywords = [
    'cardio',
    'hypertension',
    'hypertensive',
    'angina',
    'arrhythmia',
    'heart failure',
    'beta blocker',
    'calcium channel',
    'ace inhibitor',
    'diuretic',
    'vasodilator',
    'antiplatelet',
    'anticoagulant',
    'lipid',
    'cholesterol',
    'statin',
    'thromb',
    'vein',
    'ischemic',
    'adrenergic',
    'aldosterone',
    'angiotensin',
    'anti-ischemic',
    'anti-tachycardia',
    'antiarrhythmic',
    'antihypertensive',
    'cardiotonic',
    'heart',
    'hyperlipidemia',
    'hypotension',
    'renin',
    'sartans',
    'vasopressin',
    'venous',
    'clotting',
    'coagulation',
    'heparin',
    'warfarin',
    'clopidogrel',
    'fibrinolytic',
    'sclerosing',
    'varicose',
    'hemorrhagic',
    'hemorheological',
  ];

  // --- 2. Anti-Infective ---
  static const _antiInfectiveKeywords = [
    'biotic',
    'bacterial',
    'viral',
    'fungal',
    'infective',
    'septic',
    'parasit',
    'protozoal',
    'malaria',
    'amoeb',
    'helminth',
    'lice',
    'scabi',
    'mycotic',
    'vaccine',
    'amebicide',
    'aminoglycoside',
    'anthelmentic',
    'antibacterial',
    'antileprotic',
    'antimalarial',
    'antimicrobial',
    'antimycobacterial',
    'antiparasitic',
    'antiprotozoal',
    'antiseptic',
    'antitubercular',
    'antiviral',
    'bacitracin',
    'bactericidal',
    'carbapenem',
    'cephalosporin',
    'ciprofloxacin',
    'clindamycin',
    'disinfectant',
    'fluconazole',
    'fluoroquinolone',
    'gentamicin',
    'glycopeptide',
    'herpes',
    'imipenem',
    'interferon',
    'ivermectin',
    'lincomycin',
    'macrolide',
    'metronidazole',
    'moxifloxacin',
    'nitroimidazole',
    'penicillin',
    'polymyxin',
    'quinolone',
    'rifampicin',
    'scabicide',
    'sulfonamide',
    'tetracycline',
    'tobramycin',
    'vancomycin',
    'worm',
    'nits',
  ];

  // --- 3. Respiratory ---
  static const _respiratoryKeywords = [
    'respiratory',
    'asthma',
    'bronch',
    'cough',
    'cold',
    'flu',
    'nasal',
    'sinus',
    'throat',
    'expectorant',
    'mucolytic',
    'antitussive',
    'pulmonary',
    'decongestant',
    'histamine',
    'antihistamine',
    'bronchitis',
    'copd',
    'inhalation',
    'leukotriene',
    'rhinitis',
    'sore throat',
    'chest rub',
    'rubefacient',
    'pharyngeal',
  ];

  // --- 4. Neurology ---
  static const _neurologyKeywords = [
    'epilep',
    'convuls',
    'seizure',
    'parkinson',
    'alzheimer',
    'neuro',
    'migraine',
    'vertigo',
    'dizziness',
    'sclerosis',
    'myasthenia',
    'cholinesterase',
    'memory',
    'brain',
    'acetylcholinesterase',
    'anticholinergic',
    'anticonvulsant',
    'antiepileptic',
    'barbiturate',
    'benzodiazepine',
    'dementia',
    'dopamine',
    'gaba',
    'hydantoin',
    'multiple sclerosis',
    'nerve',
    'neuropathy',
    'neuroprotective',
    'nootropic',
    'parasympathomimetic',
    'cognitive',
    'attention',
    'cerebral',
    'sclerosis',
  ];

  // --- 5. Psychiatric ---
  static const _psychiatricKeywords = [
    'psych',
    'depress',
    'anxiety',
    'anxiolytic',
    'schizo',
    'sedative',
    'hypnotic',
    'insomnia',
    'mood',
    'bipolar',
    'adhd',
    'addiction',
    'antidepressant',
    'antipsychotic',
    'lithium',
    'mao',
    'monoamine',
    'neuroleptic',
    'obsessive',
    'panic',
    'psychosis',
    'serotonin',
    'sleep',
    'tranquilizer',
    'social',
    'phobia',
  ];

  // --- 6. Gastroenterology (GIT) ---
  static const _gastroKeywords = [
    'git',
    'gastro',
    'stomach',
    'bowel',
    'ulcer',
    'reflux',
    'antacid',
    'proton pump',
    'laxative',
    'constipation',
    'diarrhea',
    'emetic',
    'nausea',
    'vomiting',
    'colic',
    'flatulen',
    'digest',
    'enzyme',
    'liver',
    'hepat',
    'biliary',
    'gall',
    'antidiarrheal',
    'antiemetic',
    'antiflatulent',
    'antispasmodic',
    'appetite',
    'bile',
    'cathartic',
    'colitis',
    'dyspepsia',
    'enema',
    'gerd',
    'h.pylori',
    'h2',
    'heartburn',
    'hemorrhoid',
    'ibs',
    'irritable',
    'motility',
    'peptic',
    'probiotic',
    'purgative',
    'spasmodic',
    'suppository',
    'rectal',
  ];

  // --- 7. Dermatology ---
  static const _dermatologyKeywords = [
    'dermat',
    'skin',
    'acne',
    'eczema',
    'psoriasis',
    'scart',
    'scar',
    'sun',
    'burn',
    'hair',
    'scalp',
    'dandruff',
    'emollient',
    'moistur',
    'whitening',
    'pigmentation',
    'rash',
    'alopecia',
    'anti-acne',
    'anti-dandruff',
    'anti-hair',
    'antipruritic',
    'astringent',
    'barrier',
    'callus',
    'cleanser',
    'corn',
    'cream',
    'fungal',
    'hirsutism',
    'keratolytic',
    'lotion',
    'melasma',
    'nail',
    'ointment',
    'pediculicide',
    'protectant',
    'rosacea',
    'scab',
    'seborrh',
    'shampoo',
    'soap',
    'topical',
    'wart',
    'wound',
    'wrinkle',
    'aging',
    'sweat',
    'antiperspirant',
    'deodorant',
  ];

  // --- 8. Urology ---
  static const _urologyKeywords = [
    'urolog',
    'urin',
    'bladder',
    'prostat',
    'bph',
    'erectile',
    'impotence',
    'renal',
    'kidney',
    'stone',
    'alpha-reductase',
    'cystitis',
    'enuresis',
    'incontinence',
    'nephrolithiasis',
    'overactive',
    'sexual',
    'sildenafil',
    'tadalafil',
    'premature',
    'ejaculat',
    'viagra',
    'cialis',
    'levitra',
    'andrology',
    'genital',
  ];

  // --- 9. Gynecology ---
  static const _gynecologyKeywords = [
    'gynec',
    'women',
    'female',
    'contracept',
    'menopaus',
    'menstru',
    'vagin',
    'uter',
    'labor',
    'pregnancy',
    'fertil',
    'lactat',
    'breast',
    'estrogen',
    'fsh',
    'gnrh',
    'gonadotropin',
    'hormone replacement',
    'hrt',
    'infertility',
    'luteinizing',
    'obstetric',
    'ovulation',
    'oxytocin',
    'progester',
    'progestin',
    'tocolytic',
    'vaginal',
  ];

  // --- 10. Endocrinology ---
  static const _endocrinologyKeywords = [
    'endocrin', 'diabet', 'insulin', 'thyroid', 'hormone', 'metabolic',
    'glucose',
    'growth',
    'acarbose',
    'androgen',
    'antidiabetic',
    'corticosteroid',
    'cortisone',
    'dpp-4',
    'glibenclamide',
    'glimepiride',
    'glipizide',
    'glucagon',
    'hyperglycem', 'hypoglycem', 'metformin', 'parathyroid', 'pioglitazone',
    'reductase',
    'sglt2',
    'steroid',
    'sulfonylurea',
    'testosterone',
    'thyroxine',
    'obesity', 'weight loss', 'slimming', // Often metabolic/endo
  ];

  // --- 11. Ophthalmology ---
  static const _ophthalmologyKeywords = [
    'ophthalm',
    'eye',
    'ocular',
    'optic',
    'glaucoma',
    'mydriatic',
    'tears',
    'contact lens',
    'cataract',
    'conjunctivitis',
    'intraocular',
    'lens',
    'miotic',
    'vision',
    'viscoelastic',
  ];

  // --- 12. Pain Relief ---
  static const _painReliefKeywords = [
    'analgesic',
    'nsaid',
    'pain',
    'headache',
    'antipyretic',
    'fever',
    'anesthetic',
    'aspirin',
    'cox-2',
    'diclofenac',
    'fentanyl',
    'ibuprofen',
    'ketometh',
    'lidocaine',
    'morphine',
    'naloxone',
    'narcotic',
    'opioid',
    'paracetamol',
    'tramadol',
    'migraine',
    'neuralgia',
    'toothache',
  ];

  // --- 13. Orthopedics ---
  static const _orthopedicsKeywords = [
    'ortho',
    'bone',
    'joint',
    'muscle',
    'musculo',
    'skeletal',
    'arthrit',
    'rheum',
    'osteopor',
    'chondro',
    'cartilage',
    'back',
    'glucosamine',
    'gout',
    'myorelaxant',
    'rubefacient',
    'spasm',
    'tendon',
    'uric acid',
    'stiffness',
    'mobility',
  ];

  // --- 14. Hematology ---
  static const _hematologyKeywords = [
    'hemat',
    'anemia',
    'coagulation',
    'thromb',
    'antihemophilic',
    'clopidogrel',
    'enoxaparin',
    'erythropoietin',
    'fibrinolytic',
    'heparin',
    'iron',
    'plasma',
    'platelet',
    'warfarin',
    'bleeding',
    'hemoglobin',
  ];

  // --- 15. Oncology ---
  static const _oncologyKeywords = [
    'onco',
    'cancer',
    'tumor',
    'neoplastic',
    'chemo',
    'cytotoxic',
    'leukemia',
    'alkylating',
    'antimetabolite',
    'antineoplastic',
    'interleukin',
    'kinase',
    'lymphoma',
    'metastatic',
    'monoclonal',
    'carcinoma',
    'sarcoma',
  ];

  // --- 16. Nutrition ---
  static const _nutritionKeywords = [
    'nutrition',
    'vitamin',
    'mineral',
    'supple',
    'diet',
    'food',
    'feeding',
    'milk',
    'formula',
    'weight',
    'appetit',
    'tonic',
    'calcium',
    'magnesium',
    'zinc',
    'omega',
    'amino acid',
    'electrolyte',
    'potassium',
    'protein',
    'baby food',
    'infant',
    'energy',
    'multivitamin',
  ];

  // --- 17. Immunology ---
  static const _immunologyKeywords = [
    'immun',
    'allergy',
    'hypersens',
    'allergen',
    'anti-allergic',
    'desensitiz',
    'serum',
    'immunoglobulin',
    'immunosuppress',
  ];

  /// Maps a detailed drug category/classification to a broad medical specialty ID.
  static String mapCategoryToSpecialty(String detailedCategory) {
    if (detailedCategory.isEmpty) return 'general';
    final lower = detailedCategory.toLowerCase();

    // Priority checks for ambiguous terms

    // Eye drops (often "antibiotic eye drops") -> Ophthalmology
    if (lower.contains('eye') ||
        lower.contains('ophthalm') ||
        lower.contains('ocular')) {
      if (!lower.contains('fish oil'))
        return 'ophthalmology'; // Avoid "Omega 3 for eye health" -> Nutrition? No, if it's for eye, usually Ophtha.
    }

    // Ear drops -> General? Or Anti-Infective?
    // User list has "Ear drops". Let's map to General or Specific if Infection.

    // 1. Cardiovascular
    if (_matches(lower, _cardioKeywords)) return 'cardiovascular';

    // 2. Respiratory (Check before Anti-Infective for "Cold/Flu" overlap)
    if (_matches(lower, _respiratoryKeywords)) return 'respiratory';

    // 3. Anti-Infective
    if (_matches(lower, _antiInfectiveKeywords) ||
        (lower.contains('cold') && lower.contains('virus')))
      return 'anti_infective';

    // 4. Neurology
    if (_matches(lower, _neurologyKeywords)) return 'neurology';

    // 5. Psychiatric
    if (_matches(lower, _psychiatricKeywords)) return 'psychiatric';

    // 6. Gastroenterology
    if (_matches(lower, _gastroKeywords) ||
        (lower.contains('spasmodic') && lower.contains('anti')))
      return 'gastroenterology';

    // 7. Urology (Prostate/BPH/Sexual)
    if (_matches(lower, _urologyKeywords)) return 'urology';

    // 8. Gynecology
    if (_matches(lower, _gynecologyKeywords)) return 'gynecology';

    // 9. Endocrinology
    if (_matches(lower, _endocrinologyKeywords) ||
        (lower.contains('steroid') &&
            !lower.contains('topical') &&
            !lower.contains('nasal') &&
            !lower.contains('inhal')) ||
        (lower.contains('corticosteroid') && !lower.contains('topical')))
      return 'endocrinology';

    // 10. Ophthalmology (Redundant check but safe for keywords)
    if (_matches(lower, _ophthalmologyKeywords)) return 'ophthalmology';

    // 11. Dermatology
    // Check AFTER Endo because of oral steroids.
    // Check AFTER Anti-Infective? Fungals -> Derma or Anti-Inf? Usually topical = derma.
    if (_matches(lower, _dermatologyKeywords)) return 'dermatology';
    if (lower.contains('fungal') && lower.contains('topical'))
      return 'dermatology';

    // 12. Orthopedics
    if (_matches(lower, _orthopedicsKeywords)) return 'orthopedics';

    // 13. Pain Relief (After Ortho to treat Arthritis as Ortho)
    if (_matches(lower, _painReliefKeywords)) return 'pain_relief';

    // 14. Hematology
    if (_matches(lower, _hematologyKeywords)) return 'hematology';
    if (lower.contains('iron') && lower.contains('anemia')) return 'hematology';

    // 15. Oncology
    if (_matches(lower, _oncologyKeywords)) return 'oncology';

    // 16. Immunology
    if (_matches(lower, _immunologyKeywords)) return 'immunology';

    // 17. Nutrition
    if (_matches(lower, _nutritionKeywords) || lower.contains('iron'))
      return 'nutrition';

    return 'general';
  }

  static bool _matches(String text, List<String> keywords) {
    for (final k in keywords) {
      if (text.contains(k)) return true;
    }
    return false;
  }

  /// Returns the list of keywords for a given specialty to be used in SQL queries.
  static List<String> getKeywords(String specialtyId) {
    switch (specialtyId) {
      case 'cardiovascular':
        return _cardioKeywords;
      case 'anti_infective':
        return _antiInfectiveKeywords;
      case 'respiratory':
        return _respiratoryKeywords;
      case 'neurology':
        return _neurologyKeywords;
      case 'psychiatric':
        return _psychiatricKeywords;
      case 'gastroenterology':
        return _gastroKeywords;
      case 'dermatology':
        return _dermatologyKeywords;
      case 'urology':
        return _urologyKeywords;
      case 'gynecology':
        return _gynecologyKeywords;
      case 'endocrinology':
        return _endocrinologyKeywords;
      case 'ophthalmology':
        return _ophthalmologyKeywords;
      case 'pain_relief':
        return _painReliefKeywords;
      case 'orthopedics':
        return _orthopedicsKeywords;
      case 'hematology':
        return _hematologyKeywords;
      case 'oncology':
        return _oncologyKeywords;
      case 'nutrition':
        return _nutritionKeywords;
      case 'immunology':
        return _immunologyKeywords;
      default:
        return [];
    }
  }
}
