-- DDInter2 Comprehensive Database Schema
-- قاعدة بيانات شاملة لجميع بيانات DDInter2

-- ===================================
-- 1. جدول الأدوية الأساسي
-- ===================================
CREATE TABLE IF NOT EXISTS drugs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ddinter_id TEXT UNIQUE NOT NULL,           -- DDInter263
    drug_name TEXT,                             -- Caffeine
    drug_type TEXT,                             -- small molecule, protein, etc.
    molecular_formula TEXT,                     -- C8H10N4O2
    molecular_weight REAL,                      -- 194.191
    cas_number TEXT,                            -- 58-08-2
    description TEXT,                           -- وصف كامل للدواء
    iupac_name TEXT,                            -- IUPAC chemical name
    inchi TEXT,                                 -- InChI identifier
    smiles TEXT,                                -- SMILES notation
    atc_codes TEXT,                             -- JSON array of ATC codes
    external_links TEXT,                        -- JSON object: {drugbank, chebi, pubchem, ...}
    structure_2d_svg TEXT,                      -- SVG للبنية الكيميائية 2D
    scraped_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_drugs_ddinter_id ON drugs(ddinter_id);
CREATE INDEX idx_drugs_name ON drugs(drug_name);

-- ===================================
-- 2. جدول تفاعلات دواء-دواء
-- ===================================
CREATE TABLE IF NOT EXISTS drug_drug_interactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    interaction_id INTEGER UNIQUE,              -- رقم التفاعل من الموقع (4652)
    drug_a_id TEXT NOT NULL,                    -- DDInter263
    drug_b_id TEXT NOT NULL,                    -- DDInter20
    severity TEXT,                              -- Major/Moderate/Minor
    mechanism_flags TEXT,                       -- JSON array: ["Antagonism", "Synergy", ...]
    interaction_description TEXT,               -- النص الكامل للتفاعل
    management_text TEXT,                       -- نصائح إدارة التفاعل
    alternative_drugs_a TEXT,                   -- JSON array للبدائل للدواء A
    alternative_drugs_b TEXT,                   -- JSON array للبدائل للدواء B
    metabolism_info TEXT,                       -- معلومات الأيض (Potential metabolism)
    reference_text TEXT,                        -- JSON array للمراجع
    source_url TEXT,                            -- رابط الصفحة الأصلي
    scraped_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (drug_a_id) REFERENCES drugs(ddinter_id),
    FOREIGN KEY (drug_b_id) REFERENCES drugs(ddinter_id)
);

CREATE INDEX idx_ddi_drug_a ON drug_drug_interactions(drug_a_id);
CREATE INDEX idx_ddi_drug_b ON drug_drug_interactions(drug_b_id);
CREATE INDEX idx_ddi_severity ON drug_drug_interactions(severity);
CREATE INDEX idx_ddi_interaction_id ON drug_drug_interactions(interaction_id);

-- ===================================
-- 3. جدول تفاعلات دواء-مرض
-- ===================================
CREATE TABLE IF NOT EXISTS drug_disease_interactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    drug_id TEXT NOT NULL,                      -- DDInter263
    disease_name TEXT NOT NULL,
    severity TEXT,                              -- Major/Moderate/Minor
    interaction_text TEXT,                      -- وصف التفاعل
    reference_text TEXT,                        -- JSON array للمراجع
    scraped_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (drug_id) REFERENCES drugs(ddinter_id)
);

CREATE INDEX idx_ddsi_drug_id ON drug_disease_interactions(drug_id);
CREATE INDEX idx_ddsi_disease ON drug_disease_interactions(disease_name);

-- ===================================
-- 4. جدول تفاعلات دواء-غذاء
-- ===================================
CREATE TABLE IF NOT EXISTS drug_food_interactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    drug_id TEXT NOT NULL,                      -- DDInter263
    food_name TEXT NOT NULL,
    severity TEXT,                              -- Major/Moderate/Minor
    description TEXT,                           -- وصف التفاعل
    management TEXT,                            -- نصائح الإدارة
    mechanism_flags TEXT,                       -- JSON array: ["Absorption", "Metabolism", ...]
    reference_text TEXT,                        -- JSON array للمراجع
    scraped_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (drug_id) REFERENCES drugs(ddinter_id)
);

CREATE INDEX idx_dfi_drug_id ON drug_food_interactions(drug_id);
CREATE INDEX idx_dfi_food ON drug_food_interactions(food_name);

-- ===================================
-- 5. جدول المستحضرات المركبة
-- ===================================
CREATE TABLE IF NOT EXISTS compound_preparations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    drug_id TEXT NOT NULL,                      -- DDInter263
    preparation_name TEXT,
    components TEXT,                            -- JSON array للمكونات
    interaction_info TEXT,                      -- معلومات التفاعل
    scraped_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (drug_id) REFERENCES drugs(ddinter_id)
);

CREATE INDEX idx_cp_drug_id ON compound_preparations(drug_id);

-- ===================================
-- 6. جدول تتبع عملية السحب
-- ===================================
CREATE TABLE IF NOT EXISTS scraping_progress (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    entity_type TEXT NOT NULL,                  -- 'drug', 'interaction', 'disease', etc.
    entity_id TEXT NOT NULL,                    -- DDInter263 or interaction ID
    status TEXT NOT NULL,                       -- 'pending', 'completed', 'failed'
    error_message TEXT,
    scraped_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(entity_type, entity_id)
);

CREATE INDEX idx_progress_status ON scraping_progress(entity_type, status);
