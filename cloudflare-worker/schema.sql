-- D1 Database Schema Matching Flutter App DatabaseHelper
-- Version: Synced with App DB Version 12

-- 1. Drugs (Medicines) Table
CREATE TABLE IF NOT EXISTS drugs (
  id INTEGER PRIMARY KEY,
  trade_name TEXT,
  arabic_name TEXT,
  price TEXT,
  old_price TEXT,
  main_category TEXT,
  category TEXT,
  category_ar TEXT,
  active TEXT,
  company TEXT,
  dosage_form TEXT,
  dosage_form_ar TEXT,
  concentration TEXT,
  unit TEXT,
  usage TEXT,
  usage_ar TEXT,
  description TEXT,
  pharmacology TEXT,
  barcode TEXT,
  qr_code TEXT,
  visits INTEGER DEFAULT 0,
  last_price_update TEXT,
  image_url TEXT,
  updated_at INTEGER DEFAULT 0,
  has_drug_interaction INTEGER DEFAULT 0,
  has_food_interaction INTEGER DEFAULT 0,
  has_disease_interaction INTEGER DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_trade_name ON drugs (trade_name);
CREATE INDEX IF NOT EXISTS idx_category ON drugs (category);
CREATE INDEX IF NOT EXISTS idx_active ON drugs (active);

-- 2. Drug Interactions (Rules) Table
CREATE TABLE IF NOT EXISTS drug_interactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ingredient1 TEXT,
  ingredient2 TEXT,
  severity TEXT,
  effect TEXT,
  arabic_effect TEXT,
  recommendation TEXT,
  arabic_recommendation TEXT,
  management_text TEXT,
  mechanism_text TEXT,
  risk_level TEXT,
  ddinter_id TEXT,
  source TEXT,
  type TEXT,
  updated_at INTEGER DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_rules_pair ON drug_interactions(ingredient1, ingredient2);
CREATE INDEX IF NOT EXISTS idx_rules_i1 ON drug_interactions(ingredient1);
CREATE INDEX IF NOT EXISTS idx_rules_i2 ON drug_interactions(ingredient2);

-- 3. Food Interactions Table
CREATE TABLE IF NOT EXISTS food_interactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  med_id INTEGER,
  trade_name TEXT,
  interaction TEXT NOT NULL,
  source TEXT DEFAULT 'DrugBank'
);
CREATE INDEX IF NOT EXISTS idx_food_med_id ON food_interactions(med_id);

-- 4. Disease Interactions Table
CREATE TABLE IF NOT EXISTS disease_interactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  med_id INTEGER,
  trade_name TEXT,
  disease_name TEXT NOT NULL,
  interaction_text TEXT NOT NULL,
  source TEXT DEFAULT 'DDInter'
);
CREATE INDEX IF NOT EXISTS idx_disease_med_id ON disease_interactions(med_id);

-- 5. Dosage Guidelines Table
CREATE TABLE IF NOT EXISTS dosage_guidelines (
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
  is_pediatric INTEGER,
  -- Extra fields for compatibility/expansion
  active_ingredient TEXT,
  strength TEXT,
  standard_dose TEXT,
  package_label TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_guideline_med_id ON dosage_guidelines(med_id);

-- 6. Medicine Ingredients Map Table
CREATE TABLE IF NOT EXISTS med_ingredients (
  med_id INTEGER,
  ingredient TEXT,
  updated_at INTEGER DEFAULT 0,
  PRIMARY KEY (med_id, ingredient)
);
CREATE INDEX IF NOT EXISTS idx_mi_mid ON med_ingredients(med_id);

-- 7. Config Table
CREATE TABLE IF NOT EXISTS config (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Default Config
INSERT OR IGNORE INTO config (key, value) VALUES ('ads_enabled', 'true');
INSERT OR IGNORE INTO config (key, value) VALUES ('app_version', '1.0.0');
