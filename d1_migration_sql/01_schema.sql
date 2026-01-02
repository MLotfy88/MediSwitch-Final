-- Cloudflare D1 Schema
-- Generated for MediSwitch Database (Fixed to match Flutter DatabaseHelper snake_case)

DROP TABLE IF EXISTS drugs;

CREATE TABLE drugs (
    id INTEGER PRIMARY KEY,
    trade_name TEXT,
    arabic_name TEXT,
    price TEXT,
    old_price TEXT,
    category TEXT,
    active TEXT,
    company TEXT,
    dosage_form TEXT,
    dosage_form_ar TEXT,
    concentration TEXT,
    unit TEXT,
    usage TEXT,
    pharmacology TEXT,
    barcode TEXT,
    qr_code TEXT,
    visits INTEGER,
    last_price_update TEXT,
    has_drug_interaction INTEGER DEFAULT 0,
    has_food_interaction INTEGER DEFAULT 0,
    has_disease_interaction INTEGER DEFAULT 0
);

DROP TABLE IF EXISTS dosage_guidelines;

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

-- Note: sqlite_sequence is internal, do not create manually.

DROP TABLE IF EXISTS drug_interactions;

CREATE TABLE drug_interactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ingredient1 TEXT COLLATE NOCASE,
    ingredient2 TEXT COLLATE NOCASE,
    severity TEXT,
    effect TEXT,
    arabic_effect TEXT,
    recommendation TEXT,
    arabic_recommendation TEXT,
    management_text TEXT,
    mechanism_text TEXT,
    alternatives_a TEXT,
    alternatives_b TEXT,
    risk_level TEXT,
    ddinter_id TEXT,
    source TEXT,
    type TEXT,
    updated_at INTEGER DEFAULT 0
);

DROP TABLE IF EXISTS med_ingredients;

CREATE TABLE med_ingredients (
    med_id INTEGER,
    ingredient TEXT COLLATE NOCASE,
    updated_at INTEGER DEFAULT 0,
    PRIMARY KEY (med_id, ingredient)
);

DROP TABLE IF EXISTS food_interactions;

CREATE TABLE food_interactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    med_id INTEGER NOT NULL,
    trade_name TEXT,
    interaction TEXT NOT NULL,
    source TEXT DEFAULT 'DrugBank'
);

DROP TABLE IF EXISTS disease_interactions;

CREATE TABLE disease_interactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    med_id INTEGER NOT NULL,
    trade_name TEXT,
    disease_name TEXT NOT NULL,
    interaction_text TEXT NOT NULL,
    severity TEXT,
    source TEXT DEFAULT 'DDInter'
);

CREATE INDEX idx_trade_name ON drugs(trade_name);
CREATE INDEX idx_active ON drugs(active);
CREATE INDEX idx_category ON drugs(category);

CREATE INDEX idx_rules_i1 ON drug_interactions(ingredient1);
CREATE INDEX idx_rules_i2 ON drug_interactions(ingredient2);
CREATE INDEX idx_rules_pair ON drug_interactions(ingredient1, ingredient2);

CREATE INDEX idx_food_med_id ON food_interactions(med_id);
CREATE INDEX idx_disease_med_id ON disease_interactions(med_id);