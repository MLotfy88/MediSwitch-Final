-- D1 Interactions Schema Generated from mediswitch.db
PRAGMA foreign_keys = OFF;

DROP TABLE IF EXISTS drug_interactions;
CREATE TABLE drug_interactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ingredient1 TEXT, ingredient2 TEXT, severity TEXT, source TEXT, 
        risk_level TEXT, type TEXT,
        metabolism_info TEXT, source_url TEXT, reference_text TEXT, alternatives_a TEXT, alternatives_b TEXT, updated_at INTEGER DEFAULT 0
    , arabic_effect TEXT, arabic_recommendation TEXT, ddinter_id TEXT, management_text_blob BLOB, mechanism_text_blob BLOB, recommendation_blob BLOB, effect_blob BLOB);

CREATE INDEX idx_rules_pair ON drug_interactions(ingredient1, ingredient2);
CREATE INDEX idx_interactions_severity_lower ON drug_interactions(LOWER(severity));
CREATE INDEX idx_high_risk_partial ON drug_interactions(ingredient1, ingredient2) WHERE severity IN ('Contraindicated', 'Severe', 'Major', 'High');
CREATE INDEX idx_di_ing1 ON drug_interactions(ingredient1);
CREATE INDEX idx_di_ing2 ON drug_interactions(ingredient2);

DROP TABLE IF EXISTS disease_interactions;
CREATE TABLE disease_interactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        med_id INTEGER NOT NULL, trade_name TEXT, disease_name TEXT NOT NULL, severity TEXT, reference_text TEXT, source TEXT DEFAULT 'DDInter', created_at INTEGER DEFAULT 0
    , interaction_text_blob BLOB);

CREATE INDEX idx_disease_med_id ON disease_interactions(med_id);

DROP TABLE IF EXISTS food_interactions;
CREATE TABLE food_interactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT, med_id INTEGER NOT NULL, trade_name TEXT, interaction TEXT NOT NULL, 
        ingredient TEXT, severity TEXT, reference_text TEXT, 
        source TEXT DEFAULT 'DrugBank', created_at INTEGER DEFAULT 0
    , management_text_blob BLOB, mechanism_text_blob BLOB, interaction_blob BLOB);

CREATE INDEX idx_food_med_id ON food_interactions(med_id);
CREATE INDEX idx_fi_covering ON food_interactions(ingredient, interaction);
CREATE INDEX idx_fi_ingredient ON food_interactions(ingredient);

