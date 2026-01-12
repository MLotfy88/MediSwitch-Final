-- D1 Main Schema Generated from mediswitch.db
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


DROP TABLE IF EXISTS home_summary;
CREATE TABLE home_summary (
            type TEXT,          -- 'food_interaction' or 'high_risk_ingredient'
            name TEXT,
            count INTEGER,
            med_id INTEGER,     -- optional, for navigation
            severe_count INTEGER,
            moderate_count INTEGER,
            minor_count INTEGER,
            danger_score INTEGER
        );


