"""
Comprehensive Drug Synonym Dictionary for DDInter Matching
Manually curated to ensure pharmaceutical accuracy
"""

# Local ingredient name -> DDInter standard name
DRUG_SYNONYMS = {
    # Paracetamol variants
    'paracetamol': 'Acetaminophen',
    'paracetamol(acetaminophen)': 'Acetaminophen',
    
    # Vitamins - precise mapping
    'ascorbic acid': 'Ascorbic acid',
    'vitamin c': 'Ascorbic acid',
    
    'cholecalciferol': 'Cholecalciferol',
    'vitamin d3': 'Cholecalciferol',
    'vitamin d': 'Cholecalciferol',
    
    'ergocalciferol': 'Ergocalciferol',
    'vitamin d2': 'Ergocalciferol',
    
    'cyanocobalamin': 'Cyanocobalamin',
    'vitamin b12': 'Cyanocobalamin',
    'vitamin b 12': 'Cyanocobalamin',
    
    'pyridoxine': 'Pyridoxine',
    'vitamin b6': 'Pyridoxine',
    'vitamin b 6': 'Pyridoxine',
    
    'thiamine': 'Thiamine',
    'thiamin': 'Thiamine',
    'vitamin b1': 'Thiamine',
    'vitamin b 1': 'Thiamine',
    
    'riboflavin': 'Riboflavin',
    'vitamin b2': 'Riboflavin',
    'vitamin b 2': 'Riboflavin',
    
    'niacin': 'Niacin',
    'nicotinic acid': 'Niacin',
    'vitamin b3': 'Niacin',
    'vitamin b 3': 'Niacin',
    
    'folic acid': 'Folic acid',
    'folate': 'Folic acid',
    'vitamin b9': 'Folic acid',
    
    'biotin': 'Biotin',
    'vitamin b7': 'Biotin',
    'vitamin h': 'Biotin',
    
    'tocopherol': 'Vitamin E',
    'alpha tocopherol': 'Vitamin E',
    'vitamin e': 'Vitamin E',
    
    'phytonadione': 'Phytonadione',
    'phytomenadione': 'Phytonadione',
    'vitamin k1': 'Phytonadione',
    'vitamin k': 'Phytonadione',
    
    # Antibiotics
    'amoxicillin': 'Amoxicillin',
    'amoxycillin': 'Amoxicillin',
    'amoxicillin trihydrate': 'Amoxicillin',
    
    'ampicillin': 'Ampicillin',
    'ampicillin trihydrate': 'Ampicillin',
    
    'cefadroxil': 'Cefadroxil',
    'cefadroxyl': 'Cefadroxil',
    
    'cephalexin': 'Cephalexin',
    'cefalexin': 'Cephalexin',
    
    'cefradine': 'Cefradine',
    'cephradine': 'Cefradine',
    
    'azithromycin': 'Azithromycin',
    'clarithromycin': 'Clarithromycin',
    'erythromycin': 'Erythromycin',
    'roxithromycin': 'Clarithromycin',  # Similar macrolide
    
    'ciprofloxacin': 'Ciprofloxacin',
    'ciprofloxacin hcl': 'Ciprofloxacin',
    
    'levofloxacin': 'Levofloxacin',
    'moxifloxacin': 'Moxifloxacin',
    
    'metronidazole': 'Metronidazole',
    'tinidazole': 'Tinidazole',
    
    # Pain & Anti-inflammatory
    'ibuprofen': 'Ibuprofen',
    'dexibuprofen': 'Ibuprofen',
    
    'diclofenac': 'Diclofenac',
    'diclofenac sodium': 'Diclofenac',
    'diclofenac potassium': 'Diclofenac',
    
    'naproxen': 'Naproxen',
    'naproxen sodium': 'Naproxen',
    
    'aspirin': 'Acetylsalicylic acid',
    'acetylsalicylic acid': 'Acetylsalicylic acid',
    
    'tramadol': 'Tramadol',
    'tramadol hcl': 'Tramadol',
    
    'meloxicam': 'Meloxicam',
    'tenoxicam': 'Meloxicam',  # Similar oxicam
    
    # Cardiovascular
    'amlodipine': 'Amlodipine',
    'amlodipine besylate': 'Amlodipine',
    
    'atenolol': 'Atenolol',
    'metoprolol': 'Metoprolol',
    'bisoprolol': 'Bisoprolol',
    'carvedilol': 'Carvedilol',
    
    'enalapril': 'Enalapril',
    'ramipril': 'Ramipril',
    'lisinopril': 'Lisinopril',
    'perindopril': 'Perindopril',
    
    'losartan': 'Losartan',
    'valsartan': 'Valsartan',
    'telmisartan': 'Telmisartan',
    
    'atorvastatin': 'Atorvastatin',
    'simvastatin': 'Simvastatin',
    'rosuvastatin': 'Rosuvastatin',
    
    'clopidogrel': 'Clopidogrel',
    
    # Antidiabetic
    'metformin': 'Metformin',
    'metformin hcl': 'Metformin',
    
    'glimepiride': 'Glimepiride',
    'gliclazide': 'Gliclazide',
    'glibenclamide': 'Glyburide',
    'glyburide': 'Glyburide',
    
    'sitagliptin': 'Sitagliptin',
    'vildagliptin': 'Vildagliptin',
    'linagliptin': 'Linagliptin',
    
    'insulin': 'Insulin (human)',
    'insulin glargine': 'Insulin glargine',
    'insulin aspart': 'Insulin aspart',
    
    'semaglutide': 'Semaglutide',
    'liraglutide': 'Liraglutide',
    
    # GI Drugs
    'omeprazole': 'Omeprazole',
    'esomeprazole': 'Esomeprazole',
    'pantoprazole': 'Pantoprazole',
    'pantoprazole sodium': 'Pantoprazole',
    'lansoprazole': 'Lansoprazole',
    'rabeprazole': 'Rabeprazole',
    
    'ranitidine': 'Ranitidine',
    'famotidine': 'Famotidine',
    
    'domperidone': 'Domperidone',
    'metoclopramide': 'Metoclopramide',
    
    # Antihistamines
    'cetirizine': 'Cetirizine',
    'cetirizine hcl': 'Cetirizine',
    
    'loratadine': 'Loratadine',
    'desloratadine': 'Desloratadine',
    'fexofenadine': 'Fexofenadine',
    
    'chlorpheniramine': 'Chlorpheniramine',
    'diphenhydramine': 'Diphenhydramine',
    
    # Respiratory
    'salbutamol': 'Albuterol',
    'albuterol': 'Albuterol',
    
    'montelukast': 'Montelukast',
    'montelukast sodium': 'Montelukast',
    
    'fluticasone': 'Fluticasone (inhalation)',
    'fluticasone propionate': 'Fluticasone (inhalation)',
    
    # Psychotropics
    'fluoxetine': 'Fluoxetine',
    'sertraline': 'Sertraline',
    'paroxetine': 'Paroxetine',
    'citalopram': 'Citalopram',
    'escitalopram': 'Escitalopram',
    
    'alprazolam': 'Alprazolam',
    'lorazepam': 'Lorazepam',
    'diazepam': 'Diazepam',
    'clonazepam': 'Clonazepam',
    
    # Specialty
    'levothyroxine': 'Levothyroxine',
    'levothyroxine sodium': 'Levothyroxine',
    'thyroxine': 'Levothyroxine',
    
    'prednisolone': 'Prednisolone',
    'prednisone': 'Prednisone',
    'dexamethasone': 'Dexamethasone',
    'hydrocortisone': 'Hydrocortisone',
    
    'warfarin': 'Warfarin',
    'warfarin sodium': 'Warfarin',
    
    'allopurinol': 'Allopurinol',
    'colchicine': 'Colchicine',
    
    'levocarnitine': 'Levocarnitine',
    'l carnitine': 'Levocarnitine',
    'l-carnitine': 'Levocarnitine',
    'carnitine': 'Levocarnitine',
    
    'acetylcysteine': 'Acetylcysteine',
    'n acetylcysteine': 'Acetylcysteine',
    'n-acetylcysteine': 'Acetylcysteine',
    'nac': 'Acetylcysteine',
    
    # Antimalarials
    'hydroxychloroquine': 'Hydroxychloroquine',
    'hydroxychloroquine sulphate': 'Hydroxychloroquine',
    'hydroxychloroquine sulfate': 'Hydroxychloroquine',
    
    'chloroquine': 'Chloroquine',
    'chloroquine phosphate': 'Chloroquine',
    
    # Anesthetics
    'lidocaine': 'Lidocaine',
    'lignocaine': 'Lidocaine',
    
    'bupivacaine': 'Bupivacaine',
    
    # Minerals
    'calcium carbonate': 'Calcium carbonate',
    'calcium': 'Calcium carbonate',
    
    'magnesium': 'Magnesium sulfate',
    'magnesium sulfate': 'Magnesium sulfate',
    'magnesium sulphate': 'Magnesium sulfate',
    
    'iron': 'Iron',
    'ferrous sulfate': 'Iron',
    'ferrous sulphate': 'Iron',
    
    'zinc': 'Zinc sulfate',
    'zinc sulfate': 'Zinc sulfate',
    'zinc sulphate': 'Zinc sulfate',
    
    # Common drugs
    'dextrose': 'Glucose',
    'glucose': 'Glucose',
    
    'caffeine': 'Caffeine',
    'caffiene': 'Caffeine',
    
    'simethicone': 'Simethicone',
    'dimethicone': 'Simethicone',
    'dimeticone': 'Simethicone',
    
    'glycerin': 'Glycerin',
    'glycerol': 'Glycerin',
    'glycerine': 'Glycerin',
}

def get_ddinter_name(local_ingredient: str) -> str:
    """Get DDInter standard name for a local ingredient."""
    normalized = local_ingredient.lower().strip()
    return DRUG_SYNONYMS.get(normalized)
