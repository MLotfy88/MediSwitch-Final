-- Cloudflare D1 Schema
-- Generated for MediSwitch Database

CREATE TABLE drugs (
            tradeName TEXT PRIMARY KEY,
            id INTEGER,
            arabicName TEXT,
            price TEXT,
            oldPrice TEXT,
            mainCategory TEXT,
            category TEXT,
            category_ar TEXT,
            active TEXT,
            company TEXT,
            dosageForm TEXT,
            dosageForm_ar TEXT,
            concentration REAL,
            unit TEXT,
            usage TEXT,
            usage_ar TEXT,
            description TEXT,
            barcode TEXT,
            visits INTEGER,
            lastPriceUpdate TEXT,
            imageUrl TEXT,
            updatedAt INTEGER DEFAULT 0
        , indication TEXT, mechanism_of_action TEXT, pharmacodynamics TEXT, data_source_pharmacology TEXT);

CREATE TABLE dosage_guidelines (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            med_id INTEGER,
            dailymed_setid TEXT,
            min_dose REAL,
            max_dose REAL,
            frequency INTEGER,
            duration INTEGER,
            instructions TEXT,
            condition TEXT,
            source TEXT,
            is_pediatric INTEGER
        );

CREATE TABLE sqlite_sequence(name,seq);

CREATE TABLE drug_interactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ingredient1 TEXT,
            ingredient2 TEXT,
            severity TEXT,
            effect TEXT,
            source TEXT,
            updated_at INTEGER DEFAULT 0
        , management_text TEXT, mechanism_text TEXT, recommendation TEXT, arabic_recommendation TEXT, arabic_effect TEXT, risk_level TEXT, type TEXT);

CREATE TABLE med_ingredients (
            med_id INTEGER,
            ingredient TEXT,
            PRIMARY KEY (med_id, ingredient)
        );

CREATE TABLE drug_interactions_v8 (
            id INTEGER PRIMARY KEY,
            ddinter_interaction_id INTEGER UNIQUE,
            drug_a_id TEXT,
            drug_b_id TEXT,
            severity TEXT,
            interaction_text TEXT,
            management_text TEXT,
            source TEXT
        );

CREATE INDEX idx_ddi_ing1 ON drug_interactions(ingredient1);

CREATE INDEX idx_ddi_ing2 ON drug_interactions(ingredient2);

CREATE INDEX idx_ddi_severity ON drug_interactions(severity);

CREATE INDEX idx_drugs_active ON drugs(active);

CREATE TABLE disease_interactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            med_id INTEGER,
            trade_name TEXT,
            disease_name TEXT,
            interaction_text TEXT,
            severity TEXT,
            source TEXT,
            created_at INTEGER
        );

CREATE TABLE food_interactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            med_id INTEGER,
            interaction_text TEXT,
            source TEXT,
            created_at INTEGER
        );

CREATE INDEX idx_disease_med ON disease_interactions(med_id);

CREATE INDEX idx_disease_severity ON disease_interactions(severity);

CREATE INDEX idx_disease_name ON disease_interactions(disease_name);

CREATE INDEX idx_food_med ON food_interactions(med_id);