-- D1 Schema Generated from mediswitch.db
PRAGMA foreign_keys = OFF;

DROP TABLE IF EXISTS drugs;
CREATE TABLE drugs (
        id INTEGER PRIMARY KEY,
        trade_name TEXT NOT NULL,
        arabic_name TEXT,
        price TEXT,
        old_price TEXT,
        category TEXT,
        active TEXT,
        company TEXT,
        dosage_form TEXT,
        dosage_form_ar TEXT,
        concentration REAL,
        unit TEXT,
        usage TEXT,
        pharmacology TEXT,
        barcode TEXT,
        qr_code TEXT,
        visits INTEGER,
        last_price_update TEXT,
        updated_at INTEGER DEFAULT 0,
        indication TEXT,
        mechanism_of_action TEXT,
        pharmacodynamics TEXT,
        data_source_pharmacology TEXT,
        has_drug_interaction INTEGER DEFAULT 0,
        has_food_interaction INTEGER DEFAULT 0,
        has_disease_interaction INTEGER DEFAULT 0,
        description TEXT,
        atc_codes TEXT,
        external_links TEXT
    );

CREATE INDEX idx_trade_name ON drugs(trade_name);
CREATE INDEX idx_drugs_flags ON drugs(has_drug_interaction, has_food_interaction, has_disease_interaction);

DROP TABLE IF EXISTS drug_interactions;
CREATE TABLE drug_interactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ingredient1 TEXT, ingredient2 TEXT, severity TEXT, effect TEXT, source TEXT, 
        management_text TEXT, mechanism_text TEXT, recommendation TEXT, risk_level TEXT, type TEXT,
        metabolism_info TEXT, source_url TEXT, reference_text TEXT, alternatives_a TEXT, alternatives_b TEXT, updated_at INTEGER DEFAULT 0
    , arabic_effect TEXT, arabic_recommendation TEXT, ddinter_id TEXT);

CREATE INDEX idx_rules_pair ON drug_interactions(ingredient1, ingredient2);
CREATE INDEX idx_interactions_severity_lower ON drug_interactions(LOWER(severity));
CREATE INDEX idx_high_risk_partial ON drug_interactions(ingredient1, ingredient2) WHERE severity IN ('Contraindicated', 'Severe', 'Major', 'High');
CREATE INDEX idx_di_ing1 ON drug_interactions(ingredient1);
CREATE INDEX idx_di_ing2 ON drug_interactions(ingredient2);

DROP TABLE IF EXISTS disease_interactions;
CREATE TABLE disease_interactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        med_id INTEGER NOT NULL, trade_name TEXT, disease_name TEXT NOT NULL, interaction_text TEXT NOT NULL, 
        severity TEXT, reference_text TEXT, source TEXT DEFAULT 'DDInter', created_at INTEGER DEFAULT 0
    );

CREATE INDEX idx_disease_med_id ON disease_interactions(med_id);

DROP TABLE IF EXISTS food_interactions;
CREATE TABLE food_interactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT, med_id INTEGER NOT NULL, trade_name TEXT, interaction TEXT NOT NULL, 
        ingredient TEXT, severity TEXT, management_text TEXT, mechanism_text TEXT, reference_text TEXT, 
        source TEXT DEFAULT 'DrugBank', created_at INTEGER DEFAULT 0
    );

CREATE INDEX idx_food_med_id ON food_interactions(med_id);
CREATE INDEX idx_fi_covering ON food_interactions(ingredient, interaction);
CREATE INDEX idx_fi_ingredient ON food_interactions(ingredient);

DROP TABLE IF EXISTS med_ingredients;
CREATE TABLE med_ingredients (
            med_id INTEGER,
            ingredient TEXT,
            PRIMARY KEY (med_id, ingredient)
        );

CREATE INDEX idx_mi_med_id ON med_ingredients(med_id);
CREATE INDEX idx_mi_ingredient ON med_ingredients(ingredient);

DROP TABLE IF EXISTS dosage_guidelines;
CREATE TABLE "dosage_guidelines" (id INTEGER PRIMARY KEY AUTOINCREMENT, med_id INTEGER, wikem_min_dose REAL, wikem_max_dose REAL, wikem_dose_unit TEXT, wikem_route TEXT, wikem_frequency INTEGER, wikem_patient_category TEXT, wikem_instructions BLOB, wikem_json_blob BLOB, ncbi_indications BLOB, ncbi_administration BLOB, ncbi_adverse_effects BLOB, ncbi_contraindications BLOB, ncbi_monitoring BLOB, ncbi_mechanism BLOB, ncbi_toxicity BLOB, ncbi_json_blob BLOB, source TEXT, created_at INTEGER, updated_at INTEGER, structured_dosage BLOB, min_dose REAL, max_dose REAL, dose_unit TEXT, frequency TEXT, route TEXT, patient_category TEXT);


