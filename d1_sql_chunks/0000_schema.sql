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

DROP TABLE IF EXISTS dosage_guidelines;
CREATE TABLE dosage_guidelines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        med_id INTEGER NOT NULL,
        dailymed_setid TEXT,
        min_dose REAL,
        max_dose REAL,
        frequency INTEGER,
        duration INTEGER,
        instructions TEXT,
        condition TEXT,
        source TEXT,
        is_pediatric INTEGER
    , dose_unit TEXT, route TEXT, dosage_form TEXT, patient_category TEXT, is_geriatric BOOLEAN, is_pregnant BOOLEAN, renal_adjustment TEXT, hepatic_adjustment TEXT, warnings TEXT, contraindications TEXT, adverse_reactions TEXT, black_box_warning TEXT, overdose_management TEXT, max_daily_dose REAL, loading_dose REAL, maintenance_dose REAL, special_populations TEXT, pregnancy_category TEXT, lactation_info TEXT);

DROP TABLE IF EXISTS drug_interactions;
CREATE TABLE drug_interactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ingredient1 TEXT, ingredient2 TEXT, severity TEXT, effect TEXT, source TEXT, 
        management_text TEXT, mechanism_text TEXT, recommendation TEXT, risk_level TEXT, type TEXT,
        metabolism_info TEXT, source_url TEXT, reference_text TEXT, alternatives_a TEXT, alternatives_b TEXT, updated_at INTEGER DEFAULT 0
    );

DROP TABLE IF EXISTS disease_interactions;
CREATE TABLE disease_interactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        med_id INTEGER NOT NULL, trade_name TEXT, disease_name TEXT NOT NULL, interaction_text TEXT NOT NULL, 
        severity TEXT, reference_text TEXT, source TEXT DEFAULT 'DDInter', created_at INTEGER DEFAULT 0
    );

DROP TABLE IF EXISTS food_interactions;
CREATE TABLE food_interactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT, med_id INTEGER NOT NULL, trade_name TEXT, interaction TEXT NOT NULL, 
        ingredient TEXT, severity TEXT, management_text TEXT, mechanism_text TEXT, reference_text TEXT, 
        source TEXT DEFAULT 'DrugBank', created_at INTEGER DEFAULT 0
    );

DROP TABLE IF EXISTS med_ingredients;
CREATE TABLE med_ingredients (
            med_id INTEGER,
            ingredient TEXT,
            PRIMARY KEY (med_id, ingredient)
        );

